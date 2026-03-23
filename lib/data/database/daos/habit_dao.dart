import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/habits_table.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<AtlasDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Future<List<Habit>> getAllHabits(String userId) {
    return (select(habits)..where((h) => h.userId.equals(userId))).get();
  }

  Future<Habit?> getHabitById(String id) {
    return (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertHabit(HabitsCompanion entry) {
    return into(habits).insert(entry);
  }

  Future<bool> updateHabit(HabitsCompanion entry) {
    return update(habits).replace(entry);
  }

  Future<int> deleteHabit(String id) {
    return (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  Future<int> resetDailyHabits(String userId) {
    return (update(habits)..where((h) => h.userId.equals(userId)))
        .write(const HabitsCompanion(isCompletedToday: Value(false)));
  }
}
