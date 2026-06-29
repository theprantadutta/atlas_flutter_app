import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/world_tiles_table.dart';

part 'world_dao.g.dart';

@DriftAccessor(tables: [WorldTiles])
class WorldDao extends DatabaseAccessor<AtlasDatabase>
    with _$WorldDaoMixin {
  WorldDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones, ordered for the grid) ───

  Stream<List<WorldTile>> watchTiles(String userId) {
    return (select(worldTiles)
          ..where((w) => w.userId.equals(userId) & w.isDeleted.equals(false))
          ..orderBy([
            (w) => OrderingTerm.asc(w.positionY),
            (w) => OrderingTerm.asc(w.positionX),
          ]))
        .watch();
  }

  Future<List<WorldTile>> getAllTiles(String userId) {
    return (select(worldTiles)
          ..where((w) => w.userId.equals(userId) & w.isDeleted.equals(false))
          ..orderBy([
            (w) => OrderingTerm.asc(w.positionY),
            (w) => OrderingTerm.asc(w.positionX),
          ]))
        .get();
  }

  Future<WorldTile?> getTileById(String id) {
    return (select(worldTiles)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }

  /// Grid position is the natural key for a tile — tiles are seeded
  /// independently on each device, so sync matches on position, not id.
  Future<WorldTile?> getTileByPosition(String userId, int x, int y) {
    return (select(worldTiles)
          ..where((w) =>
              w.userId.equals(userId) &
              w.positionX.equals(x) &
              w.positionY.equals(y) &
              w.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<int> countForUser(String userId) async {
    final rows =
        await (select(worldTiles)..where((w) => w.userId.equals(userId))).get();
    return rows.length;
  }

  // ─── Writes ───

  Future<int> insertTile(WorldTilesCompanion entry) =>
      into(worldTiles).insert(entry);

  Future<int> upsertTile(WorldTilesCompanion entry) =>
      into(worldTiles).insertOnConflictUpdate(entry);

  Future<void> updateFields(String id, WorldTilesCompanion patch) async {
    await (update(worldTiles)..where((w) => w.id.equals(id))).write(patch);
  }

  Future<void> softDeleteTile(String id, DateTime now) async {
    await (update(worldTiles)..where((w) => w.id.equals(id))).write(
      WorldTilesCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> hardDeleteTile(String id) {
    return (delete(worldTiles)..where((w) => w.id.equals(id))).go();
  }

  // ─── Sync helpers ───

  Future<List<WorldTile>> getDirtyTiles(String userId) {
    return (select(worldTiles)
          ..where((w) => w.userId.equals(userId) & w.isDirty.equals(true)))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(worldTiles)..where((w) => w.id.isIn(ids))).write(
      WorldTilesCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(worldTiles)
          ..where((w) => w.isDeleted.equals(true) & w.isDirty.equals(false)))
        .go();
  }
}
