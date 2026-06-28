import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()();
  TextColumn get frequency => text()();
  IntColumn get difficulty => integer().withDefault(const Constant(1))();
  BoolColumn get isCompletedToday =>
      boolean().withDefault(const Constant(false))();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  RealColumn get completionRate =>
      real().withDefault(const Constant(0.0))();
  IntColumn get totalCompletions =>
      integer().withDefault(const Constant(0))();
  TextColumn get reminderTime => text().nullable()();
  DateTimeColumn get lastCompletedDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // ─── Sync metadata (offline-first) ───
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
