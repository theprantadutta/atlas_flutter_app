import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/tables/aurora_conversations_table.dart';

/// One message in an [AuroraConversations] row.
///
/// LOCAL ONLY, deliberately NOT synced (see [AuroraConversations]).
class AuroraMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()
      .references(AuroraConversations, #id, onDelete: KeyAction.cascade)();

  /// `user` | `aurora`
  TextColumn get role => text()();
  TextColumn get content => text()();

  /// JSON list of suggestion cards shown under an Aurora reply.
  TextColumn get suggestionsJson => text().nullable()();

  /// JSON list of follow-up chips.
  TextColumn get followUpsJson => text().nullable()();

  /// JSON list of the entities Aurora created from this turn.
  TextColumn get createdJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
