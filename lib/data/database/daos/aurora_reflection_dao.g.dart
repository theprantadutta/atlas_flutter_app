// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aurora_reflection_dao.dart';

// ignore_for_file: type=lint
mixin _$AuroraReflectionDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $AuroraReflectionsTable get auroraReflections =>
      attachedDatabase.auroraReflections;
  AuroraReflectionDaoManager get managers => AuroraReflectionDaoManager(this);
}

class AuroraReflectionDaoManager {
  final _$AuroraReflectionDaoMixin _db;
  AuroraReflectionDaoManager(this._db);
  $$AuroraReflectionsTableTableManager get auroraReflections =>
      $$AuroraReflectionsTableTableManager(
        _db.attachedDatabase,
        _db.auroraReflections,
      );
}
