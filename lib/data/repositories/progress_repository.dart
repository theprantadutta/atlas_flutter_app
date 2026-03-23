import 'package:atlas_flutter_app/data/models/progress_entry.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class ProgressRepository extends BaseRepository {
  ProgressRepository(super.apiService);

  /// Get progress entries with optional date range.
  Future<List<ProgressEntry>> getProgress({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await apiService.get(
      '/progress',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return parseList(response.data, ProgressEntry.fromJson);
  }

  /// Get progress trend data.
  Future<Map<String, dynamic>> getProgressTrend() async {
    final response = await apiService.get('/progress/trend');
    return response.data as Map<String, dynamic>;
  }

  /// Get category breakdown of progress.
  Future<Map<String, dynamic>> getCategoryBreakdown() async {
    final response = await apiService.get('/progress/categories');
    return response.data as Map<String, dynamic>;
  }
}
