// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_dao.dart';

// ignore_for_file: type=lint
mixin _$CheckInDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $CheckInsTable get checkIns => attachedDatabase.checkIns;
  CheckInDaoManager get managers => CheckInDaoManager(this);
}

class CheckInDaoManager {
  final _$CheckInDaoMixin _db;
  CheckInDaoManager(this._db);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db.attachedDatabase, _db.checkIns);
}
