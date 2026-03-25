import 'package:drift/drift.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart'
    show NotificationsCompanion;
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/data/models/app_notification.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

class NotificationRepository extends BaseRepository {
  final NotificationDao _notificationDao;

  NotificationRepository(
    super.apiService,
    super.offlineManager,
    this._notificationDao,
  );

  // ─── READ operations ─────────────────────────────────────────

  /// Fetch notifications from the API and persist locally.
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int pageSize = 50,
  }) async {
    if (isOnline) {
      try {
        final response = await apiService.get(
          '/notifications',
          queryParameters: {
            'page': page,
            'pageSize': pageSize,
          },
        );
        final notifications =
            parseList(response.data, AppNotification.fromJson);

        // Persist to local DB
        await _persistNotificationsToDb(notifications);

        return notifications;
      } catch (_) {
        // API failed — fall through to DAO
      }
    }

    // Offline fallback: read from local DAO
    try {
      final localNotifications =
          await _notificationDao.getAllNotifications(currentUserId);
      return localNotifications
          .map((n) => AppNotification.fromJson(_driftNotificationToJson(n)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get unread notification count.
  Future<int> getUnreadCount() async {
    if (isOnline) {
      try {
        final response = await apiService.get('/notifications/unread-count');
        final count = response.data['count'] as int? ?? 0;
        return count;
      } catch (_) {
        // Fall through to local
      }
    }

    try {
      return await _notificationDao.getUnreadCount(currentUserId);
    } catch (_) {
      return 0;
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    // Optimistic local update
    await _notificationDao.markAsRead(id);

    if (isOnline) {
      try {
        await apiService.put('/notifications/$id/read');
      } catch (_) {
        // Ignore API errors — local is already updated
      }
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    // Optimistic local update
    await _notificationDao.markAllAsRead(currentUserId);

    if (isOnline) {
      try {
        await apiService.put('/notifications/read-all');
      } catch (_) {
        // Ignore API errors — local is already updated
      }
    }
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String id) async {
    await _notificationDao.deleteNotification(id);

    if (isOnline) {
      try {
        await apiService.delete('/notifications/$id');
      } catch (_) {
        // Ignore API errors — local is already deleted
      }
    }
  }

  // ─── DB Persistence Helpers ────────────────────────────────

  Future<void> _persistNotificationsToDb(
      List<AppNotification> notifications) async {
    for (final notification in notifications) {
      await _persistNotificationToDb(notification);
    }
  }

  Future<void> _persistNotificationToDb(AppNotification notification) async {
    try {
      await _notificationDao.upsertNotification(_toCompanion(notification));
    } catch (_) {
      // Ignore DB write errors
    }
  }

  NotificationsCompanion _toCompanion(AppNotification notification) {
    return NotificationsCompanion(
      id: Value(notification.id),
      userId: Value(notification.userId),
      title: Value(notification.title),
      body: Value(notification.body),
      type: Value(notification.type),
      data: Value(notification.data),
      isRead: Value(notification.isRead),
      readAt: Value(notification.readAt),
      entityType: Value(notification.entityType),
      entityId: Value(notification.entityId),
      createdAt: Value(notification.createdAt),
    );
  }

  Map<String, dynamic> _driftNotificationToJson(dynamic driftNotification) {
    return {
      'id': driftNotification.id,
      'user_id': driftNotification.userId,
      'title': driftNotification.title,
      'body': driftNotification.body,
      'type': driftNotification.type,
      'data': driftNotification.data,
      'is_read': driftNotification.isRead,
      'read_at': driftNotification.readAt?.toIso8601String(),
      'entity_type': driftNotification.entityType,
      'entity_id': driftNotification.entityId,
      'created_at': driftNotification.createdAt.toIso8601String(),
    };
  }
}
