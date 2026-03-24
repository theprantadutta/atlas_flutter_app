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
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Call when auth state changes. Sync only runs when authenticated.
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    if (authenticated && _isOnline) {
      syncNow();
    }
    if (!authenticated) {
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

    for (final op in pending) {
      // Check retry eligibility using the model's fields directly
      final retryDelay =
          Duration(seconds: (1 << op.retryCount).clamp(1, 300));
      final isReady =
          op.retryCount < op.maxRetries &&
          DateTime.now().isAfter(op.timestamp.add(retryDelay));

      if (!isReady) continue;

      try {
        final payload = <String, dynamic>{
          'id': op.id,
          'operation_type': op.operationType,
          'entity_type': op.entityType,
          'entity_id': op.entityId,
          'timestamp': op.timestamp.toIso8601String(),
        };
        if (op.data != null) {
          payload['data'] = jsonDecode(op.data!);
        }

        await _syncRepository.pushSync(payload);
        await _syncDao.deleteOperation(op.id);
        _log.d(
            'OfflineManager: Pushed ${op.operationType} for ${op.entityType}/${op.entityId}');
      } catch (e) {
        if (op.retryCount + 1 >= op.maxRetries) {
          _log.w(
              'OfflineManager: Max retries exceeded for ${op.id}, removing');
          await _syncDao.deleteOperation(op.id);
        } else {
          await _syncDao.incrementRetry(op.id);
          _log.d(
              'OfflineManager: Retry ${op.retryCount + 1} for ${op.id}');
        }
      }
    }
  }

  // ─── Pull ───────────────────────────────────────────────────

  Future<void> _pullChanges() async {
    try {
      final response = await _syncRepository.pullSync(
        lastSyncTimestamp: _lastSyncTime?.toIso8601String(),
      );

      for (final entityType in _pullHandlers.keys) {
        final entities = response[entityType];
        if (entities != null && entities is List && entities.isNotEmpty) {
          final typed = entities
              .map((e) => e as Map<String, dynamic>)
              .toList();
          await _pullHandlers[entityType]!(typed);
          _log.d(
              'OfflineManager: Pulled ${typed.length} $entityType entities');
        }
      }
    } catch (e) {
      _log.e('OfflineManager: Pull failed', error: e);
      rethrow;
    }
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
