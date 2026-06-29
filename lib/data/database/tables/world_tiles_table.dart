import 'package:drift/drift.dart';

class WorldTiles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get tileType => text()();
  BoolColumn get isUnlocked =>
      boolean().withDefault(const Constant(false))();
  IntColumn get unlockRequirement =>
      integer().withDefault(const Constant(0))();
  TextColumn get unlockCategory => text().nullable()();
  IntColumn get positionX => integer().withDefault(const Constant(0))();
  IntColumn get positionY => integer().withDefault(const Constant(0))();
  DateTimeColumn get unlockedAt => dateTime().nullable()();
  TextColumn get customProperties => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // ─── Offline-first sync metadata ───
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
