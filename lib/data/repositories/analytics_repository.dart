import 'package:atlas_flutter_app/data/models/analytics_data.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class AnalyticsRepository extends BaseRepository {
  AnalyticsRepository(super.apiService);

  /// Get the analytics dashboard data.
  Future<AnalyticsData> getDashboard() async {
    final response = await apiService.get('/analytics/dashboard');
    return AnalyticsData.fromJson(response.data as Map<String, dynamic>);
  }
}
