// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aurora_memory_dao.dart';

// ignore_for_file: type=lint
mixin _$AuroraMemoryDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $AuroraMemoriesTable get auroraMemories => attachedDatabase.auroraMemories;
  AuroraMemoryDaoManager get managers => AuroraMemoryDaoManager(this);
}

class AuroraMemoryDaoManager {
  final _$AuroraMemoryDaoMixin _db;
  AuroraMemoryDaoManager(this._db);
  $$AuroraMemoriesTableTableManager get auroraMemories =>
      $$AuroraMemoriesTableTableManager(
        _db.attachedDatabase,
        _db.auroraMemories,
      );
}
