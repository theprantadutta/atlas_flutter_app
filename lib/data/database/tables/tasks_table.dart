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

  @override
  Set<Column> get primaryKey => {id};
}
