import 'package:atlas_flutter_app/data/models/goal.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class GoalRepository extends BaseRepository {
  GoalRepository(super.apiService);

  /// Fetch all goals with optional filters.
  Future<List<Goal>> getGoals({
    String? category,
    String? status,
    String? priority,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (search != null) queryParams['search'] = search;

    final response = await apiService.get(
      '/goals',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return parseList(response.data, Goal.fromJson);
  }

  /// Create a new goal.
  Future<Goal> createGoal(Map<String, dynamic> data) async {
    final response = await apiService.post('/goals', data: data);
    return Goal.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update an existing goal.
  Future<Goal> updateGoal(String id, Map<String, dynamic> data) async {
    final response = await apiService.put('/goals/$id', data: data);
    return Goal.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a goal.
  Future<void> deleteGoal(String id) async {
    await apiService.delete('/goals/$id');
  }

  /// Update progress on a goal.
  Future<Map<String, dynamic>> updateGoalProgress(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.post('/goals/$id/progress', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Get overdue goals.
  Future<List<Goal>> getOverdueGoals() async {
    final response = await apiService.get('/goals/overdue');
    return parseList(response.data, Goal.fromJson);
  }

  /// Get goals due soon.
  Future<List<Goal>> getGoalsDueSoon() async {
    final response = await apiService.get('/goals/due-soon');
    return parseList(response.data, Goal.fromJson);
  }
}
