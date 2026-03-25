import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/notifications_table.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AtlasDatabase>
    with _$NotificationDaoMixin {
  NotificationDao(super.db);

  /// Get all notifications for a user, ordered by createdAt desc, limit 100.
  Future<List<Notification>> getAllNotifications(String userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(100))
        .get();
  }

  /// Get unread notification count for a user.
  Future<int> getUnreadCount(String userId) async {
    final countExp = notifications.id.count();
    final query = selectOnly(notifications)
      ..addColumns([countExp])
      ..where(
          notifications.userId.equals(userId) & notifications.isRead.equals(false));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Watch unread notification count as a stream.
  Stream<int> watchUnreadCount(String userId) {
    final countExp = notifications.id.count();
    final query = selectOnly(notifications)
      ..addColumns([countExp])
      ..where(
          notifications.userId.equals(userId) & notifications.isRead.equals(false));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  /// Upsert a notification (insert or update on conflict).
  Future<int> upsertNotification(NotificationsCompanion entry) {
    return into(notifications).insertOnConflictUpdate(entry);
  }

  /// Mark a single notification as read.
  Future<bool> markAsRead(String id) {
    return (update(notifications)..where((n) => n.id.equals(id))).write(
      NotificationsCompanion(
        isRead: const Value(true),
        readAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  /// Mark all notifications as read for a user.
  Future<int> markAllAsRead(String userId) {
    return (update(notifications)
          ..where(
              (n) => n.userId.equals(userId) & n.isRead.equals(false)))
        .write(
      NotificationsCompanion(
        isRead: const Value(true),
        readAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a single notification.
  Future<int> deleteNotification(String id) {
    return (delete(notifications)..where((n) => n.id.equals(id))).go();
  }

  /// Delete all notifications for a user.
  Future<int> deleteAllForUser(String userId) {
    return (delete(notifications)..where((n) => n.userId.equals(userId))).go();
  }
}
