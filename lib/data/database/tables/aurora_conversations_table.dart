import 'package:drift/drift.dart';

/// A chat conversation with Aurora.
///
/// LOCAL ONLY, deliberately NOT synced: there is no backend entity, so no
/// sync metadata and no entity parity to keep. Rows are scoped by user id like
/// every table and are removed by the account wipe.
class AuroraConversations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// The first user message, capped at 60 chars.
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
