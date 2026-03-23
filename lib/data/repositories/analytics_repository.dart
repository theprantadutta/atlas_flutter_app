import 'package:atlas_flutter_app/core/utils/lru_cache.dart';
import 'package:atlas_flutter_app/data/models/analytics_data.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class AnalyticsRepository extends BaseRepository {
  AnalyticsRepository(
    super.apiService,
    super.offlineManager,
  );

  // ─── Cache ───────────────────────────────────────────────────

  final LRUCache<String, AnalyticsData> _dashboardCache =
      LRUCache(maxSize: 50, ttl: Duration(minutes: 5));

  // ─── READ operations ─────────────────────────────────────────

  /// Get the analytics dashboard data.
  Future<AnalyticsData> getDashboard() async {
    // 1. Check cache
    final cached = _dashboardCache.get('dashboard');
    if (cached != null) return cached;

    // 2. Fetch from API (read-only, no offline queueing)
    final response = await apiService.get('/analytics/dashboard');
    final data = AnalyticsData.fromJson(response.data as Map<String, dynamic>);
    _dashboardCache.put('dashboard', data);
    return data;
  }
}
