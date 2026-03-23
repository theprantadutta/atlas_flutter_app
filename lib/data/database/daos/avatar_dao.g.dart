// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_dao.dart';

// ignore_for_file: type=lint
mixin _$AvatarDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $AvatarsTable get avatars => attachedDatabase.avatars;
  AvatarDaoManager get managers => AvatarDaoManager(this);
}

class AvatarDaoManager {
  final _$AvatarDaoMixin _db;
  AvatarDaoManager(this._db);
  $$AvatarsTableTableManager get avatars =>
      $$AvatarsTableTableManager(_db.attachedDatabase, _db.avatars);
}
