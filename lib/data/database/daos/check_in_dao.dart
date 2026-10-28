import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/check_ins_table.dart';

part 'check_in_dao.g.dart';

@DriftAccessor(tables: [CheckIns])
class CheckInDao extends DatabaseAccessor<AtlasDatabase>
    with _$CheckInDaoMixin {
  CheckInDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones) ───

  /// Live check-ins whose day is in [start, end), oldest first.
  Stream<List<CheckIn>> watchRange(
          String userId, DateTime start, DateTime end) =>
      _range(userId, start, end).watch();

  Future<List<CheckIn>> getRange(
          String userId, DateTime start, DateTime end) =>
      _range(userId, start, end).get();

  SimpleSelectStatement<$CheckInsTable, CheckIn> _range(
      String userId, DateTime start, DateTime end) {
    return select(checkIns)
      ..where((c) =>
          c.userId.equals(userId) &
          c.isDeleted.equals(false) &
          c.date.isBiggerOrEqualValue(start) &
          c.date.isSmallerThanValue(end))
      ..orderBy([
        (c) => OrderingTerm.asc(c.date),
        (c) => OrderingTerm.asc(c.createdAt),
      ]);
  }

  Future<CheckIn?> getById(String id) =>
      (select(checkIns)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// The row for (user, day, moment), INCLUDING a tombstone so saving again
  /// revives it instead of making a second row. Tolerates duplicates (two
  /// offline devices): a live row beats a tombstone, then the most recently
  /// updated wins.
  Future<CheckIn?> findForMoment(
      String userId, DateTime start, DateTime end, String moment) {
    return (select(checkIns)
          ..where((c) =>
              c.userId.equals(userId) &
              c.moment.equals(moment) &
              c.date.isBiggerOrEqualValue(start) &
              c.date.isSmallerThanValue(end))
          ..orderBy([
            (c) => OrderingTerm.asc(c.isDeleted),
            (c) => OrderingTerm.desc(c.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  // ─── Writes ───

  Future<int> upsert(CheckInsCompanion entry) =>
      into(checkIns).insertOnConflictUpdate(entry);

  Future<void> updateFields(String id, CheckInsCompanion patch) async {
    await (update(checkIns)..where((c) => c.id.equals(id))).write(patch);
  }

  Future<void> softDelete(String id, DateTime now) async {
    await (update(checkIns)..where((c) => c.id.equals(id))).write(
      CheckInsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> hardDelete(String id) =>
      (delete(checkIns)..where((c) => c.id.equals(id))).go();

  // ─── Sync helpers ───

  Future<List<CheckIn>> getDirty(String userId) {
    return (select(checkIns)
          ..where((c) => c.userId.equals(userId) & c.isDirty.equals(true)))
        .get();
  }

  /// Clears the dirty flag for pushed rows, keyed by id with the `updatedAt`
  /// that was sent. A row edited while the push was in flight stays dirty.
  Future<void> markSynced(
      Map<String, DateTime> pushedUpdatedAt, DateTime syncedAt) async {
    if (pushedUpdatedAt.isEmpty) return;
    await transaction(() async {
      for (final e in pushedUpdatedAt.entries) {
        await (update(checkIns)
              ..where(
                  (c) => c.id.equals(e.key) & c.updatedAt.equals(e.value)))
            .write(
          CheckInsCompanion(
            isDirty: const Value(false),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      }
    });
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(checkIns)
          ..where((c) => c.isDeleted.equals(true) & c.isDirty.equals(false)))
        .go();
  }
}
