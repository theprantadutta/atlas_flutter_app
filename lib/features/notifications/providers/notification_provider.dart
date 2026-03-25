import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/app_notification.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';

// ─── Notification State ──────────────────────────────────────────

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// ─── Notification Notifier ───────────────────────────────────────

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    return const NotificationState();
  }

  /// Load notifications from the repository.
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final notifications = await repo.getNotifications();
      final unreadCount = await repo.getUnreadCount();
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(id);

      // Update local state optimistically
      final updated = state.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      final newUnread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: newUnread);
    } catch (_) {
      // Ignore errors
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();

      final updated = state.notifications
          .map((n) => n.isRead
              ? n
              : n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();

      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (_) {
      // Ignore errors
    }
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(id);

      final wasUnread =
          state.notifications.any((n) => n.id == id && !n.isRead);
      final updated = state.notifications.where((n) => n.id != id).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount:
            wasUnread ? state.unreadCount - 1 : state.unreadCount,
      );
    } catch (_) {
      // Ignore errors
    }
  }

  /// Refresh notifications.
  Future<void> refresh() => loadNotifications();
}

// ─── Providers ──────────────────────────────────────────────────

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

/// Stream-based unread count provider from the local database.
final unreadCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId == null) return Stream.value(0);

  final dao = ref.read(notificationDaoProvider);
  return dao.watchUnreadCount(userId);
});
