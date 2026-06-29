import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
  // Seed a few notifications once so a fresh offline DB isn't empty.
  ref.read(notificationActionsProvider).ensureSeeded(userId);
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
  final _uuid = const Uuid();
  final _seeded = <String>{};

  Future<void> markAllRead(String userId) => _dao.markAllAsRead(userId);

  Future<void> markRead(String id) => _dao.markAsRead(id);

  Future<void> dismiss(String id) =>
      _dao.softDeleteNotification(id, DateTime.now());

  Future<void> ensureSeeded(String userId) async {
    if (_seeded.contains(userId)) return;
    _seeded.add(userId);
    if (await _dao.countForUser(userId) > 0) return;

    final now = DateTime.now();
    // title, body, type, hoursAgo, read
    final seeds = <List<dynamic>>[
      [
        'Achievement unlocked',
        'You earned "Week of Calm" — a 7-day streak.',
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
    for (final s in seeds) {
      final created = now.subtract(Duration(hours: s[3] as int));
      final read = s[4] as bool;
      await _dao.insertNotification(NotificationsCompanion(
        id: Value(_uuid.v4()),
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
}
