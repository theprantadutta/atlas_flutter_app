import 'package:drift/drift.dart' show Value;
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

  /// Deterministic ids for opt-in starter content (removable later).
  static const seedIds = [
    'seed-notif-0',
    'seed-notif-1',
    'seed-notif-2',
    'seed-notif-3',
  ];

  Future<void> markAllRead(String userId) => _dao.markAllAsRead(userId);

  Future<void> markRead(String id) => _dao.markAsRead(id);

  Future<void> dismiss(String id) =>
      _dao.softDeleteNotification(id, DateTime.now());

  /// Opt-in starter content (only seeded when the user asks for example data).
  Future<void> seedStarter(String userId) async {
    if (await _dao.countForUser(userId) > 0) return;

    final now = DateTime.now();
    // title, body, type, hoursAgo, read
    final seeds = <List<dynamic>>[
      [
        'Achievement unlocked',
        'You earned "Week of Calm" for a 7-day streak.',
        'achievementUnlocked',
        2,
        false,
      ],
      [
        'Your world grew',
        'A new Forest tile bloomed overnight.',
        'systemMessage',
        5,
        false,
      ],
      [
        'Gentle reminder',
        'Meditation is waiting whenever you are.',
        'habitReminder',
        28,
        true,
      ],
      [
        'Streak milestone',
        'You reached a 12-day streak. Keep tending.',
        'streakAlert',
        50,
        true,
      ],
    ];
    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final created = now.subtract(Duration(hours: s[3] as int));
      final read = s[4] as bool;
      await _dao.insertNotification(NotificationsCompanion(
        id: Value(seedIds[i]),
        userId: Value(userId),
        title: Value(s[0] as String),
        body: Value(s[1] as String),
        type: Value(s[2] as String),
        isRead: Value(read),
        readAt: read ? Value(created) : const Value(null),
        createdAt: Value(created),
        updatedAt: Value(created),
        isDirty: const Value(true),
      ));
    }
  }

  /// Remove the opt-in starter content (soft-delete so it can sync).
  Future<void> deleteStarter(String userId) async {
    final now = DateTime.now();
    for (final id in seedIds) {
      await _dao.softDeleteNotification(id, now);
    }
  }
}
