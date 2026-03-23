import 'package:drift/drift.dart';

class Achievements extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get iconPath => text().nullable()();
  TextColumn get achievementType => text()();
  TextColumn get criteria => text().nullable()();
  BoolColumn get isUnlocked =>
      boolean().withDefault(const Constant(false))();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  DateTimeColumn get unlockedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
