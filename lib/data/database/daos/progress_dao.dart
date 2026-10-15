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

  /// The entry for a calendar day (one per day per user by convention).
  /// Duplicates can exist (e.g. legacy rows from before deterministic ids), so
  /// this returns the most recently updated one instead of throwing. Sync
  /// matches pulled entries by id, not by this lookup.
  Future<ProgressEntry?> getEntryForDay(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(progressEntries)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isDeleted.equals(false) &
              p.date.isBiggerOrEqualValue(startOfDay) &
              p.date.isSmallerThanValue(endOfDay))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
          ..limit(1))
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

  /// Clears the dirty flag for pushed rows, keyed by id with the `updatedAt`
  /// that was sent. A row whose `updatedAt` changed while the push was in
  /// flight (edited mid-sync) is left dirty so that edit goes out next sync.
  Future<void> markSynced(
      Map<String, DateTime> pushedUpdatedAt, DateTime syncedAt) async {
    if (pushedUpdatedAt.isEmpty) return;
    await transaction(() async {
      for (final e in pushedUpdatedAt.entries) {
        await (update(progressEntries)
              ..where((p) => p.id.equals(e.key) & p.updatedAt.equals(e.value)))
            .write(
          ProgressEntriesCompanion(
            isDirty: const Value(false),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      }
    });
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(progressEntries)
          ..where((p) => p.isDeleted.equals(true) & p.isDirty.equals(false)))
        .go();
  }
}
