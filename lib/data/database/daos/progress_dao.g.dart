// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ProgressDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $ProgressEntriesTable get progressEntries => attachedDatabase.progressEntries;
  ProgressDaoManager get managers => ProgressDaoManager(this);
}

class ProgressDaoManager {
  final _$ProgressDaoMixin _db;
  ProgressDaoManager(this._db);
  $$ProgressEntriesTableTableManager get progressEntries =>
      $$ProgressEntriesTableTableManager(
        _db.attachedDatabase,
        _db.progressEntries,
      );
}
