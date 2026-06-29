import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/config/sync_config.dart';
import 'package:atlas_flutter_app/data/database/daos/sync_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/sync_repository.dart';
import 'package:atlas_flutter_app/data/services/conflict_resolution_service.dart';

/// Sync status emitted by [OfflineManager].
enum SyncStatus { idle, syncing, error }

/// Central sync orchestrator that queues offline operations, pushes them
/// when connectivity is restored, and pulls remote changes periodically.
class OfflineManager {
  final SyncDao _syncDao;
  final TaskDao _taskDao;
  final HabitDao _habitDao;
  final GoalDao _goalDao;
  final AvatarDao _avatarDao;
  final SyncRepository _syncRepository;
  final ConflictResolutionService _conflictResolution;
  final _log = Logger();
  final _uuid = const Uuid();

  static const _lastSyncKey = 'offline_manager_last_sync';
  static const _periodicSyncInterval = Duration(minutes: 5);

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _isAuthenticated = false;
  String? _currentUserId;
  Timer? _periodicSyncTimer;
  DateTime? _lastSyncTime;
  StreamSubscription<bool>? _connectivitySubscription;

  // ─── Streams ────────────────────────────────────────────────

  final _syncStatusController =
      StreamController<SyncStatus>.broadcast();
  final _lastSyncTimeController =
      StreamController<DateTime?>.broadcast();

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  Stream<DateTime?> get lastSyncTimeStream =>
      _lastSyncTimeController.stream;

  /// Pull handlers registered per entity type. Each handler receives the
  /// list of remote entities and is responsible for upserting them locally.
  final Map<String, Future<void> Function(List<Map<String, dynamic>>)>
      _pullHandlers = {};

  // ─── Public Getters ─────────────────────────────────────────

  bool get isOnline => _isOnline;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Call when auth state changes. Sync only runs when authenticated.
  void setAuthenticated(bool authenticated, {String? userId}) {
    _isAuthenticated = authenticated;
    _currentUserId = userId;
    if (authenticated && _isOnline) {
      syncNow();
    }
    if (!authenticated) {
      _currentUserId = null;
      _cancelPeriodicSync();
    }
  }

  /// Exposes conflict resolution so pull handlers can resolve local-vs-remote
  /// conflicts using last-write-wins.
  ConflictResolutionService get conflictResolution => _conflictResolution;

  // ─── Constructor ────────────────────────────────────────────

  OfflineManager({
    required SyncDao syncDao,
    required TaskDao taskDao,
    required HabitDao habitDao,
    required GoalDao goalDao,
    required AvatarDao avatarDao,
    required SyncRepository syncRepository,
    required ConflictResolutionService conflictResolution,
  })  : _syncDao = syncDao,
        _taskDao = taskDao,
        _habitDao = habitDao,
        _goalDao = goalDao,
        _avatarDao = avatarDao,
        _syncRepository = syncRepository,
        _conflictResolution = conflictResolution;

  // ─── Lifecycle ──────────────────────────────────────────────

  /// Initialise the manager. Call once at app startup.
  Future<void> initialize(Stream<bool> connectivityStream) async {
    // Restore persisted last-sync time
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_lastSyncKey);
    if (stored != null) {
      _lastSyncTime = DateTime.tryParse(stored);
      _lastSyncTimeController.add(_lastSyncTime);
    }

    // Listen to connectivity changes
    _connectivitySubscription = connectivityStream.listen((online) {
      final wasOffline = !_isOnline;
      _isOnline = online;
      if (online && wasOffline && _isAuthenticated) {
        _log.i('OfflineManager: Back online — triggering sync');
        syncNow();
      }
    });
  }

  // ─── Queue ──────────────────────────────────────────────────

  /// Enqueue a local change for eventual sync.
  Future<void> queueOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? data,
  }) async {
    final entry = SyncOperationsCompanion.insert(
      id: _uuid.v4(),
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      data: data != null ? Value(jsonEncode(data)) : const Value.absent(),
      timestamp: DateTime.now(),
    );

    await _syncDao.queueOperation(entry);
    _log.d(
        'OfflineManager: Queued $operationType for $entityType/$entityId');

    if (_isOnline && !_isSyncing) {
      syncNow();
    }
  }

  // ─── Sync ───────────────────────────────────────────────────

  /// Push pending local changes then pull remote changes.
  Future<void> syncNow() async {
    // Sync is a premium feature — gated off until enabled. The app is fully
    // local-first regardless; nothing here runs while disabled.
    if (!SyncConfig.enabled) return;
    if (!_isOnline || _isSyncing || !_isAuthenticated) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Row-based sync for migrated entities (Tasks, Habits), then legacy outbox.
      await _pushTasks();
      await _pushHabits();
      await _pushGoals();
      await _pushAvatar();
      await _pushChanges();
      await _pullRows();
      await _pullChanges();

      // Persist last sync time
      _lastSyncTime = DateTime.now();
      _lastSyncTimeController.add(_lastSyncTime);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastSyncKey, _lastSyncTime!.toIso8601String());

      _syncStatusController.add(SyncStatus.idle);
      _log.i('OfflineManager: Sync completed at $_lastSyncTime');
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
      _log.e('OfflineManager: Sync failed', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Push ───────────────────────────────────────────────────

  Future<void> _pushChanges() async {
    final pending = await _syncDao.getPendingOperations();
    if (pending.isEmpty) return;

    // Filter to only retry-eligible operations (exponential backoff)
    final readyOps = pending.where((op) {
      final retryDelay =
          Duration(seconds: (1 << op.retryCount).clamp(1, 300));
      return op.retryCount < op.maxRetries &&
          DateTime.now().isAfter(op.timestamp.add(retryDelay));
    }).toList();

    if (readyOps.isEmpty) return;

    for (final op in readyOps) {
      try {
        await _dispatchOperation(op);
        await _syncDao.deleteOperation(op.id);
        _log.d(
            'OfflineManager: Synced ${op.operationType} ${op.entityType}/${op.entityId}');
      } catch (e) {
        if (op.retryCount + 1 >= op.maxRetries) {
          await _syncDao.deleteOperation(op.id);
          _log.w(
              'OfflineManager: Max retries exceeded for ${op.id}, removing');
        } else {
          await _syncDao.incrementRetry(op.id);
          _log.w(
              'OfflineManager: Retry ${op.retryCount + 1} for ${op.operationType} ${op.entityType}/${op.entityId}',
              error: e);
        }
      }
    }
  }

  /// Dispatch a single queued operation to the appropriate REST endpoint.
  Future<void> _dispatchOperation(SyncOperation op) async {
    final data = op.data != null
        ? jsonDecode(op.data!) as Map<String, dynamic>
        : null;
    final api = _syncRepository.apiService;

    switch ('${op.operationType}_${op.entityType}') {
      // ─── Tasks ─────────────────────────────────────────
      case 'create_task':
        await api.post('/tasks', data: data);
      case 'update_task':
        await api.put('/tasks/${op.entityId}', data: data);
      case 'delete_task':
        await api.delete('/tasks/${op.entityId}');
      case 'complete_task':
        await api.post('/tasks/${op.entityId}/complete');

      // ─── Habits ────────────────────────────────────────
      case 'create_habit':
        await api.post('/habits', data: data);
      case 'update_habit':
        await api.put('/habits/${op.entityId}', data: data);
      case 'delete_habit':
        await api.delete('/habits/${op.entityId}');
      case 'complete_habit':
        await api.post('/habits/${op.entityId}/complete');

      // ─── Goals ─────────────────────────────────────────
      case 'create_goal':
        await api.post('/goals', data: data);
      case 'update_goal':
        await api.put('/goals/${op.entityId}', data: data);
      case 'delete_goal':
        await api.delete('/goals/${op.entityId}');
      case 'update_progress_goal':
        await api.post('/goals/${op.entityId}/progress', data: data);

      // ─── Avatar ────────────────────────────────────────
      case 'create_avatar':
        await api.post('/avatar', data: data);
      case 'update_appearance_avatar':
        await api.put('/avatar/appearance', data: data);
      case 'unlock_item_avatar':
        await api.post('/avatar/unlock-item', data: data);

      // ─── Achievements ──────────────────────────────────
      case 'check_achievement':
        await api.post('/achievements/check');

      // ─── World Tiles ───────────────────────────────────
      case 'unlock_world_tile':
        await api.post('/world/tiles/${op.entityId}/unlock');

      default:
        _log.w(
            'OfflineManager: Unknown operation ${op.operationType}_${op.entityType}');
    }
  }

  // ─── Pull ───────────────────────────────────────────────────

  Future<void> _pullChanges() async {
    for (final entry in _pullHandlers.entries) {
      try {
        final entityType = entry.key;
        final handler = entry.value;
        final endpoint = _endpointForEntityType(entityType);
        if (endpoint == null) continue;

        final response = await _syncRepository.apiService.get(endpoint);

        // Handle both List responses and single-object responses (e.g., avatar)
        if (response.data is List) {
          final items = (response.data as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          await handler(items);
          _log.d(
              'OfflineManager: Pulled ${items.length} $entityType entities');
        } else if (response.data is Map<String, dynamic>) {
          // Single entity (e.g., avatar) — wrap in a list for the handler
          await handler([response.data as Map<String, dynamic>]);
          _log.d('OfflineManager: Pulled 1 $entityType entity');
        }
      } catch (e) {
        _log.w('OfflineManager: Pull failed for ${entry.key}', error: e);
      }
    }
  }

  /// Maps entity type names to their REST GET endpoints.
  String? _endpointForEntityType(String entityType) {
    return switch (entityType) {
      'task' => '/tasks',
      'habit' => '/habits',
      'goal' => '/goals',
      'avatar' => '/avatar',
      'achievement' => '/achievements',
      'world_tile' => '/world/tiles',
      'progress' => '/progress',
      _ => null,
    };
  }

  // ─── Row-based Task sync (offline-first) ────────────────────

  /// Push dirty Task rows (incl. tombstones) as upserts via /sync/push.
  Future<void> _pushTasks() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _taskDao.getDirtyTasks(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final t in dirty)
        {
          'operation_type': t.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'task',
          'entity_id': t.id,
          'data': jsonEncode(_taskWire(t)),
          'timestamp': t.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    await _syncRepository.pushSync(ops);
    await _taskDao.markSynced([for (final t in dirty) t.id], DateTime.now());
    await _taskDao.purgeSyncedTombstones();
    _log.d('OfflineManager: Pushed ${ops.length} task rows');
  }

  /// Pull deltas (incl. tombstones) since the cursor and apply each migrated
  /// entity with LWW (local wins ties).
  Future<void> _pullRows() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final resp = await _syncRepository.pullSync(
      lastSyncTimestamp: _lastSyncTime?.toUtc().toIso8601String(),
    );
    final list = (resp['entities'] as List?) ?? const [];
    for (final e in list) {
      final m = (e as Map).cast<String, dynamic>();
      final raw = m['data'];
      final remote = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : (raw as Map).cast<String, dynamic>();
      switch (m['entity_type']) {
        case 'task':
          await _applyRemoteTask(userId, remote);
        case 'habit':
          await _applyRemoteHabit(userId, remote);
        case 'goal':
          await _applyRemoteGoal(userId, remote);
        case 'avatar':
          await _applyRemoteAvatar(userId, remote);
      }
    }
  }

  /// Apply a remote task using last-write-wins with local winning ties.
  Future<void> _applyRemoteTask(String userId, Map<String, dynamic> r) async {
    final id = r['id'].toString();
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final isDeleted = r['is_deleted'] == true;
    final local = await _taskDao.getTaskById(id);

    // Local wins ties: only apply when the server copy is strictly newer.
    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    if (isDeleted) {
      if (local != null) await _taskDao.hardDeleteTask(id);
      return;
    }
    await _taskDao.upsertTask(_companionFromRemote(userId, r, remoteUpdated));
  }

  Map<String, dynamic> _taskWire(Task t) => {
        'id': t.id,
        'user_id': t.userId,
        'title': t.title,
        'description': t.description,
        'type': t.type,
        'category': t.category,
        'xp_reward': t.xpReward,
        'difficulty': t.difficulty,
        'due_date': t.dueDate?.toUtc().toIso8601String(),
        'is_completed': t.isCompleted,
        'streak_count': t.streakCount,
        'last_completed_date': t.lastCompletedDate?.toUtc().toIso8601String(),
        'is_deleted': t.isDeleted,
        'updated_at': t.updatedAt.toUtc().toIso8601String(),
      };

  TasksCompanion _companionFromRemote(
      String userId, Map<String, dynamic> r, DateTime? updated) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    // Backend lowercases enum names; restore the only camelCase one.
    var type = (r['type'] ?? 'daily').toString();
    if (type == 'longterm') type = 'longTerm';
    return TasksCompanion(
      id: Value(r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      title: Value((r['title'] ?? '').toString()),
      description: Value(r['description']?.toString()),
      type: Value(type),
      category: Value((r['category'] ?? 'custom').toString()),
      xpReward: Value((r['xp_reward'] as num?)?.toInt() ?? 25),
      difficulty: Value((r['difficulty'] as num?)?.toInt() ?? 1),
      dueDate: Value(parse(r['due_date'])),
      isCompleted: Value(r['is_completed'] == true),
      streakCount: Value((r['streak_count'] as num?)?.toInt() ?? 0),
      lastCompletedDate: Value(parse(r['last_completed_date'])),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: Value(r['is_deleted'] == true),
      deletedAt: Value(parse(r['deleted_at'])),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  // ─── Row-based Habit sync (offline-first) ───────────────────

  Future<void> _pushHabits() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _habitDao.getDirtyHabits(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final h in dirty)
        {
          'operation_type': h.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'habit',
          'entity_id': h.id,
          'data': jsonEncode(_habitWire(h)),
          'timestamp': h.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    await _syncRepository.pushSync(ops);
    await _habitDao.markSynced([for (final h in dirty) h.id], DateTime.now());
    await _habitDao.purgeSyncedTombstones();
    _log.d('OfflineManager: Pushed ${ops.length} habit rows');
  }

  Future<void> _applyRemoteHabit(String userId, Map<String, dynamic> r) async {
    final id = r['id'].toString();
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final isDeleted = r['is_deleted'] == true;
    final local = await _habitDao.getHabitById(id);

    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    if (isDeleted) {
      if (local != null) await _habitDao.hardDeleteHabit(id);
      return;
    }
    await _habitDao.upsertHabit(_companionFromRemoteHabit(userId, r, remoteUpdated));
  }

  Map<String, dynamic> _habitWire(Habit h) => {
        'id': h.id,
        'user_id': h.userId,
        'title': h.title,
        'description': h.description,
        'category': h.category,
        'frequency': h.frequency,
        'difficulty': h.difficulty,
        'is_completed_today': h.isCompletedToday,
        'streak_count': h.streakCount,
        'longest_streak': h.longestStreak,
        'completion_rate': h.completionRate,
        'total_completions': h.totalCompletions,
        'reminder_time': h.reminderTime,
        'last_completed_date': h.lastCompletedDate?.toUtc().toIso8601String(),
        'is_deleted': h.isDeleted,
        'updated_at': h.updatedAt.toUtc().toIso8601String(),
      };

  HabitsCompanion _companionFromRemoteHabit(
      String userId, Map<String, dynamic> r, DateTime? updated) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return HabitsCompanion(
      id: Value(r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      title: Value((r['title'] ?? '').toString()),
      description: Value(r['description']?.toString()),
      category: Value((r['category'] ?? 'custom').toString()),
      frequency: Value((r['frequency'] ?? 'daily').toString()),
      difficulty: Value((r['difficulty'] as num?)?.toInt() ?? 1),
      isCompletedToday: Value(r['is_completed_today'] == true),
      streakCount: Value((r['streak_count'] as num?)?.toInt() ?? 0),
      longestStreak: Value((r['longest_streak'] as num?)?.toInt() ?? 0),
      completionRate: Value((r['completion_rate'] as num?)?.toDouble() ?? 0.0),
      totalCompletions: Value((r['total_completions'] as num?)?.toInt() ?? 0),
      reminderTime: Value(r['reminder_time']?.toString()),
      lastCompletedDate: Value(parse(r['last_completed_date'])),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: Value(r['is_deleted'] == true),
      deletedAt: Value(parse(r['deleted_at'])),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  // ─── Row-based Goal sync (offline-first) ────────────────────

  Future<void> _pushGoals() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _goalDao.getDirtyGoals(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final g in dirty)
        {
          'operation_type': g.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'goal',
          'entity_id': g.id,
          'data': jsonEncode(_goalWire(g)),
          'timestamp': g.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    await _syncRepository.pushSync(ops);
    await _goalDao.markSynced([for (final g in dirty) g.id], DateTime.now());
    await _goalDao.purgeSyncedTombstones();
    _log.d('OfflineManager: Pushed ${ops.length} goal rows');
  }

  Future<void> _applyRemoteGoal(String userId, Map<String, dynamic> r) async {
    final id = r['id'].toString();
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final isDeleted = r['is_deleted'] == true;
    final local = await _goalDao.getGoalById(id);

    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    if (isDeleted) {
      if (local != null) await _goalDao.hardDeleteGoal(id);
      return;
    }
    await _goalDao.upsertGoal(_companionFromRemoteGoal(userId, r, remoteUpdated));
  }

  Map<String, dynamic> _goalWire(Goal g) => {
        'id': g.id,
        'user_id': g.userId,
        'title': g.title,
        'description': g.description,
        'category': g.category,
        'priority': g.priority,
        'status': g.status,
        'progress': g.progress,
        'start_date': g.startDate?.toUtc().toIso8601String(),
        'deadline': g.deadline?.toUtc().toIso8601String(),
        'completed_at': g.completedAt?.toUtc().toIso8601String(),
        'parent_goal_id': g.parentGoalId,
        'is_deleted': g.isDeleted,
        'updated_at': g.updatedAt.toUtc().toIso8601String(),
      };

  GoalsCompanion _companionFromRemoteGoal(
      String userId, Map<String, dynamic> r, DateTime? updated) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    // Backend lowercases enum names; restore the camelCase statuses.
    var status = (r['status'] ?? 'notStarted').toString();
    status = switch (status) {
      'notstarted' => 'notStarted',
      'inprogress' => 'inProgress',
      'onhold' => 'onHold',
      _ => status,
    };
    return GoalsCompanion(
      id: Value(r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      title: Value((r['title'] ?? '').toString()),
      description: Value(r['description']?.toString()),
      category: Value((r['category'] ?? 'personal').toString()),
      priority: Value((r['priority'] ?? 'medium').toString()),
      status: Value(status),
      progress: Value((r['progress'] as num?)?.toDouble() ?? 0.0),
      startDate: Value(parse(r['start_date'])),
      deadline: Value(parse(r['deadline'])),
      completedAt: Value(parse(r['completed_at'])),
      parentGoalId: Value(r['parent_goal_id']?.toString()),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: Value(r['is_deleted'] == true),
      deletedAt: Value(parse(r['deleted_at'])),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  // ─── Row-based Avatar sync (offline-first, 1:1 per user) ────

  Future<void> _pushAvatar() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _avatarDao.getDirtyAvatars(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final a in dirty)
        {
          'operation_type': a.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'avatar',
          'entity_id': a.id,
          'data': jsonEncode(_avatarWire(a)),
          'timestamp': a.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    await _syncRepository.pushSync(ops);
    await _avatarDao.markSynced([for (final a in dirty) a.id], DateTime.now());
    await _avatarDao.purgeSyncedTombstones();
    _log.d('OfflineManager: Pushed ${ops.length} avatar rows');
  }

  /// Avatar is 1:1 per user, so the local and remote ids may differ (the
  /// server created its avatar at registration). Match on userId and keep the
  /// existing local row id to avoid creating a duplicate.
  Future<void> _applyRemoteAvatar(String userId, Map<String, dynamic> r) async {
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final local = await _avatarDao.getAvatarByUserId(userId);

    // Local wins ties: only apply when the server copy is strictly newer.
    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    // Avatars are never deleted in practice; ignore remote tombstones.
    if (r['is_deleted'] == true) return;

    await _avatarDao.upsertAvatar(
      _companionFromRemoteAvatar(userId, r, remoteUpdated, local?.id),
    );
  }

  Map<String, dynamic> _avatarWire(Avatar a) {
    Map<String, dynamic>? appearance;
    if (a.appearanceData != null && a.appearanceData!.isNotEmpty) {
      try {
        appearance = jsonDecode(a.appearanceData!) as Map<String, dynamic>;
      } catch (_) {
        // Malformed appearance — omit it.
      }
    }
    List<dynamic>? unlocked;
    if (a.unlockedItems != null && a.unlockedItems!.isNotEmpty) {
      try {
        unlocked = jsonDecode(a.unlockedItems!) as List<dynamic>;
      } catch (_) {
        // Malformed list — omit it.
      }
    }
    return {
      'id': a.id,
      'user_id': a.userId,
      'name': a.name,
      'level': a.level,
      'current_xp': a.currentXp,
      'strength': a.strength,
      'wisdom': a.wisdom,
      'intelligence': a.intelligence,
      'appearance': appearance,
      'unlocked_items': unlocked,
      'is_deleted': a.isDeleted,
      'updated_at': a.updatedAt.toUtc().toIso8601String(),
    };
  }

  AvatarsCompanion _companionFromRemoteAvatar(
      String userId, Map<String, dynamic> r, DateTime? updated, String? existingId) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    String? appearanceJson;
    final ap = r['appearance'];
    if (ap is Map) {
      appearanceJson = jsonEncode(ap);
    } else if (ap is String && ap.isNotEmpty) {
      appearanceJson = ap;
    }
    String? unlockedJson;
    final ul = r['unlocked_items'];
    if (ul is List) {
      unlockedJson = jsonEncode(ul);
    } else if (ul is String && ul.isNotEmpty) {
      unlockedJson = ul;
    }
    return AvatarsCompanion(
      id: Value(existingId ?? r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      name: Value((r['name'] ?? 'Adventurer').toString()),
      level: Value((r['level'] as num?)?.toInt() ?? 1),
      currentXp: Value((r['current_xp'] as num?)?.toInt() ?? 0),
      strength: Value((r['strength'] as num?)?.toInt() ?? 0),
      wisdom: Value((r['wisdom'] as num?)?.toInt() ?? 0),
      intelligence: Value((r['intelligence'] as num?)?.toInt() ?? 0),
      appearanceData: Value(appearanceJson),
      unlockedItems: Value(unlockedJson),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: const Value(false),
      deletedAt: const Value(null),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  // ─── Pull Handler Registration ──────────────────────────────

  /// Register a handler invoked when entities of [entityType] are pulled
  /// from the server.
  void registerPullHandler(
    String entityType,
    Future<void> Function(List<Map<String, dynamic>>) handler,
  ) {
    _pullHandlers[entityType] = handler;
  }

  // ─── App Lifecycle ──────────────────────────────────────────

  /// Call when the app resumes from background.
  void onAppResumed() {
    if (_isAuthenticated) {
      syncNow();
      _startPeriodicSync();
    }
  }

  /// Call when the app is paused / sent to background.
  void onAppPaused() {
    _cancelPeriodicSync();
  }

  // ─── Periodic Timer ─────────────────────────────────────────

  void _startPeriodicSync() {
    _cancelPeriodicSync();
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
      if (_isOnline) syncNow();
    });
  }

  void _cancelPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  // ─── Cleanup ────────────────────────────────────────────────

  void dispose() {
    _cancelPeriodicSync();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _lastSyncTimeController.close();
  }
}
