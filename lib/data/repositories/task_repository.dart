import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class TaskRepository extends BaseRepository {
  final TaskDao _taskDao;

  TaskRepository(
    super.apiService,
    super.offlineManager,
    this._taskDao,
  );

  // ─── Caches ──────────────────────────────────────────────────

  final LRUCache<String, List<Task>> _collectionCache =
      LRUCache(maxSize: 100, ttl: Duration(minutes: 3));
  final LRUCache<String, Task> _entityCache =
      LRUCache(maxSize: 200, ttl: Duration(minutes: 3));
  final LRUCache<String, Map<String, dynamic>> _statsCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 5));

  // ─── Cache key helpers ───────────────────────────────────────

  String _collectionKey({
    String? category,
    String? type,
    String? status,
    String? search,
  }) =>
      'tasks:$category:$type:$status:$search';

  // ─── READ operations ─────────────────────────────────────────

  /// Fetch tasks with optional filters.
  Future<List<Task>> getTasks({
    String? category,
    String? type,
    String? status,
    String? search,
  }) async {
    final cacheKey = _collectionKey(
      category: category,
      type: type,
      status: status,
      search: search,
    );

    // 1. Check LRU cache
    final cached = _collectionCache.get(cacheKey);
    if (cached != null) return cached;

    // 2. If online, try API
    if (isOnline) {
      try {
        final queryParams = <String, dynamic>{};
        if (category != null) queryParams['category'] = category;
        if (type != null) queryParams['type'] = type;
        if (status != null) queryParams['status'] = status;
        if (search != null) queryParams['search'] = search;

        final response = await apiService.get(
          '/tasks',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        final tasks = parseList(response.data, Task.fromJson);

        // Cache the collection and individual entities
        _collectionCache.put(cacheKey, tasks);
        for (final task in tasks) {
          _entityCache.put(task.id, task);
        }
        return tasks;
      } catch (_) {
        // API failed — fall through to DAO
      }
    }

    // 3. Offline fallback: read from local DAO
    try {
      final localTasks = await _taskDao.getAllTasks('');
      final tasks = localTasks
          .map((t) => Task.fromJson(_driftTaskToJson(t)))
          .toList();
      _collectionCache.put(cacheKey, tasks);
      return tasks;
    } catch (_) {
      return [];
    }
  }

  /// Get a single task by ID.
  Future<Task> getTaskById(String id) async {
    // 1. Check entity cache
    final cached = _entityCache.get(id);
    if (cached != null) return cached;

    // 2. If online, try API
    if (isOnline) {
      try {
        final response = await apiService.get('/tasks/$id');
        final task = Task.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put(id, task);
        return task;
      } catch (_) {
        // Fall through to DAO
      }
    }

    // 3. Offline fallback
    final local = await _taskDao.getTaskById(id);
    if (local != null) {
      final task = Task.fromJson(_driftTaskToJson(local));
      _entityCache.put(id, task);
      return task;
    }

    throw Exception('Task $id not found');
  }

  // ─── WRITE operations ────────────────────────────────────────

  /// Create a new task.
  Future<Task> createTask(Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response = await apiService.post('/tasks', data: data);
        final task = Task.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put(task.id, task);
        _invalidateCollectionCaches();
        return task;
      } catch (_) {
        // Fall through to queue
      }
    }

    // Queue for later sync
    await offlineManager.queueOperation(
      operationType: 'create',
      entityType: 'task',
      entityId: data['id']?.toString() ?? '',
      data: data,
    );
    _invalidateCollectionCaches();

    // Return an optimistic task from the provided data
    return Task.fromJson(data);
  }

  /// Update an existing task.
  Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response = await apiService.put('/tasks/$id', data: data);
        final task = Task.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put(id, task);
        _invalidateCollectionCaches();
        return task;
      } catch (_) {
        // Fall through to queue
      }
    }

    // Queue for later sync
    await offlineManager.queueOperation(
      operationType: 'update',
      entityType: 'task',
      entityId: id,
      data: data,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();

    // Return optimistic result: merge existing cache with updates
    final existing = _entityCache.get(id);
    if (existing != null) {
      final merged = <String, dynamic>{...existing.toJson(), ...data};
      return Task.fromJson(merged);
    }
    return Task.fromJson({...data, 'id': id});
  }

  /// Mark a task as completed.
  Future<Map<String, dynamic>> completeTask(String id) async {
    if (isOnline) {
      try {
        final response = await apiService.post('/tasks/$id/complete');
        _entityCache.remove(id);
        _invalidateCollectionCaches();
        _statsCache.clear();
        return response.data as Map<String, dynamic>;
      } catch (_) {
        // Fall through to queue
      }
    }

    // Queue for later sync
    await offlineManager.queueOperation(
      operationType: 'complete',
      entityType: 'task',
      entityId: id,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();
    _statsCache.clear();

    return {'id': id, 'is_completed': true};
  }

  /// Delete a task.
  Future<void> deleteTask(String id) async {
    if (isOnline) {
      try {
        await apiService.delete('/tasks/$id');
        _entityCache.remove(id);
        _invalidateCollectionCaches();
        return;
      } catch (_) {
        // Fall through to queue
      }
    }

    // Queue for later sync
    await offlineManager.queueOperation(
      operationType: 'delete',
      entityType: 'task',
      entityId: id,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();
  }

  /// Batch-complete multiple tasks.
  Future<Map<String, dynamic>> batchComplete(List<String> taskIds) async {
    if (isOnline) {
      try {
        final response = await apiService.post(
          '/tasks/batch-complete',
          data: {'task_ids': taskIds},
        );
        for (final id in taskIds) {
          _entityCache.remove(id);
        }
        _invalidateCollectionCaches();
        _statsCache.clear();
        return response.data as Map<String, dynamic>;
      } catch (_) {
        // Fall through to queue
      }
    }

    // Queue individual complete operations
    for (final id in taskIds) {
      await offlineManager.queueOperation(
        operationType: 'complete',
        entityType: 'task',
        entityId: id,
      );
      _entityCache.remove(id);
    }
    _invalidateCollectionCaches();
    _statsCache.clear();

    return {'completed': taskIds.length, 'task_ids': taskIds};
  }

  // ─── STATS operations ───────────────────────────────────────

  /// Get task statistics.
  Future<Map<String, dynamic>> getTaskStats() async {
    final cached = _statsCache.get('task_stats');
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/tasks/stats');
        final stats = response.data as Map<String, dynamic>;
        _statsCache.put('task_stats', stats);
        return stats;
      } catch (_) {
        // Fall through
      }
    }

    return {};
  }

  /// Get task completion trend.
  Future<Map<String, dynamic>> getTaskTrend() async {
    final cached = _statsCache.get('task_trend');
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/tasks/trend');
        final trend = response.data as Map<String, dynamic>;
        _statsCache.put('task_trend', trend);
        return trend;
      } catch (_) {
        // Fall through
      }
    }

    return {};
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _invalidateCollectionCaches() {
    _collectionCache.clear();
  }

  /// Converts a Drift Task data class to a JSON map compatible with the
  /// domain Task.fromJson factory. The Drift-generated class shares the
  /// same field names so we can cast through toJson-like accessors.
  Map<String, dynamic> _driftTaskToJson(dynamic driftTask) {
    // Drift data classes expose typed fields; build the map manually.
    return {
      'id': driftTask.id,
      'user_id': driftTask.userId,
      'title': driftTask.title,
      'description': driftTask.description,
      'type': driftTask.type,
      'category': driftTask.category,
      'xp_reward': driftTask.xpReward,
      'difficulty': driftTask.difficulty,
      'due_date': driftTask.dueDate?.toIso8601String(),
      'is_completed': driftTask.isCompleted,
      'streak_count': driftTask.streakCount,
      'last_completed_date': driftTask.lastCompletedDate?.toIso8601String(),
      'created_at': driftTask.createdAt.toIso8601String(),
      'updated_at': driftTask.updatedAt.toIso8601String(),
    };
  }
}
