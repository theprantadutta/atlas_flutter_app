import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/config/sync_config.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/world_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/achievement_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/sync_repository.dart';
import 'package:atlas_flutter_app/data/services/conflict_resolution_service.dart';

/// Sync status emitted by [OfflineManager].
enum SyncStatus { idle, syncing, error }

/// Central sync orchestrator that queues offline operations, pushes them
/// when connectivity is restored, and pulls remote changes periodically.
class OfflineManager {
  final TaskDao _taskDao;
  final HabitDao _habitDao;
  final GoalDao _goalDao;
  final AvatarDao _avatarDao;
  final WorldDao _worldDao;
  final AchievementDao _achievementDao;
  final ProgressDao _progressDao;
  final NotificationDao _notificationDao;
  final SyncRepository _syncRepository;
  final ConflictResolutionService _conflictResolution;
  final _log = Logger();

  static const _lastSyncKey = 'offline_manager_last_sync';
  static const _periodicSyncInterval = Duration(minutes: 5);
  static const _syncDebounceDelay = Duration(seconds: 2);

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _isAuthenticated = false;
  bool _isEntitled = false;
  String? _currentUserId;
  Timer? _periodicSyncTimer;
  Timer? _syncDebounceTimer;
  DateTime? _lastSyncTime;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<void>? _tableUpdatesSubscription;

  // ─── Streams ────────────────────────────────────────────────

  final _syncStatusController =
      StreamController<SyncStatus>.broadcast();
  final _lastSyncTimeController =
      StreamController<DateTime?>.broadcast();

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  Stream<DateTime?> get lastSyncTimeStream =>
      _lastSyncTimeController.stream;

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
      _maybeStartPeriodicSync();
    }
    if (!authenticated) {
      _currentUserId = null;
      _cancelPeriodicSync();
    }
  }

  /// Cloud sync is a premium feature. Driven by the user's entitlement (see the
  /// `entitlementProvider` listener in `AtlasApp`). When the user isn't premium
  /// the sync engine stays dormant and the app is purely local.
  void setEntitled(bool entitled) {
    if (_isEntitled == entitled) return;
    _isEntitled = entitled;
    if (entitled && _isAuthenticated && _isOnline) {
      syncNow();
      _maybeStartPeriodicSync();
    }
    if (!entitled) {
      _cancelPeriodicSync();
    }
  }

  /// Exposes conflict resolution so pull handlers can resolve local-vs-remote
  /// conflicts using last-write-wins.
  ConflictResolutionService get conflictResolution => _conflictResolution;

  // ─── Constructor ────────────────────────────────────────────

  OfflineManager({
    required TaskDao taskDao,
    required HabitDao habitDao,
    required GoalDao goalDao,
    required AvatarDao avatarDao,
    required WorldDao worldDao,
    required AchievementDao achievementDao,
    required ProgressDao progressDao,
    required NotificationDao notificationDao,
    required SyncRepository syncRepository,
    required ConflictResolutionService conflictResolution,
  })  : _taskDao = taskDao,
        _habitDao = habitDao,
        _goalDao = goalDao,
        _avatarDao = avatarDao,
        _worldDao = worldDao,
        _achievementDao = achievementDao,
        _progressDao = progressDao,
        _notificationDao = notificationDao,
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

    // Trigger a debounced sync whenever any local Drift table changes (i.e. a
    // repository wrote a dirty row). This keeps the network entirely out of the
    // repositories' write path — they just write locally and mark rows dirty,
    // and this listener schedules the push. All sync gates still apply, so this
    // is a no-op while sync is disabled or the user isn't entitled.
    _tableUpdatesSubscription =
        _taskDao.attachedDatabase.tableUpdates().listen((_) {
      scheduleSync();
    });

    // Start the periodic timer now if we're already authenticated + entitled
    // (e.g. a warm start after login). It's a guarded no-op otherwise.
    _maybeStartPeriodicSync();
  }

  /// Debounced local-write trigger. Coalesces bursts of Drift writes into a
  /// single [syncNow] call. Respects every sync gate so it stays dormant while
  /// sync is disabled, the user is unentitled, offline, unauthenticated, or a
  /// sync is already running.
  void scheduleSync() {
    if (!SyncConfig.enabled || !_isEntitled) return;
    if (!_isOnline || !_isAuthenticated || _isSyncing) return;
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounceDelay, () {
      if (!_isSyncing) syncNow();
    });
  }

  // ─── Sync ───────────────────────────────────────────────────

  /// Push pending local changes then pull remote changes.
  Future<void> syncNow() async {
    // Sync is a premium feature. [SyncConfig.enabled] is the global rollout
    // kill-switch; [_isEntitled] is the per-user premium gate. The app is fully
    // local-first regardless; nothing here runs while either is off.
    if (!SyncConfig.enabled || !_isEntitled) return;
    if (!_isOnline || _isSyncing || !_isAuthenticated) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Row-based, dirty-flag sync for all migrated entities.
      await _pushTasks();
      await _pushHabits();
      await _pushGoals();
      await _pushAvatar();
      await _pushWorldTiles();
      await _pushAchievements();
      await _pushProgress();
      await _pushNotifications();
      await _pullRows();

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

  // ─── Conflict handling ──────────────────────────────────────

  /// Extract the set of entity ids the server rejected as conflicts for
  /// [entityType] from a `/sync/push` response. A conflict means the server's
  /// copy was modified *strictly after* our operation's timestamp, so by
  /// last-write-wins (local wins ties) the server wins that row. We therefore
  /// must NOT mark those rows synced — they stay dirty and the following
  /// [_pullRows] applies the server's strictly-newer copy via `_applyRemoteX`
  /// (which itself enforces LWW with local winning ties).
  Set<String> _conflictedIds(Map<String, dynamic> resp, String entityType) {
    final raw = resp['conflicts'];
    if (raw is! List) return const {};
    final ids = <String>{};
    for (final c in raw) {
      if (c is Map && c['entity_type']?.toString() == entityType) {
        final id = c['entity_id']?.toString();
        if (id != null) ids.add(id);
      }
    }
    return ids;
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

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'task');
    final synced = [for (final t in dirty) if (!conflicts.contains(t.id)) t.id];
    await _taskDao.markSynced(synced, DateTime.now());
    await _taskDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} task rows (${conflicts.length} conflicts kept dirty)');
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
        case 'world_tile':
          await _applyRemoteWorldTile(userId, remote);
        case 'achievement':
          await _applyRemoteAchievement(userId, remote);
        case 'progress_entry':
          await _applyRemoteProgress(userId, remote);
        case 'notification':
          await _applyRemoteNotification(userId, remote);
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

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'habit');
    final synced = [for (final h in dirty) if (!conflicts.contains(h.id)) h.id];
    await _habitDao.markSynced(synced, DateTime.now());
    await _habitDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} habit rows (${conflicts.length} conflicts kept dirty)');
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

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'goal');
    final synced = [for (final g in dirty) if (!conflicts.contains(g.id)) g.id];
    await _goalDao.markSynced(synced, DateTime.now());
    await _goalDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} goal rows (${conflicts.length} conflicts kept dirty)');
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

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'avatar');
    final synced = [for (final a in dirty) if (!conflicts.contains(a.id)) a.id];
    await _avatarDao.markSynced(synced, DateTime.now());
    await _avatarDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} avatar rows (${conflicts.length} conflicts kept dirty)');
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

  // ─── Row-based World tile sync (offline-first) ──────────────

  Future<void> _pushWorldTiles() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _worldDao.getDirtyTiles(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final w in dirty)
        {
          'operation_type': w.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'world_tile',
          'entity_id': w.id,
          'data': jsonEncode(_worldTileWire(w)),
          'timestamp': w.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'world_tile');
    final synced = [for (final w in dirty) if (!conflicts.contains(w.id)) w.id];
    await _worldDao.markSynced(synced, DateTime.now());
    await _worldDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} world tile rows (${conflicts.length} conflicts kept dirty)');
  }

  /// World tiles are seeded independently on each device, so the grid position
  /// is the natural key — match on it to avoid duplicating tiles.
  Future<void> _applyRemoteWorldTile(
      String userId, Map<String, dynamic> r) async {
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final isDeleted = r['is_deleted'] == true;
    final posX = (r['position_x'] as num?)?.toInt() ?? 0;
    final posY = (r['position_y'] as num?)?.toInt() ?? 0;
    final local = await _worldDao.getTileByPosition(userId, posX, posY);

    // Local wins ties: only apply when the server copy is strictly newer.
    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    if (isDeleted) {
      if (local != null) await _worldDao.hardDeleteTile(local.id);
      return;
    }
    await _worldDao.upsertTile(
      _companionFromRemoteWorldTile(userId, r, remoteUpdated, local?.id),
    );
  }

  Map<String, dynamic> _worldTileWire(WorldTile w) => {
        'id': w.id,
        'user_id': w.userId,
        'name': w.name,
        'description': w.description,
        'image_path': w.imagePath,
        'tile_type': w.tileType,
        'is_unlocked': w.isUnlocked,
        'unlock_requirement': w.unlockRequirement,
        'unlock_category': w.unlockCategory,
        'position_x': w.positionX,
        'position_y': w.positionY,
        'unlocked_at': w.unlockedAt?.toUtc().toIso8601String(),
        'is_deleted': w.isDeleted,
        'updated_at': w.updatedAt.toUtc().toIso8601String(),
      };

  WorldTilesCompanion _companionFromRemoteWorldTile(
      String userId, Map<String, dynamic> r, DateTime? updated, String? existingId) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return WorldTilesCompanion(
      id: Value(existingId ?? r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      name: Value((r['name'] ?? 'Tile').toString()),
      description: Value(r['description']?.toString()),
      imagePath: Value(r['image_path']?.toString()),
      tileType: Value((r['tile_type'] ?? 'grass').toString()),
      isUnlocked: Value(r['is_unlocked'] == true),
      unlockRequirement: Value((r['unlock_requirement'] as num?)?.toInt() ?? 0),
      unlockCategory: Value(r['unlock_category']?.toString()),
      positionX: Value((r['position_x'] as num?)?.toInt() ?? 0),
      positionY: Value((r['position_y'] as num?)?.toInt() ?? 0),
      unlockedAt: Value(parse(r['unlocked_at'])),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: const Value(false),
      deletedAt: const Value(null),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  // ─── Row-based Achievement sync (offline-first) ─────────────

  Future<void> _pushAchievements() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _achievementDao.getDirtyAchievements(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final a in dirty)
        {
          'operation_type': a.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'achievement',
          'entity_id': a.id,
          'data': jsonEncode(_achievementWire(a)),
          'timestamp': a.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'achievement');
    final synced = [for (final a in dirty) if (!conflicts.contains(a.id)) a.id];
    await _achievementDao.markSynced(synced, DateTime.now());
    await _achievementDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} achievement rows (${conflicts.length} conflicts kept dirty)');
  }

  /// Achievements are seeded independently per device, so the title is the
  /// natural key — match on it to avoid duplicating the gallery.
  Future<void> _applyRemoteAchievement(
      String userId, Map<String, dynamic> r) async {
    final title = (r['title'] ?? '').toString();
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final isDeleted = r['is_deleted'] == true;
    final local = await _achievementDao.getAchievementByTitle(userId, title);

    // Local wins ties: only apply when the server copy is strictly newer.
    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    if (isDeleted) {
      if (local != null) {
        await _achievementDao.hardDeleteAchievement(local.id);
      }
      return;
    }
    await _achievementDao.upsertAchievement(
      _companionFromRemoteAchievement(userId, r, remoteUpdated, local?.id),
    );
  }

  Map<String, dynamic> _achievementWire(Achievement a) {
    Map<String, dynamic>? criteria;
    if (a.criteria != null && a.criteria!.isNotEmpty) {
      try {
        criteria = jsonDecode(a.criteria!) as Map<String, dynamic>;
      } catch (_) {
        // Malformed criteria — omit it.
      }
    }
    return {
      'id': a.id,
      'user_id': a.userId,
      'title': a.title,
      'description': a.description,
      'icon_path': a.iconPath,
      'type': a.achievementType,
      'criteria': criteria,
      'is_unlocked': a.isUnlocked,
      'progress': a.progress,
      'unlocked_at': a.unlockedAt?.toUtc().toIso8601String(),
      'is_deleted': a.isDeleted,
      'updated_at': a.updatedAt.toUtc().toIso8601String(),
    };
  }

  AchievementsCompanion _companionFromRemoteAchievement(
      String userId, Map<String, dynamic> r, DateTime? updated, String? existingId) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    String? criteriaJson;
    final c = r['criteria'];
    if (c is Map) {
      criteriaJson = jsonEncode(c);
    } else if (c is String && c.isNotEmpty) {
      criteriaJson = c;
    } else if (r['target_value'] != null) {
      criteriaJson = jsonEncode({
        'target_value': (r['target_value'] as num).toDouble(),
        'category': r['category'],
        'task_type': null,
      });
    }
    return AchievementsCompanion(
      id: Value(existingId ?? r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      title: Value((r['title'] ?? '').toString()),
      description: Value(r['description']?.toString()),
      iconPath: Value(r['icon_path']?.toString()),
      achievementType: Value((r['type'] ?? 'milestone').toString()),
      criteria: Value(criteriaJson),
      isUnlocked: Value(r['is_unlocked'] == true),
      progress: Value((r['progress'] as num?)?.toDouble() ?? 0.0),
      unlockedAt: Value(parse(r['unlocked_at'])),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: const Value(false),
      deletedAt: const Value(null),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  // ─── Row-based Progress entry sync (offline-first) ──────────

  Future<void> _pushProgress() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _progressDao.getDirtyEntries(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final p in dirty)
        {
          'operation_type': p.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'progress_entry',
          'entity_id': p.id,
          'data': jsonEncode(_progressWire(p)),
          'timestamp': p.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'progress_entry');
    final synced = [for (final p in dirty) if (!conflicts.contains(p.id)) p.id];
    await _progressDao.markSynced(synced, DateTime.now());
    await _progressDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} progress rows (${conflicts.length} conflicts kept dirty)');
  }

  /// Daily entries are keyed by calendar day (one per day), seeded
  /// independently per device — match on the day to avoid duplicates.
  Future<void> _applyRemoteProgress(
      String userId, Map<String, dynamic> r) async {
    final date =
        DateTime.tryParse(r['date']?.toString() ?? '')?.toLocal() ??
            DateTime.now();
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final isDeleted = r['is_deleted'] == true;
    final local = await _progressDao.getEntryForDay(userId, date);

    // Local wins ties: only apply when the server copy is strictly newer.
    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    if (isDeleted) {
      if (local != null) await _progressDao.hardDeleteEntry(local.id);
      return;
    }
    await _progressDao.upsertProgress(
      _companionFromRemoteProgress(userId, r, remoteUpdated, local?.id, date),
    );
  }

  Map<String, dynamic> _progressWire(ProgressEntry p) {
    Map<String, dynamic>? decode(String? s) {
      if (s == null || s.isEmpty) return null;
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    return {
      'id': p.id,
      'user_id': p.userId,
      'date': p.date.toUtc().toIso8601String(),
      'xp_gained': p.xpGained,
      'tasks_completed': p.tasksCompleted,
      'category': p.category,
      'category_breakdown': decode(p.categoryBreakdown),
      'task_type_breakdown': decode(p.taskTypeBreakdown),
      'streak_count': p.streakCount,
      'level_at_time': p.levelAtTime,
      'additional_metrics': decode(p.additionalMetrics),
      'is_deleted': p.isDeleted,
      'updated_at': p.updatedAt.toUtc().toIso8601String(),
    };
  }

  ProgressEntriesCompanion _companionFromRemoteProgress(String userId,
      Map<String, dynamic> r, DateTime? updated, String? existingId, DateTime date) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    String? enc(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isEmpty ? null : v;
      return jsonEncode(v);
    }

    return ProgressEntriesCompanion(
      id: Value(existingId ?? r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      date: Value(date),
      xpGained: Value((r['xp_gained'] as num?)?.toInt() ?? 0),
      tasksCompleted: Value((r['tasks_completed'] as num?)?.toInt() ?? 0),
      category: Value(r['category']?.toString()),
      categoryBreakdown: Value(enc(r['category_breakdown'])),
      taskTypeBreakdown: Value(enc(r['task_type_breakdown'])),
      streakCount: Value((r['streak_count'] as num?)?.toInt() ?? 0),
      levelAtTime: Value((r['level_at_time'] as num?)?.toInt() ?? 1),
      additionalMetrics: Value(enc(r['additional_metrics'])),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: const Value(false),
      deletedAt: const Value(null),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  // ─── Row-based Notification sync (offline-first, server-push) ─

  Future<void> _pushNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final dirty = await _notificationDao.getDirtyNotifications(userId);
    if (dirty.isEmpty) return;

    final ops = [
      for (final n in dirty)
        {
          'operation_type': n.isDeleted ? 'Delete' : 'Update',
          'entity_type': 'notification',
          'entity_id': n.id,
          'data': jsonEncode(_notificationWire(n)),
          'timestamp': n.updatedAt.toUtc().toIso8601String(),
          'version': 1,
        }
    ];

    final resp = await _syncRepository.pushSync(ops);
    final conflicts = _conflictedIds(resp, 'notification');
    final synced = [for (final n in dirty) if (!conflicts.contains(n.id)) n.id];
    await _notificationDao.markSynced(synced, DateTime.now());
    await _notificationDao.purgeSyncedTombstones();
    _log.d(
        'OfflineManager: Pushed ${ops.length} notification rows (${conflicts.length} conflicts kept dirty)');
  }

  /// Notifications are unique server-pushed events, so the id is the key.
  Future<void> _applyRemoteNotification(
      String userId, Map<String, dynamic> r) async {
    final id = r['id'].toString();
    final remoteUpdated =
        DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal();
    final isDeleted = r['is_deleted'] == true;
    final local = await _notificationDao.getNotificationById(id);

    // Local wins ties: only apply when the server copy is strictly newer.
    if (local != null &&
        remoteUpdated != null &&
        !remoteUpdated.isAfter(local.updatedAt)) {
      return;
    }
    if (isDeleted) {
      if (local != null) await _notificationDao.hardDeleteNotification(id);
      return;
    }
    await _notificationDao.upsertNotification(
      _companionFromRemoteNotification(userId, r, remoteUpdated),
    );
  }

  Map<String, dynamic> _notificationWire(Notification n) => {
        'id': n.id,
        'user_id': n.userId,
        'title': n.title,
        'body': n.body,
        'type': n.type,
        'data': n.data,
        'is_read': n.isRead,
        'read_at': n.readAt?.toUtc().toIso8601String(),
        'entity_type': n.entityType,
        'entity_id': n.entityId,
        'is_deleted': n.isDeleted,
        'updated_at': n.updatedAt.toUtc().toIso8601String(),
      };

  NotificationsCompanion _companionFromRemoteNotification(
      String userId, Map<String, dynamic> r, DateTime? updated) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    // Backend lowercases enum names; restore the camelCase notification types.
    String type(String t) => switch (t.toLowerCase()) {
          'dailysummary' => 'dailySummary',
          'taskreminder' => 'taskReminder',
          'goaldeadline' => 'goalDeadline',
          'streakalert' => 'streakAlert',
          'achievementunlocked' => 'achievementUnlocked',
          'levelup' => 'levelUp',
          'habitreminder' => 'habitReminder',
          'systemmessage' => 'systemMessage',
          _ => t,
        };
    return NotificationsCompanion(
      id: Value(r['id'].toString()),
      userId: Value((r['user_id'] ?? userId).toString()),
      title: Value((r['title'] ?? '').toString()),
      body: Value((r['body'] ?? '').toString()),
      type: Value(type((r['type'] ?? 'systemMessage').toString())),
      data: Value(r['data']?.toString()),
      isRead: Value(r['is_read'] == true),
      readAt: Value(parse(r['read_at'])),
      entityType: Value(r['entity_type']?.toString()),
      entityId: Value(r['entity_id']?.toString()),
      createdAt: Value(parse(r['created_at']) ?? DateTime.now()),
      updatedAt: Value(updated ?? DateTime.now()),
      isDirty: const Value(false),
      isDeleted: const Value(false),
      deletedAt: const Value(null),
      lastSyncedAt: Value(DateTime.now()),
    );
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

  /// Starts the periodic timer only when sync is actually eligible to run
  /// (enabled, entitled, authenticated). Used at init/login so the timer isn't
  /// only started on app-resume.
  void _maybeStartPeriodicSync() {
    if (!SyncConfig.enabled || !_isEntitled || !_isAuthenticated) return;
    _startPeriodicSync();
  }

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
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = null;
    _connectivitySubscription?.cancel();
    _tableUpdatesSubscription?.cancel();
    _syncStatusController.close();
    _lastSyncTimeController.close();
  }
}
