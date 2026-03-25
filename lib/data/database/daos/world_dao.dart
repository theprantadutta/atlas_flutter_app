import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/world_tiles_table.dart';

part 'world_dao.g.dart';

@DriftAccessor(tables: [WorldTiles])
class WorldDao extends DatabaseAccessor<AtlasDatabase>
    with _$WorldDaoMixin {
  WorldDao(super.db);

  Future<List<WorldTile>> getAllTiles(String userId) {
    return (select(worldTiles)..where((w) => w.userId.equals(userId))).get();
  }

  Future<WorldTile?> getTileById(String id) {
    return (select(worldTiles)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertTile(WorldTilesCompanion entry) {
    return into(worldTiles).insert(entry);
  }

  Future<int> upsertTile(WorldTilesCompanion entry) {
    return into(worldTiles).insertOnConflictUpdate(entry);
  }

  Future<bool> updateTile(WorldTilesCompanion entry) {
    return update(worldTiles).replace(entry);
  }
}
