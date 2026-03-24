import 'package:atlas_flutter_app/data/services/api_service.dart';

/// Sync repository handles push/pull operations with the server.
///
/// This is an infrastructure-level repository used by [OfflineManager].
/// It does NOT extend [BaseRepository] to avoid circular dependencies
/// (OfflineManager -> SyncRepository -> BaseRepository -> OfflineManager).
class SyncRepository {
  final ApiService apiService;

  SyncRepository(this.apiService);

  /// Push local changes to the server.
  Future<Map<String, dynamic>> pushSync(List<Map<String, dynamic>> operations) async {
    final response = await apiService.post(
      '/sync/push',
      data: {'operations': operations},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Pull remote changes from the server.
  Future<Map<String, dynamic>> pullSync({
    String? lastSyncTimestamp,
  }) async {
    final response = await apiService.post(
      '/sync/pull',
      data: {'last_sync_timestamp': lastSyncTimestamp},
    );
    return response.data as Map<String, dynamic>;
  }
}
