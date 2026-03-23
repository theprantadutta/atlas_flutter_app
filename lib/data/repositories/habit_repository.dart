import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/database/daos/habit_dao.dart';
import 'package:atlas_flutter_app/data/models/habit.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class HabitRepository extends BaseRepository {
  final HabitDao _habitDao;

  HabitRepository(
    super.apiService,
    super.offlineManager,
    this._habitDao,
  );

  // ─── Caches ──────────────────────────────────────────────────

  final LRUCache<String, List<Habit>> _collectionCache =
      LRUCache(maxSize: 100, ttl: Duration(minutes: 3));
  final LRUCache<String, Habit> _entityCache =
      LRUCache(maxSize: 200, ttl: Duration(minutes: 3));
  final LRUCache<String, Map<String, dynamic>> _statsCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 5));

  // ─── Cache key helpers ───────────────────────────────────────

  String _collectionKey({
    String? category,
    String? frequency,
    String? search,
  }) =>
      'habits:$category:$frequency:$search';

  // ─── READ operations ─────────────────────────────────────────

  /// Fetch all habits.
  Future<List<Habit>> getHabits({
    String? category,
    String? frequency,
    String? search,
  }) async {
    final cacheKey = _collectionKey(
      category: category,
      frequency: frequency,
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
        if (frequency != null) queryParams['frequency'] = frequency;
        if (search != null) queryParams['search'] = search;

        final response = await apiService.get(
          '/habits',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        final habits = parseList(response.data, Habit.fromJson);

        _collectionCache.put(cacheKey, habits);
        for (final habit in habits) {
          _entityCache.put(habit.id, habit);
        }
        return habits;
      } catch (_) {
        // API failed — fall through to DAO
      }
    }

    // 3. Offline fallback: read from local DAO
    try {
      final localHabits = await _habitDao.getAllHabits('');
      final habits = localHabits
          .map((h) => Habit.fromJson(_driftHabitToJson(h)))
          .toList();
      _collectionCache.put(cacheKey, habits);
      return habits;
    } catch (_) {
      return [];
    }
  }

  // ─── WRITE operations ────────────────────────────────────────

  /// Create a new habit.
  Future<Habit> createHabit(Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response = await apiService.post('/habits', data: data);
        final habit = Habit.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put(habit.id, habit);
        _invalidateCollectionCaches();
        return habit;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'create',
      entityType: 'habit',
      entityId: data['id']?.toString() ?? '',
      data: data,
    );
    _invalidateCollectionCaches();
    return Habit.fromJson(data);
  }

  /// Update an existing habit.
  Future<Habit> updateHabit(String id, Map<String, dynamic> data) async {
    if (isOnline) {
      try {
        final response = await apiService.put('/habits/$id', data: data);
        final habit = Habit.fromJson(response.data as Map<String, dynamic>);
        _entityCache.put(id, habit);
        _invalidateCollectionCaches();
        return habit;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'update',
      entityType: 'habit',
      entityId: id,
      data: data,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();

    final existing = _entityCache.get(id);
    if (existing != null) {
      final merged = <String, dynamic>{...existing.toJson(), ...data};
      return Habit.fromJson(merged);
    }
    return Habit.fromJson({...data, 'id': id});
  }

  /// Mark a habit as completed for today.
  Future<Map<String, dynamic>> completeHabit(String id) async {
    if (isOnline) {
      try {
        final response = await apiService.post('/habits/$id/complete');
        _entityCache.remove(id);
        _invalidateCollectionCaches();
        _statsCache.clear();
        return response.data as Map<String, dynamic>;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'complete',
      entityType: 'habit',
      entityId: id,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();
    _statsCache.clear();

    return {'id': id, 'is_completed_today': true};
  }

  /// Delete a habit.
  Future<void> deleteHabit(String id) async {
    if (isOnline) {
      try {
        await apiService.delete('/habits/$id');
        _entityCache.remove(id);
        _invalidateCollectionCaches();
        return;
      } catch (_) {
        // Fall through to queue
      }
    }

    await offlineManager.queueOperation(
      operationType: 'delete',
      entityType: 'habit',
      entityId: id,
    );
    _entityCache.remove(id);
    _invalidateCollectionCaches();
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _invalidateCollectionCaches() {
    _collectionCache.clear();
  }

  Map<String, dynamic> _driftHabitToJson(dynamic driftHabit) {
    return {
      'id': driftHabit.id,
      'user_id': driftHabit.userId,
      'title': driftHabit.title,
      'description': driftHabit.description,
      'category': driftHabit.category,
      'frequency': driftHabit.frequency,
      'difficulty': driftHabit.difficulty,
      'is_completed_today': driftHabit.isCompletedToday,
      'streak_count': driftHabit.streakCount,
      'longest_streak': driftHabit.longestStreak,
      'completion_rate': driftHabit.completionRate,
      'total_completions': driftHabit.totalCompletions,
      'reminder_time': driftHabit.reminderTime,
      'last_completed_date':
          driftHabit.lastCompletedDate?.toIso8601String(),
      'created_at': driftHabit.createdAt.toIso8601String(),
      'updated_at': driftHabit.updatedAt.toIso8601String(),
    };
  }
}
