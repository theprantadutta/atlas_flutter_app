import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/daos/sync_dao.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/repositories/sync_repository.dart';
import 'package:atlas_flutter_app/data/services/conflict_resolution_service.dart';

/// Sync status emitted by [OfflineManager].
enum SyncStatus { idle, syncing, error }

/// Central sync orchestrator that queues offline operations, pushes them
/// when connectivity is restored, and pulls remote changes periodically.
class OfflineManager {
  final SyncDao _syncDao;
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
    required SyncRepository syncRepository,
    required ConflictResolutionService conflictResolution,
  })  : _syncDao = syncDao,
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
    if (!_isOnline || _isSyncing || !_isAuthenticated) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      await _pushChanges();
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
