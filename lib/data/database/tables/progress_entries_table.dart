import 'package:drift/drift.dart';

class ProgressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get xpGained => integer().withDefault(const Constant(0))();
  IntColumn get tasksCompleted =>
      integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()();
  TextColumn get categoryBreakdown => text().nullable()();
  TextColumn get taskTypeBreakdown => text().nullable()();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  IntColumn get levelAtTime => integer().withDefault(const Constant(1))();
  TextColumn get additionalMetrics => text().nullable()();
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
