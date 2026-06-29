import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/goals_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AtlasDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones) ───

  Stream<List<Goal>> watchGoals(String userId) {
    return (select(goals)
          ..where((g) => g.userId.equals(userId) & g.isDeleted.equals(false))
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  Future<List<Goal>> getAllGoals(String userId) {
    return (select(goals)
          ..where((g) => g.userId.equals(userId) & g.isDeleted.equals(false)))
        .get();
  }

  Future<Goal?> getGoalById(String id) {
    return (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  Future<int> countForUser(String userId) async {
    final rows =
        await (select(goals)..where((g) => g.userId.equals(userId))).get();
    return rows.length;
  }

  // ─── Writes ───

  Future<int> insertGoal(GoalsCompanion entry) => into(goals).insert(entry);

  Future<int> upsertGoal(GoalsCompanion entry) =>
      into(goals).insertOnConflictUpdate(entry);

  Future<void> updateFields(String id, GoalsCompanion patch) async {
    await (update(goals)..where((g) => g.id.equals(id))).write(patch);
  }

  Future<void> softDeleteGoal(String id, DateTime now) async {
    await (update(goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> hardDeleteGoal(String id) {
    return (delete(goals)..where((g) => g.id.equals(id))).go();
  }

  Future<int> deleteGoal(String id) => hardDeleteGoal(id);

  // ─── Sync helpers ───

  Future<List<Goal>> getDirtyGoals(String userId) {
    return (select(goals)
          ..where((g) => g.userId.equals(userId) & g.isDirty.equals(true)))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(goals)..where((g) => g.id.isIn(ids))).write(
      GoalsCompanion(isDirty: const Value(false), lastSyncedAt: Value(syncedAt)),
    );
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(goals)
          ..where((g) => g.isDeleted.equals(true) & g.isDirty.equals(false)))
        .go();
  }
}
