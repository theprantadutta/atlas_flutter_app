import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  TextColumn get photoUrl => text().nullable()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  BoolColumn get isEmailVerified =>
      boolean().withDefault(const Constant(false))();
  TextColumn get authProvider =>
      text().withDefault(const Constant('email'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastActiveDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
