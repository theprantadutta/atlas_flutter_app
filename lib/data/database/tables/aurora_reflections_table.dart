import 'package:drift/drift.dart';

/// Local cache of Aurora weekly reflections so the latest one is readable
/// offline. Server-generated (pull-only) — no sync metadata needed.
class AuroraReflections extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get content => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  TextColumn get modelTier => text().withDefault(const Constant('free'))();

  /// `week` | `month` (schema 12). Month letters are premium.
  TextColumn get period => text().withDefault(const Constant('week'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
