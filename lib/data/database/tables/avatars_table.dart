import 'package:drift/drift.dart';

class Avatars extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get currentXp => integer().withDefault(const Constant(0))();
  IntColumn get strength => integer().withDefault(const Constant(0))();
  IntColumn get wisdom => integer().withDefault(const Constant(0))();
  IntColumn get intelligence => integer().withDefault(const Constant(0))();
  TextColumn get appearanceData => text().nullable()();
  TextColumn get unlockedItems => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
