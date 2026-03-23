import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class TaskRepository extends BaseRepository {
  TaskRepository(super.apiService);

  /// Fetch tasks with optional filters.
  Future<List<Task>> getTasks({
    String? category,
    String? type,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (type != null) queryParams['type'] = type;
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final response = await apiService.get(
      '/tasks',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return parseList(response.data, Task.fromJson);
  }

  /// Create a new task.
  Future<Task> createTask(Map<String, dynamic> data) async {
    final response = await apiService.post('/tasks', data: data);
    return Task.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update an existing task.
  Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    final response = await apiService.put('/tasks/$id', data: data);
    return Task.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mark a task as completed.
  Future<Map<String, dynamic>> completeTask(String id) async {
    final response = await apiService.post('/tasks/$id/complete');
    return response.data as Map<String, dynamic>;
  }

  /// Delete a task.
  Future<void> deleteTask(String id) async {
    await apiService.delete('/tasks/$id');
  }

  /// Batch-complete multiple tasks.
  Future<Map<String, dynamic>> batchComplete(List<String> taskIds) async {
    final response = await apiService.post(
      '/tasks/batch-complete',
      data: {'task_ids': taskIds},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get task statistics.
  Future<Map<String, dynamic>> getTaskStats() async {
    final response = await apiService.get('/tasks/stats');
    return response.data as Map<String, dynamic>;
  }

  /// Get task completion trend.
  Future<Map<String, dynamic>> getTaskTrend() async {
    final response = await apiService.get('/tasks/trend');
    return response.data as Map<String, dynamic>;
  }
}
