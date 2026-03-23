import 'package:drift/drift.dart';

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get parentGoalId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
