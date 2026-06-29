import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart' as db;
import 'package:atlas_flutter_app/data/models/app_notification.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Local-first Notification repository: Drift is the source of truth.
class NotificationRepository extends BaseRepository {
  final NotificationDao _notificationDao;

  NotificationRepository(
    super.apiService,
    super.offlineManager,
    this._notificationDao,
  );

  // ─── READ ─────────────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int pageSize = 50,
  }) async {
    final rows = await _notificationDao.getAllNotifications(currentUserId);
    return rows.map(_toModel).toList();
  }

  Future<int> getUnreadCount() async {
    final rows = await _notificationDao.getAllNotifications(currentUserId);
    return rows.where((n) => !n.isRead).length;
  }

  // ─── WRITE (local-first) ──────────────────────────────────────

  Future<void> markAsRead(String id) => _notificationDao.markAsRead(id);

  Future<void> markAllAsRead() =>
      _notificationDao.markAllAsRead(currentUserId);

  /// Dismiss = soft-delete (tombstone) so the dismissal syncs.
  Future<void> deleteNotification(String id) =>
      _notificationDao.softDeleteNotification(id, DateTime.now());

  // ─── Mapping ──────────────────────────────────────────────────

  AppNotification _toModel(db.Notification row) =>
      AppNotification.fromJson(_rowToJson(row));

  Map<String, dynamic> _rowToJson(db.Notification row) => {
        'id': row.id,
        'user_id': row.userId,
        'title': row.title,
        'body': row.body,
        'type': row.type,
        'data': row.data,
        'is_read': row.isRead,
        'read_at': row.readAt?.toIso8601String(),
        'entity_type': row.entityType,
        'entity_id': row.entityId,
        'created_at': row.createdAt.toIso8601String(),
      };
}
