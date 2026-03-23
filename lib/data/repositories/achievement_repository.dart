import 'package:atlas_flutter_app/data/models/achievement.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class AchievementRepository extends BaseRepository {
  AchievementRepository(super.apiService);

  /// Get achievements with optional filters.
  Future<List<Achievement>> getAchievements({
    String? type,
    bool? unlocked,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (unlocked != null) queryParams['unlocked'] = unlocked.toString();
    if (search != null) queryParams['search'] = search;

    final response = await apiService.get(
      '/achievements',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return parseList(response.data, Achievement.fromJson);
  }

  /// Get recently unlocked achievements.
  Future<List<Achievement>> getRecentUnlocks() async {
    final response = await apiService.get('/achievements/recent');
    return parseList(response.data, Achievement.fromJson);
  }

  /// Check for new achievement unlocks.
  Future<Map<String, dynamic>> checkAchievements() async {
    final response = await apiService.post('/achievements/check');
    return response.data as Map<String, dynamic>;
  }
}
