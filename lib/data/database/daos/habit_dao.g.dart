// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $HabitsTable get habits => attachedDatabase.habits;
  HabitDaoManager get managers => HabitDaoManager(this);
}

class HabitDaoManager {
  final _$HabitDaoMixin _db;
  HabitDaoManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db.attachedDatabase, _db.habits);
}
