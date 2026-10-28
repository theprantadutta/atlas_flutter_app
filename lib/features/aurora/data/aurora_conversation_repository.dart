import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/aurora_conversation_dao.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';

/// A deleted conversation, held so the UI can offer Undo.
class DeletedConversation {
  const DeletedConversation(this.conversation, this.messages);
  final AuroraConversation conversation;
  final List<AuroraMessage> messages;
}

/// Local-only Aurora chat history (deliberately never synced; see the
/// table). Writes go straight to Drift.
class AuroraConversationRepository {
  AuroraConversationRepository(this._dao, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AuroraConversationDao _dao;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  /// A conversation updated within this window reopens with the chat screen.
  static const reopenWindow = Duration(hours: 12);

  /// Title length cap (the first user message).
  static const maxTitle = 60;

  /// Newest (most recently updated) first.
  Stream<List<AuroraConversation>> watchConversations(String userId) =>
      _dao.watchConversations(userId);

  Future<List<AuroraConversation>> listConversations(String userId) =>
      _dao.getConversations(userId);

  Future<AuroraConversation?> getConversation(String id) =>
      _dao.getConversation(id);

  /// Messages, oldest first.
  Future<List<AuroraMessage>> messagesOf(String conversationId) =>
      _dao.getMessages(conversationId);

  /// The most recent conversation if it was updated within [reopenWindow] of
  /// now, otherwise null (start fresh).
  Future<AuroraConversation?> openRecent(String userId) async {
    final all = await _dao.getConversations(userId);
    if (all.isEmpty) return null;
    final latest = all.first;
    return _clock().difference(latest.updatedAt) <= reopenWindow
        ? latest
        : null;
  }

  /// Starts a conversation titled after [firstMessage].
  Future<AuroraConversation> create(String userId,
      {required String firstMessage}) async {
    final now = _clock();
    final row = AuroraConversation(
      id: _uuid.v4(),
      userId: userId,
      title: titleFrom(firstMessage),
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertConversation(row.toCompanion(true));
    return row;
  }

  /// Appends a message and bumps the conversation's `updatedAt`.
  Future<AuroraMessage> append(
    String conversationId, {
    required String role,
    required String content,
    List<AuroraSuggestion> suggestions = const [],
    List<String> followUps = const [],
    List<AuroraCreatedEntity> created = const [],
  }) async {
    final now = _clock();
    final row = AuroraMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: role == 'user' ? 'user' : 'aurora',
      content: content,
      suggestionsJson: suggestions.isEmpty
          ? null
          : jsonEncode([for (final s in suggestions) s.toJson()]),
      followUpsJson: followUps.isEmpty ? null : jsonEncode(followUps),
      createdJson: created.isEmpty
          ? null
          : jsonEncode([for (final c in created) c.toJson()]),
      createdAt: now,
    );
    await _dao.attachedDatabase.transaction(() async {
      await _dao.insertMessage(row.toCompanion(true));
      await _dao.touch(conversationId, now);
    });
    return row;
  }

  /// Deletes a conversation and its messages, returning them so
  /// [restore] can undo it. Null when it didn't exist.
  Future<DeletedConversation?> delete(String conversationId) async {
    final conversation = await _dao.getConversation(conversationId);
    if (conversation == null) return null;
    final messages = await _dao.getMessages(conversationId);
    await _dao.deleteConversation(conversationId);
    return DeletedConversation(conversation, messages);
  }

  /// Undo for [delete]: puts the rows back exactly as they were.
  Future<void> restore(DeletedConversation deleted) async {
    await _dao.attachedDatabase.transaction(() async {
      await _dao.insertConversation(deleted.conversation.toCompanion(true));
      for (final m in deleted.messages) {
        await _dao.insertMessage(m.toCompanion(true));
      }
    });
  }

  static String titleFrom(String message) {
    final t = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return 'New conversation';
    return t.length <= maxTitle ? t : t.substring(0, maxTitle).trimRight();
  }

  // ─── Decoding persisted turns ──────────────────────────────────────

  static List<AuroraSuggestion> suggestionsOf(AuroraMessage m) => [
        for (final e in _list(m.suggestionsJson)) ?AuroraSuggestion.fromJson(e),
      ];

  static List<String> followUpsOf(AuroraMessage m) => [
        for (final e in _list(m.followUpsJson))
          if (e is String && e.isNotEmpty) e,
      ];

  static List<AuroraCreatedEntity> createdOf(AuroraMessage m) => [
        for (final e in _list(m.createdJson))
          if (e is Map)
            AuroraCreatedEntity.fromJson(e.cast<String, dynamic>()),
      ];

  static List<Object?> _list(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final v = jsonDecode(raw);
      return v is List ? v : const [];
    } catch (_) {
      return const [];
    }
  }
}
