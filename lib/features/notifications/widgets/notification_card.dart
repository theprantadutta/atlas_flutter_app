import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/data/models/app_notification.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final bool isDark;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeInfo = _getTypeInfo(notification.type);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.cardBorderDark
                  : AppColors.cardBorderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: type icon in colored circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Center: title, body, time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Right: unread indicator
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationTypeInfo _getTypeInfo(String type) {
    return switch (type) {
      'daily_summary' => _NotificationTypeInfo(
          icon: Icons.summarize_rounded,
          color: AppColors.info,
        ),
      'task_reminder' => _NotificationTypeInfo(
          icon: Icons.task_alt_rounded,
          color: AppColors.primary,
        ),
      'goal_deadline' => _NotificationTypeInfo(
          icon: Icons.flag_rounded,
          color: AppColors.warning,
        ),
      'streak_alert' => _NotificationTypeInfo(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.streakFlame,
        ),
      'achievement_unlocked' => _NotificationTypeInfo(
          icon: Icons.emoji_events_rounded,
          color: AppColors.tertiary,
        ),
      'level_up' => _NotificationTypeInfo(
          icon: Icons.upgrade_rounded,
          color: AppColors.xpPrimary,
        ),
      'habit_reminder' => _NotificationTypeInfo(
          icon: Icons.loop_rounded,
          color: AppColors.secondary,
        ),
      'system_message' => _NotificationTypeInfo(
          icon: Icons.info_rounded,
          color: AppColors.textSecondaryLight,
        ),
      _ => _NotificationTypeInfo(
          icon: Icons.notifications_rounded,
          color: AppColors.info,
        ),
    };
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _NotificationTypeInfo {
  final IconData icon;
  final Color color;

  const _NotificationTypeInfo({
    required this.icon,
    required this.color,
  });
}
