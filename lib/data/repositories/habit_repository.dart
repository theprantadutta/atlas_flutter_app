import 'package:atlas_flutter_app/data/models/habit.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class HabitRepository extends BaseRepository {
  HabitRepository(super.apiService);

  /// Fetch all habits.
  Future<List<Habit>> getHabits({
    String? category,
    String? frequency,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (frequency != null) queryParams['frequency'] = frequency;
    if (search != null) queryParams['search'] = search;

    final response = await apiService.get(
      '/habits',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return parseList(response.data, Habit.fromJson);
  }

  /// Create a new habit.
  Future<Habit> createHabit(Map<String, dynamic> data) async {
    final response = await apiService.post('/habits', data: data);
    return Habit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update an existing habit.
  Future<Habit> updateHabit(String id, Map<String, dynamic> data) async {
    final response = await apiService.put('/habits/$id', data: data);
    return Habit.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mark a habit as completed for today.
  Future<Map<String, dynamic>> completeHabit(String id) async {
    final response = await apiService.post('/habits/$id/complete');
    return response.data as Map<String, dynamic>;
  }

  /// Delete a habit.
  Future<void> deleteHabit(String id) async {
    await apiService.delete('/habits/$id');
  }
}
