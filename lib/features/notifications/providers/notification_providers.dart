import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

/// Reactive feed of the current user's notifications from Drift (source of
/// truth), newest first.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<Notification>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(notificationDaoProvider);
  return dao.watchNotifications(userId);
});

/// Reactive unread badge count.
final unreadNotificationCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(notificationDaoProvider).watchUnreadCount(userId);
});

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref.read(notificationDaoProvider));
});

/// Local-first notification mutations. Notifications are normally pushed from
/// the server; offline we seed a few and let the user read/dismiss them.
class NotificationActions {
  NotificationActions(this._dao);
  final NotificationDao _dao;


  Future<void> markAllRead(String userId) => _dao.markAllAsRead(userId);

  Future<void> markRead(String id) => _dao.markAsRead(id);

  Future<void> dismiss(String id) =>
      _dao.softDeleteNotification(id, DateTime.now());


}

// ─── Where a notification leads (bug: tapping one did nothing) ─────

/// The in-app route a notification opens, or null to stay put. Reads, in
/// order: an explicit `route` in its data, its linked entity, then its type.
String? notificationRoute(Notification n) {
  final data = n.data;
  if (data != null && data.isNotEmpty) {
    try {
      final m = jsonDecode(data);
      if (m is Map) {
        final route = m['route'] ?? m['deep_link'];
        if (route is String && route.startsWith('/')) return route;
      }
    } catch (_) {
      // Not JSON: fall through to the entity and type.
    }
  }
  final entity = (n.entityType ?? '').toLowerCase().replaceAll('_', '');
  switch (entity) {
    case 'task':
    case 'habit':
    case 'goal':
      return '/grow';
    case 'achievement':
      return '/world/achievements';
    case 'worldtile':
    case 'world':
    case 'place':
      return '/world';
    case 'reflection':
    case 'aurorareflection':
    case 'letter':
      return '/aurora/letter';
  }
  return switch (n.type) {
    'achievementUnlocked' || 'achievement_unlocked' => '/world/achievements',
    'taskReminder' || 'task_reminder' => '/grow',
    'habitReminder' || 'habit_reminder' => '/grow',
    'goalDeadline' || 'goal_deadline' => '/grow',
    'levelUp' || 'level_up' => '/analytics',
    'dailySummary' || 'daily_summary' => '/analytics',
    _ => null,
  };
}

/// Bring back a dismissed notification (Undo after a swipe).
Future<void> restoreNotification(AtlasDatabase db, String id) async {
  await (db.update(db.notifications)..where((n) => n.id.equals(id))).write(NotificationsCompanion(
    isDeleted: const Value(false),
    deletedAt: const Value(null),
    updatedAt: Value(DateTime.now()),
    isDirty: const Value(true),
  ));
}
