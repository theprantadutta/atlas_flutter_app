import 'package:drift/drift.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  IntColumn get xpReward => integer().withDefault(const Constant(25))();
  IntColumn get difficulty => integer().withDefault(const Constant(1))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastCompletedDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // ─── Sync metadata (offline-first) ───
  /// Needs to be pushed to the server.
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  /// Soft-delete tombstone (kept so the deletion can sync, then purged).
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Last time this row was confirmed in sync with the server.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
