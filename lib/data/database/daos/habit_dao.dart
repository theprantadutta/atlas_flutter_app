import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/habits_table.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<AtlasDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones) ───

  Stream<List<Habit>> watchHabits(String userId) {
    return (select(habits)
          ..where((h) => h.userId.equals(userId) & h.isDeleted.equals(false))
          ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
        .watch();
  }

  Future<List<Habit>> getAllHabits(String userId) {
    return (select(habits)
          ..where((h) => h.userId.equals(userId) & h.isDeleted.equals(false)))
        .get();
  }

  Future<Habit?> getHabitById(String id) {
    return (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();
  }

  Future<int> countForUser(String userId) async {
    final rows =
        await (select(habits)..where((h) => h.userId.equals(userId))).get();
    return rows.length;
  }

  // ─── Writes ───

  Future<int> insertHabit(HabitsCompanion entry) => into(habits).insert(entry);

  Future<int> upsertHabit(HabitsCompanion entry) =>
      into(habits).insertOnConflictUpdate(entry);

  Future<void> updateFields(String id, HabitsCompanion patch) async {
    await (update(habits)..where((h) => h.id.equals(id))).write(patch);
  }

  Future<void> softDeleteHabit(String id, DateTime now) async {
    await (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> hardDeleteHabit(String id) {
    return (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  Future<int> deleteHabit(String id) => hardDeleteHabit(id);

  Future<int> resetDailyHabits(String userId) {
    return (update(habits)..where((h) => h.userId.equals(userId)))
        .write(const HabitsCompanion(isCompletedToday: Value(false)));
  }

  // ─── Sync helpers ───

  Future<List<Habit>> getDirtyHabits(String userId) {
    return (select(habits)
          ..where((h) => h.userId.equals(userId) & h.isDirty.equals(true)))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(habits)..where((h) => h.id.isIn(ids))).write(
      HabitsCompanion(isDirty: const Value(false), lastSyncedAt: Value(syncedAt)),
    );
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(habits)
          ..where((h) => h.isDeleted.equals(true) & h.isDirty.equals(false)))
        .go();
  }
}
