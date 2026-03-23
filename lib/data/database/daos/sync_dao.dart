import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/sync_operations_table.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncOperations])
class SyncDao extends DatabaseAccessor<AtlasDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Future<List<SyncOperation>> getPendingOperations() {
    return (select(syncOperations)
          ..orderBy([(s) => OrderingTerm.asc(s.timestamp)]))
        .get();
  }

  Future<int> insertOperation(SyncOperationsCompanion entry) {
    return into(syncOperations).insert(entry);
  }

  Future<int> deleteOperation(String id) {
    return (delete(syncOperations)..where((s) => s.id.equals(id))).go();
  }

  Future<int> clearAll() {
    return delete(syncOperations).go();
  }

  // ─── Phase 4 Additions ──────────────────────────────────────

  /// Inserts [entry] after deduplicating: removes any existing operation
  /// with the same entityType + entityId first.
  Future<void> queueOperation(SyncOperationsCompanion entry) async {
    await transaction(() async {
      if (entry.entityType.present && entry.entityId.present) {
        await (delete(syncOperations)
              ..where((s) =>
                  s.entityType.equals(entry.entityType.value) &
                  s.entityId.equals(entry.entityId.value)))
            .go();
      }
      await into(syncOperations).insert(entry);
    });
  }

  /// Returns pending operations filtered by [entityType].
  Future<List<SyncOperation>> getPendingByEntityType(String entityType) {
    return (select(syncOperations)
          ..where((s) => s.entityType.equals(entityType))
          ..orderBy([(s) => OrderingTerm.asc(s.timestamp)]))
        .get();
  }

  /// Returns the total number of pending sync operations.
  Future<int> getPendingCount() async {
    final count = syncOperations.id.count();
    final query = selectOnly(syncOperations)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Removes all operations targeting [entityId].
  Future<int> removeOperationsForEntity(String entityId) {
    return (delete(syncOperations)
          ..where((s) => s.entityId.equals(entityId)))
        .go();
  }

  /// Increments retryCount and refreshes timestamp for the given [id].
  Future<void> incrementRetry(String id) async {
    final op = await (select(syncOperations)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (op == null) return;

    await (update(syncOperations)..where((s) => s.id.equals(id))).write(
      SyncOperationsCompanion(
        retryCount: Value(op.retryCount + 1),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  /// Removes operations that have exceeded [maxRetries].
  Future<int> removeExpiredOperations(int maxRetries) {
    return (delete(syncOperations)
          ..where((s) => s.retryCount.isBiggerOrEqualValue(maxRetries)))
        .go();
  }

  /// Watches the total number of pending sync operations reactively.
  Stream<int> watchPendingCount() {
    final count = syncOperations.id.count();
    final query = selectOnly(syncOperations)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }
}
