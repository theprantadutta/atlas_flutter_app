import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/aurora_reflection_dao.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';

/// Talks to the Aurora backend endpoints. Reflections are cached in Drift so the
/// latest one is readable offline (server-generated, pull-only — no sync
/// metadata). Chat is online-only and not persisted locally.
class AuroraRepository {
  AuroraRepository(this._api, this._dao);

  final ApiService _api;
  final AuroraReflectionDao _dao;

  /// Reactive stream of the user's most recent cached reflection (or null).
  Stream<AuroraReflection?> watchLatestReflection(String userId) =>
      _dao.watchLatest(userId);

  /// Generate a fresh weekly reflection on the backend and cache it locally.
  /// Throws [AppException] with `statusCode == 402` when the free weekly limit
  /// is hit (paywall).
  ///
  /// [preferences] is the user's Aurora voice settings, which live on the
  /// device and travel with the request rather than being stored server-side.
  Future<AuroraReflectionData> generateReflection(
    String userId, {
    Map<String, dynamic>? preferences,
  }) async {
    final res = await _api.post(
      '/aurora/reflect',
      data: {'preferences': ?preferences},
    );
    final data =
        AuroraReflectionData.fromJson(res.data as Map<String, dynamic>);

    await _dao.upsert(
      AuroraReflectionsCompanion(
        id: Value(data.id),
        userId: Value(userId),
        content: Value(data.content),
        periodStart: Value(data.periodStart),
        periodEnd: Value(data.periodEnd),
        modelTier: Value(data.modelTier),
        createdAt: Value(data.createdAt),
      ),
    );
    return data;
  }

  /// Send a chat message with recent history. Throws [AppException] with
  /// `statusCode == 402` when the free weekly chat limit is hit (paywall).
  Future<AuroraChatResult> chat(
    String message,
    List<Map<String, String>> history, {
    Map<String, dynamic>? preferences,
  }) async {
    final res = await _api.post(
      '/aurora/chat',
      data: {
        'message': message,
        'history': history,
        'preferences': ?preferences,
      },
    );
    return AuroraChatResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Parse a natural-language note into habit/task/goal specs (premium). Throws
  /// [AppException] with `statusCode == 402` when the user isn't premium
  /// (paywall). The caller creates the returned specs in local Drift.
  Future<AuroraQuickAddResult> quickAdd(String text) async {
    final res = await _api.post('/aurora/quick-add', data: {'text': text});
    return AuroraQuickAddResult.fromJson(res.data as Map<String, dynamic>);
  }
}
