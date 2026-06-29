import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/tables/notifications_table.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AtlasDatabase>
    with _$NotificationDaoMixin {
  NotificationDao(super.db);

  // ─── Reads (exclude soft-deleted tombstones) ───

  /// Reactive feed for the user, newest first (capped at 100).
  Stream<List<Notification>> watchNotifications(String userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId) & n.isDeleted.equals(false))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(100))
        .watch();
  }

  Future<List<Notification>> getAllNotifications(String userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId) & n.isDeleted.equals(false))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
          ..limit(100))
        .get();
  }

  Future<Notification?> getNotificationById(String id) {
    return (select(notifications)..where((n) => n.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> countForUser(String userId) async {
    final rows =
        await (select(notifications)..where((n) => n.userId.equals(userId)))
            .get();
    return rows.length;
  }

  /// Watch unread count as a stream (excludes tombstones).
  Stream<int> watchUnreadCount(String userId) {
    final countExp = notifications.id.count();
    final query = selectOnly(notifications)
      ..addColumns([countExp])
      ..where(notifications.userId.equals(userId) &
          notifications.isRead.equals(false) &
          notifications.isDeleted.equals(false));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  // ─── Writes ───

  Future<int> upsertNotification(NotificationsCompanion entry) {
    return into(notifications).insertOnConflictUpdate(entry);
  }

  Future<int> insertNotification(NotificationsCompanion entry) {
    return into(notifications).insert(entry);
  }

  Future<void> updateFields(String id, NotificationsCompanion patch) async {
    await (update(notifications)..where((n) => n.id.equals(id))).write(patch);
  }

  /// Mark a single notification as read (local-first → dirty for sync).
  Future<bool> markAsRead(String id) {
    final now = DateTime.now();
    return (update(notifications)..where((n) => n.id.equals(id)))
        .write(NotificationsCompanion(
          isRead: const Value(true),
          readAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ))
        .then((rows) => rows > 0);
  }

  /// Mark all of a user's notifications as read (local-first → dirty).
  Future<int> markAllAsRead(String userId) {
    final now = DateTime.now();
    return (update(notifications)
          ..where((n) =>
              n.userId.equals(userId) &
              n.isRead.equals(false) &
              n.isDeleted.equals(false)))
        .write(NotificationsCompanion(
      isRead: const Value(true),
      readAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
  }

  /// Dismiss = soft-delete (tombstone) so the dismissal syncs.
  Future<void> softDeleteNotification(String id, DateTime now) async {
    await (update(notifications)..where((n) => n.id.equals(id))).write(
      NotificationsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> hardDeleteNotification(String id) {
    return (delete(notifications)..where((n) => n.id.equals(id))).go();
  }

  // ─── Sync helpers ───

  Future<List<Notification>> getDirtyNotifications(String userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId) & n.isDirty.equals(true)))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    await (update(notifications)..where((n) => n.id.isIn(ids))).write(
      NotificationsCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<int> purgeSyncedTombstones() {
    return (delete(notifications)
          ..where((n) => n.isDeleted.equals(true) & n.isDirty.equals(false)))
        .go();
  }
}
