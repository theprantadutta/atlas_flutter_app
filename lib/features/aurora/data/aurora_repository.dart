import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
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

  /// Chat, streamed: [AuroraStreamDelta]s as Aurora writes, then one
  /// [AuroraStreamDone] with the same result [chat] returns. Throws
  /// [AppException] (with the status, e.g. 402 or 404 on older servers) if the
  /// request fails before streaming starts, or on an error event mid-stream.
  Stream<AuroraStreamEvent> chatStream(
    String message,
    List<Map<String, String>> history, {
    Map<String, dynamic>? preferences,
  }) async* {
    final res = await _api.postStream(
      '/aurora/chat/stream',
      data: {
        'message': message,
        'history': history,
        'preferences': ?preferences,
      },
    );
    final body = res.data;
    if (body == null) throw const AppException('Aurora is resting right now.', statusCode: 503);

    String? event;
    final data = StringBuffer();
    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.isEmpty) {
        if (event != null && data.isNotEmpty) {
          final json = jsonDecode(data.toString());
          switch (event) {
            case 'delta':
              final text = (json as Map)['text'] as String? ?? '';
              if (text.isNotEmpty) yield AuroraStreamDelta(text);
            case 'done':
              yield AuroraStreamDone(AuroraChatResult.fromJson(json as Map<String, dynamic>));
              return;
            case 'error':
              final m = json as Map;
              throw AppException(
                (m['message'] as String?) ?? 'Aurora is resting right now.',
                statusCode: (m['status'] as num?)?.toInt() ?? 503,
              );
          }
        }
        event = null;
        data.clear();
      } else if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        data.write(line.substring(5).trimLeft());
      }
    }
    // The connection closed without a final event.
    throw const AppException('Aurora is resting right now.', statusCode: 503);
  }

  /// Parse a natural-language note into habit/task/goal specs (premium). Throws
  /// [AppException] with `statusCode == 402` when the user isn't premium
  /// (paywall). The caller creates the returned specs in local Drift.
  Future<AuroraQuickAddResult> quickAdd(String text) async {
    final res = await _api.post('/aurora/quick-add', data: {'text': text});
    return AuroraQuickAddResult.fromJson(res.data as Map<String, dynamic>);
  }
}

/// One event from a streamed chat reply.
sealed class AuroraStreamEvent {
  const AuroraStreamEvent();
}

/// More of the reply, as it's written.
class AuroraStreamDelta extends AuroraStreamEvent {
  const AuroraStreamDelta(this.text);
  final String text;
}

/// The finished turn: the cleaned reply, created items, suggestions.
class AuroraStreamDone extends AuroraStreamEvent {
  const AuroraStreamDone(this.result);
  final AuroraChatResult result;
}
