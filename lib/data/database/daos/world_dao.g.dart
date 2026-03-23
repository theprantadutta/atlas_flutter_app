// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_dao.dart';

// ignore_for_file: type=lint
mixin _$WorldDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $WorldTilesTable get worldTiles => attachedDatabase.worldTiles;
  WorldDaoManager get managers => WorldDaoManager(this);
}

class WorldDaoManager {
  final _$WorldDaoMixin _db;
  WorldDaoManager(this._db);
  $$WorldTilesTableTableManager get worldTiles =>
      $$WorldTilesTableTableManager(_db.attachedDatabase, _db.worldTiles);
}
