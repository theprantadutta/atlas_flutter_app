import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class AvatarRepository extends BaseRepository {
  AvatarRepository(super.apiService);

  /// Get the current user's avatar.
  Future<Avatar> getAvatar() async {
    final response = await apiService.get('/avatar');
    return Avatar.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create an avatar for the current user.
  Future<Avatar> createAvatar(Map<String, dynamic> data) async {
    final response = await apiService.post('/avatar', data: data);
    return Avatar.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update the avatar's appearance.
  Future<Avatar> updateAppearance(Map<String, dynamic> data) async {
    final response = await apiService.put('/avatar/appearance', data: data);
    return Avatar.fromJson(response.data as Map<String, dynamic>);
  }

  /// Unlock an item for the avatar.
  Future<Map<String, dynamic>> unlockItem(Map<String, dynamic> data) async {
    final response = await apiService.post('/avatar/unlock-item', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Get avatar statistics.
  Future<Map<String, dynamic>> getAvatarStats() async {
    final response = await apiService.get('/avatar/stats');
    return response.data as Map<String, dynamic>;
  }
}
