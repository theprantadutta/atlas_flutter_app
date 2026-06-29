import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/achievements_table.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: [Achievements])
class AchievementDao extends DatabaseAccessor<AtlasDatabase>
    with _$AchievementDaoMixin {
  AchievementDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones) ───

  Stream<List<Achievement>> watchAchievements(String userId) {
    return (select(achievements)
          ..where((a) => a.userId.equals(userId) & a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .watch();
  }

  Future<List<Achievement>> getAllAchievements(String userId) {
    return (select(achievements)
          ..where((a) => a.userId.equals(userId) & a.isDeleted.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .get();
  }

  Future<List<Achievement>> getUnlockedAchievements(String userId) {
    return (select(achievements)
          ..where((a) =>
              a.userId.equals(userId) &
              a.isUnlocked.equals(true) &
              a.isDeleted.equals(false)))
        .get();
  }

  Future<Achievement?> getAchievementById(String id) {
    return (select(achievements)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// Title is the natural key — achievements are seeded independently per
  /// device, so sync matches on (userId, title), not id.
  Future<Achievement?> getAchievementByTitle(String userId, String title) {
    return (select(achievements)
          ..where((a) =>
              a.userId.equals(userId) &
              a.title.equals(title) &
              a.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<int> countForUser(String userId) async {
    final rows =
        await (select(achievements)..where((a) => a.userId.equals(userId)))
            .get();
    return rows.length;
  }

  // ─── Writes ───

  Future<int> insertAchievement(AchievementsCompanion entry) =>
      into(achievements).insert(entry);

  Future<int> upsertAchievement(AchievementsCompanion entry) =>
      into(achievements).insertOnConflictUpdate(entry);

  Future<void> updateFields(String id, AchievementsCompanion patch) async {
    await (update(achievements)..where((a) => a.id.equals(id))).write(patch);
  }

  Future<void> softDeleteAchievement(String id, DateTime now) async {
    await (update(achievements)..where((a) => a.id.equals(id))).write(
      AchievementsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> hardDeleteAchievement(String id) {
    return (delete(achievements)..where((a) => a.id.equals(id))).go();
  }

  // ─── Sync helpers ───

  Future<List<Achievement>> getDirtyAchievements(String userId) {
    return (select(achievements)
          ..where((a) => a.userId.equals(userId) & a.isDirty.equals(true)))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(achievements)..where((a) => a.id.isIn(ids))).write(
      AchievementsCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(achievements)
          ..where((a) => a.isDeleted.equals(true) & a.isDirty.equals(false)))
        .go();
  }
}
