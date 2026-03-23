import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/offline_manager.dart';

abstract class BaseRepository {
  final ApiService apiService;
  final OfflineManager offlineManager;

  BaseRepository(this.apiService, this.offlineManager);

  /// Whether the device currently has connectivity.
  bool get isOnline => offlineManager.isOnline;

  /// Parses a list from an API response.
  ///
  /// Expects [data] to be a `List<dynamic>` where each element is a
  /// `Map<String, dynamic>`. Returns an empty list when [data] is not a List.
  List<T> parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is List) {
      return data
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
