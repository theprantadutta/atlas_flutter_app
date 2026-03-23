import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/database/daos/progress_dao.dart';
import 'package:atlas_flutter_app/data/models/progress_entry.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class ProgressRepository extends BaseRepository {
  final ProgressDao _progressDao;

  ProgressRepository(
    super.apiService,
    super.offlineManager,
    this._progressDao,
  );

  // ─── Caches ──────────────────────────────────────────────────

  final LRUCache<String, List<ProgressEntry>> _collectionCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 5));
  final LRUCache<String, Map<String, dynamic>> _statsCache =
      LRUCache(maxSize: 20, ttl: Duration(minutes: 5));

  // ─── Cache key helpers ───────────────────────────────────────

  String _collectionKey({String? startDate, String? endDate}) =>
      'progress:$startDate:$endDate';

  // ─── READ operations ─────────────────────────────────────────

  /// Get progress entries with optional date range.
  Future<List<ProgressEntry>> getProgress({
    String? startDate,
    String? endDate,
  }) async {
    final cacheKey = _collectionKey(startDate: startDate, endDate: endDate);

    // 1. Check LRU cache
    final cached = _collectionCache.get(cacheKey);
    if (cached != null) return cached;

    // 2. If online, try API
    if (isOnline) {
      try {
        final queryParams = <String, dynamic>{};
        if (startDate != null) queryParams['start_date'] = startDate;
        if (endDate != null) queryParams['end_date'] = endDate;

        final response = await apiService.get(
          '/progress',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        final entries = parseList(response.data, ProgressEntry.fromJson);

        _collectionCache.put(cacheKey, entries);
        return entries;
      } catch (_) {
        // API failed — fall through to DAO
      }
    }

    // 3. Offline fallback: read from local DAO
    try {
      final start = startDate != null
          ? DateTime.parse(startDate)
          : DateTime.now().subtract(const Duration(days: 30));
      final end =
          endDate != null ? DateTime.parse(endDate) : DateTime.now();

      final localEntries =
          await _progressDao.getProgressByDateRange('', start, end);
      final entries = localEntries
          .map((p) => ProgressEntry.fromJson(_driftProgressToJson(p)))
          .toList();
      _collectionCache.put(cacheKey, entries);
      return entries;
    } catch (_) {
      return [];
    }
  }

  // ─── STATS operations ───────────────────────────────────────

  /// Get progress trend data.
  Future<Map<String, dynamic>> getProgressTrend() async {
    final cached = _statsCache.get('progress_trend');
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/progress/trend');
        final trend = response.data as Map<String, dynamic>;
        _statsCache.put('progress_trend', trend);
        return trend;
      } catch (_) {
        // Fall through
      }
    }

    return {};
  }

  /// Get category breakdown of progress.
  Future<Map<String, dynamic>> getCategoryBreakdown() async {
    final cached = _statsCache.get('progress_categories');
    if (cached != null) return cached;

    if (isOnline) {
      try {
        final response = await apiService.get('/progress/categories');
        final breakdown = response.data as Map<String, dynamic>;
        _statsCache.put('progress_categories', breakdown);
        return breakdown;
      } catch (_) {
        // Fall through
      }
    }

    return {};
  }

  // ─── Helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _driftProgressToJson(dynamic driftProgress) {
    return {
      'id': driftProgress.id,
      'user_id': driftProgress.userId,
      'date': driftProgress.date.toIso8601String(),
      'xp_gained': driftProgress.xpGained,
      'tasks_completed': driftProgress.tasksCompleted,
      'category': driftProgress.category,
      'category_breakdown': driftProgress.categoryBreakdown,
      'task_type_breakdown': driftProgress.taskTypeBreakdown,
      'streak_count': driftProgress.streakCount,
      'level_at_time': driftProgress.levelAtTime,
      'additional_metrics': driftProgress.additionalMetrics,
      'created_at': driftProgress.createdAt.toIso8601String(),
      'updated_at': driftProgress.updatedAt.toIso8601String(),
    };
  }
}
