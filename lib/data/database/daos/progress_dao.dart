import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/progress_entries_table.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [ProgressEntries])
class ProgressDao extends DatabaseAccessor<AtlasDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones) ───

  /// Reactive stream of the user's entries, most recent first.
  Stream<List<ProgressEntry>> watchEntries(String userId) {
    return (select(progressEntries)
          ..where((p) => p.userId.equals(userId) & p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.desc(p.date)]))
        .watch();
  }

  Future<List<ProgressEntry>> getProgressByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return (select(progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isDeleted.equals(false) &
              p.date.isBiggerOrEqualValue(start) &
              p.date.isSmallerOrEqualValue(end))
          ..orderBy([(p) => OrderingTerm.desc(p.date)]))
        .get();
  }

  Future<ProgressEntry?> getEntryById(String id) {
    return (select(progressEntries)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// The calendar day is the natural key — one entry per day per user.
  /// Entries are seeded independently per device, so sync matches on day.
  Future<ProgressEntry?> getEntryForDay(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isDeleted.equals(false) &
              p.date.isBiggerOrEqualValue(startOfDay) &
              p.date.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  Future<int> countForUser(String userId) async {
    final rows =
        await (select(progressEntries)..where((p) => p.userId.equals(userId)))
            .get();
    return rows.length;
  }

  // ─── Writes ───

  Future<int> insertProgress(ProgressEntriesCompanion entry) =>
      into(progressEntries).insert(entry);

  Future<int> upsertProgress(ProgressEntriesCompanion entry) =>
      into(progressEntries).insertOnConflictUpdate(entry);

  Future<void> updateFields(String id, ProgressEntriesCompanion patch) async {
    await (update(progressEntries)..where((p) => p.id.equals(id))).write(patch);
  }

  Future<void> softDeleteEntry(String id, DateTime now) async {
    await (update(progressEntries)..where((p) => p.id.equals(id))).write(
      ProgressEntriesCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> hardDeleteEntry(String id) {
    return (delete(progressEntries)..where((p) => p.id.equals(id))).go();
  }

  // ─── Sync helpers ───

  Future<List<ProgressEntry>> getDirtyEntries(String userId) {
    return (select(progressEntries)
          ..where((p) => p.userId.equals(userId) & p.isDirty.equals(true)))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(progressEntries)..where((p) => p.id.isIn(ids))).write(
      ProgressEntriesCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(progressEntries)
          ..where((p) => p.isDeleted.equals(true) & p.isDirty.equals(false)))
        .go();
  }
}
