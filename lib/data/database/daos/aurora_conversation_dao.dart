import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/aurora_conversations_table.dart';
import 'package:atlas_flutter_app/data/database/tables/aurora_messages_table.dart';

part 'aurora_conversation_dao.g.dart';

/// Local-only Aurora chat history (deliberately never synced).
@DriftAccessor(tables: [AuroraConversations, AuroraMessages])
class AuroraConversationDao extends DatabaseAccessor<AtlasDatabase>
    with _$AuroraConversationDaoMixin {
  AuroraConversationDao(super.db);

  static const _rowid = CustomExpression<int>('rowid');

  /// Newest (most recently updated) first.
  Stream<List<AuroraConversation>> watchConversations(String userId) =>
      _conversations(userId).watch();

  Future<List<AuroraConversation>> getConversations(String userId) =>
      _conversations(userId).get();

  SimpleSelectStatement<$AuroraConversationsTable, AuroraConversation>
      _conversations(String userId) {
    return select(auroraConversations)
      ..where((c) => c.userId.equals(userId))
      ..orderBy([
        (c) => OrderingTerm.desc(c.updatedAt),
        (_) => OrderingTerm.desc(_rowid),
      ]);
  }

  Future<AuroraConversation?> getConversation(String id) =>
      (select(auroraConversations)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  /// Messages oldest first. Drift stores times to the second, so rows written
  /// in the same second keep their insertion order through the rowid.
  Future<List<AuroraMessage>> getMessages(String conversationId) {
    return (select(auroraMessages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([
            (m) => OrderingTerm.asc(m.createdAt),
            (_) => OrderingTerm.asc(_rowid),
          ]))
        .get();
  }

  Future<void> insertConversation(AuroraConversationsCompanion entry) =>
      into(auroraConversations).insertOnConflictUpdate(entry);

  Future<void> insertMessage(AuroraMessagesCompanion entry) =>
      into(auroraMessages).insertOnConflictUpdate(entry);

  Future<void> touch(String id, DateTime at) async {
    await (update(auroraConversations)..where((c) => c.id.equals(id)))
        .write(AuroraConversationsCompanion(updatedAt: Value(at)));
  }

  /// Deletes the conversation and its messages (explicitly, so it never
  /// depends on the foreign-key pragma being on).
  Future<void> deleteConversation(String id) async {
    await transaction(() async {
      await (delete(auroraMessages)
            ..where((m) => m.conversationId.equals(id)))
          .go();
      await (delete(auroraConversations)..where((c) => c.id.equals(id))).go();
    });
  }
}
