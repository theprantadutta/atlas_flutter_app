// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aurora_conversation_dao.dart';

// ignore_for_file: type=lint
mixin _$AuroraConversationDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $AuroraConversationsTable get auroraConversations =>
      attachedDatabase.auroraConversations;
  $AuroraMessagesTable get auroraMessages => attachedDatabase.auroraMessages;
  AuroraConversationDaoManager get managers =>
      AuroraConversationDaoManager(this);
}

class AuroraConversationDaoManager {
  final _$AuroraConversationDaoMixin _db;
  AuroraConversationDaoManager(this._db);
  $$AuroraConversationsTableTableManager get auroraConversations =>
      $$AuroraConversationsTableTableManager(
        _db.attachedDatabase,
        _db.auroraConversations,
      );
  $$AuroraMessagesTableTableManager get auroraMessages =>
      $$AuroraMessagesTableTableManager(
        _db.attachedDatabase,
        _db.auroraMessages,
      );
}
