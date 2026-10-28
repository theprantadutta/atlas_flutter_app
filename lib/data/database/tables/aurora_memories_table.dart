import 'package:drift/drift.dart';

/// Things Aurora remembers about the user (premium), sent as
/// `context.memories`.
///
/// LOCAL ONLY, deliberately NOT synced: there is no backend entity, so no
/// sync metadata and no entity parity to keep. Deleting is a hard delete.
class AuroraMemories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// The remembered fact, max 200 chars. (`text` in SQL; renamed in Dart
  /// because a column getter can't shadow the `text()` builder.)
  TextColumn get content => text().named('text')();

  /// `aurora` (proposed in chat, saved by a tap) | `you` (typed by the user).
  TextColumn get source => text().withDefault(const Constant('you'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
