import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/database/daos/goal_dao.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/goal.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class GoalRepository extends BaseRepository {
  final GoalDao _goalDao;

  GoalRepository(
    super.apiService,
    super.offlineManager,
    this._goalDao,
  );

  // ─── Caches ──────────────────────────────────────────────────

  final LRUCache<String, List<Goal>> _collectionCache =
      LRUCache(maxSize: 100, ttl: Duration(minutes: 5));
  final LRUCache<String, Goal> _entityCache =
      LRUCache(maxSize: 200, ttl: Duration(minutes: 5));
  final LRUCache<String, Map<String, dynamic>> _statsCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 5));

  // ─── Cache key helpers ───────────────────────────────────────

  String _collectionKey({
    String? category,
    String? status,
    String? priority,
    String? search,
  }) =>
      'goals:$category:$status:$priority:$search';

  // ─── READ operations ─────────────────────────────────────────

  /// Fetch all goals with optional filters.
  Future<List<Goal>> getGoals({
    String? category,
    String? status,
    String? priority,
    String? search,
  }) async {
    final cacheKey = _collectionKey(
      category: category,
      status: status,
      priority: priority,
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
        if (status != null) queryParams['status'] = status;
        if (priority != null) queryParams['priority'] = priority;
        if (search != null) queryParams['search'] = search;

        final response = await apiService.get(
          '/goals',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        final goals = parseList(response.data, Goal.fromJson);

        _collectionCache.put(cacheKey, goals);
        for (final goal in goals) {
          _entityCache.put(goal.id, goal);
        }
        return goals;
      } catch (_) {
        // API failed — fall through to DAO
      }
    }

    // 3. Offline fallback: read from local DAO
    try {
      final localGoals = await _goalDao.getAllGoals('');
      final goals = localGoals
          .map((g) => Goal.fromJson(_driftGoalToJson(g)))
          .toList();
      _collectionCache.put(cacheKey, goals);
      return goals;
    } catch (_) {
      return [];
    }
  }

  // ─── WRITE operations ────────────────────────────────────────

  /// Create a new goal.
  Future<Goal> createGoal(Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response = await apiService.post('/goals', data: data);
        final goal = Goal.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put(goal.id, goal);
        _invalidateCollectionCaches();
        return goal;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'create',
      entityType: 'goal',
      entityId: data['id']?.toString() ?? const Uuid().v4(),
      data: data,
    );
    _invalidateCollectionCaches();
    return Goal.fromJson(data);
  }

  /// Update an existing goal.
  Future<Goal> updateGoal(String id, Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response = await apiService.put('/goals/$id', data: data);
        final goal = Goal.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put(id, goal);
        _invalidateCollectionCaches();
        return goal;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'update',
      entityType: 'goal',
      entityId: id,
      data: data,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();

    final existing = _entityCache.get(id);
    if (existing != null) {
      final merged = <String, dynamic>{...existing.toJson(), ...data};
      return Goal.fromJson(merged);
    }
    return Goal.fromJson({...data, 'id': id});
  }

  /// Delete a goal.
  Future<void> deleteGoal(String id) async {
    if (isOnline) {
      try {
        await apiService.delete('/goals/$id');
        _entityCache.remove(id);
        _invalidateCollectionCaches();
        return;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'delete',
      entityType: 'goal',
      entityId: id,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();
  }

  /// Update progress on a goal.
  Future<Map<String, dynamic>> updateGoalProgress(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (isOnline) {
      try {
        final response =
            await apiService.post('/goals/$id/progress', data: data);
        _entityCache.remove(id);
        _invalidateCollectionCaches();
        _statsCache.clear();
        return response.data as Map<String, dynamic>;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'update_progress',
      entityType: 'goal',
      entityId: id,
      data: data,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();
    _statsCache.clear();

    return {'id': id, ...data};
  }

  /// Get overdue goals.
  Future<List<Goal>> getOverdueGoals() async {
    const cacheKey = 'goals:overdue';

    final cached = _collectionCache.get(cacheKey);
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/goals/overdue');
        final goals = parseList(response.data, Goal.fromJson);
        _collectionCache.put(cacheKey, goals);
        for (final goal in goals) {
          _entityCache.put(goal.id, goal);
        }
        return goals;
      } catch (_) {
        // Fall through
      }
    }

    // Offline: filter from local DAO
    try {
      final localGoals = await _goalDao.getAllGoals('');
      final now = DateTime.now();
      final goals = localGoals
          .map((g) => Goal.fromJson(_driftGoalToJson(g)))
          .where((g) =>
              g.deadline != null &&
              g.deadline!.isBefore(now) &&
              g.status != GoalStatus.completed)
          .toList();
      _collectionCache.put(cacheKey, goals);
      return goals;
    } catch (_) {
      return [];
    }
  }

  /// Get goals due soon.
  Future<List<Goal>> getGoalsDueSoon() async {
    const cacheKey = 'goals:due_soon';

    final cached = _collectionCache.get(cacheKey);
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/goals/due-soon');
        final goals = parseList(response.data, Goal.fromJson);
        _collectionCache.put(cacheKey, goals);
        for (final goal in goals) {
          _entityCache.put(goal.id, goal);
        }
        return goals;
      } catch (_) {
        // Fall through
      }
    }

    return [];
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _invalidateCollectionCaches() {
    _collectionCache.clear();
  }

  Map<String, dynamic> _driftGoalToJson(dynamic driftGoal) {
    return {
      'id': driftGoal.id,
      'user_id': driftGoal.userId,
      'title': driftGoal.title,
      'description': driftGoal.description,
      'category': driftGoal.category,
      'priority': driftGoal.priority,
      'status': driftGoal.status,
      'progress': driftGoal.progress,
      'start_date': driftGoal.startDate?.toIso8601String(),
      'deadline': driftGoal.deadline?.toIso8601String(),
      'completed_at': driftGoal.completedAt?.toIso8601String(),
      'parent_goal_id': driftGoal.parentGoalId,
      'created_at': driftGoal.createdAt.toIso8601String(),
      'updated_at': driftGoal.updatedAt.toIso8601String(),
    };
  }
}
