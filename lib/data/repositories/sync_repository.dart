import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class SyncRepository extends BaseRepository {
  SyncRepository(super.apiService);

  /// Push local changes to the server.
  Future<Map<String, dynamic>> pushSync(Map<String, dynamic> data) async {
    final response = await apiService.post('/sync/push', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Pull remote changes from the server.
  Future<Map<String, dynamic>> pullSync({
    String? lastSyncTimestamp,
  }) async {
    final queryParams = <String, dynamic>{};
    if (lastSyncTimestamp != null) {
      queryParams['last_sync'] = lastSyncTimestamp;
    }

    final response = await apiService.get(
      '/sync/pull',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return response.data as Map<String, dynamic>;
  }
}
