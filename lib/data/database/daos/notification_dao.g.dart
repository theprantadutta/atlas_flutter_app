// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationDaoMixin on DatabaseAccessor<AtlasDatabase> {
  $NotificationsTable get notifications => attachedDatabase.notifications;
  NotificationDaoManager get managers => NotificationDaoManager(this);
}

class NotificationDaoManager {
  final _$NotificationDaoMixin _db;
  NotificationDaoManager(this._db);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db.attachedDatabase, _db.notifications);
}
