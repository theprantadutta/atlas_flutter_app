import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/world_tiles_table.dart';

part 'world_dao.g.dart';

/// The world is [kWorldSize] places on a [kWorldCols]-wide grid, filled row
/// by row.
const kWorldCols = 5;
const kWorldSize = 30;

/// Whether ([x], [y]) is one of the app's places. Anything else came from
/// elsewhere (the server once seeded its own 8x8 map at sign-up) and is not
/// part of the world.
bool isWorldPlace(int x, int y) =>
    x >= 0 && x < kWorldCols && y >= 0 && y * kWorldCols + x < kWorldSize;

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
              w.isDeleted.equals(false))
          // Duplicate positions must not throw and abort a sync.
          ..orderBy([(w) => OrderingTerm.desc(w.updatedAt)])
          ..limit(1))
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

  /// Takes back "World Builder" (unlock 30 places) when it was earned on a
  /// world the repair just shrank: the server's old 64-place map let it
  /// unlock without 30 real places. The evaluator then recomputes its
  /// progress from the places that remain.
  Future<void> relockWorldBuilder(String userId, DateTime now) async {
    final db = attachedDatabase;
    await (db.update(db.achievements)
          ..where((a) =>
              a.userId.equals(userId) &
              a.title.equals('World Builder') &
              a.isUnlocked.equals(true)))
        .write(AchievementsCompanion(
      isUnlocked: const Value(false),
      progress: const Value(0.0),
      unlockedAt: const Value(null),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
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

  /// Clears the dirty flag for pushed rows, keyed by id with the `updatedAt`
  /// that was sent. A row whose `updatedAt` changed while the push was in
  /// flight (edited mid-sync) is left dirty so that edit goes out next sync.
  Future<void> markSynced(
      Map<String, DateTime> pushedUpdatedAt, DateTime syncedAt) async {
    if (pushedUpdatedAt.isEmpty) return;
    await transaction(() async {
      for (final e in pushedUpdatedAt.entries) {
        await (update(worldTiles)
              ..where((w) => w.id.equals(e.key) & w.updatedAt.equals(e.value)))
            .write(
          WorldTilesCompanion(
            isDirty: const Value(false),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      }
    });
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(worldTiles)
          ..where((w) => w.isDeleted.equals(true) & w.isDirty.equals(false)))
        .go();
  }
}
