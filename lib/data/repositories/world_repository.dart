import 'package:atlas_flutter_app/data/models/world_tile.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class WorldRepository extends BaseRepository {
  WorldRepository(super.apiService);

  /// Get all world tiles.
  Future<List<WorldTile>> getWorldTiles() async {
    final response = await apiService.get('/world/tiles');
    return parseList(response.data, WorldTile.fromJson);
  }

  /// Unlock a specific world tile.
  Future<Map<String, dynamic>> unlockTile(String id) async {
    final response = await apiService.post('/world/tiles/$id/unlock');
    return response.data as Map<String, dynamic>;
  }

  /// Get world exploration statistics.
  Future<Map<String, dynamic>> getWorldStats() async {
    final response = await apiService.get('/world/stats');
    return response.data as Map<String, dynamic>;
  }
}
