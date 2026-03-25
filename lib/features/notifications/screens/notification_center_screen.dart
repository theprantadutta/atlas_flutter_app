import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:atlas_flutter_app/features/notifications/providers/notification_provider.dart';
import 'package:atlas_flutter_app/features/notifications/widgets/notification_card.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationProvider.notifier).loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (state.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              tooltip: 'Mark all as read',
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
            ),
        ],
      ),
      body: state.isLoading
          ? _buildShimmerList(isDark)
          : state.notifications.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(notificationProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: Key(notification.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 0),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                          ),
                          onDismissed: (_) {
                            ref
                                .read(notificationProvider.notifier)
                                .deleteNotification(notification.id);
                          },
                          child: NotificationCard(
                            notification: notification,
                            isDark: isDark,
                            onTap: () {
                              if (!notification.isRead) {
                                ref
                                    .read(notificationProvider.notifier)
                                    .markAsRead(notification.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When you receive notifications, they will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.cardDark : Colors.grey.shade200,
      highlightColor: isDark ? AppColors.cardBorderDark : Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
      ),
    );
  }
}
