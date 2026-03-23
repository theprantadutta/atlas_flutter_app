import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/profile/providers/notification_settings_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Choose which notifications you want to receive.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          _NotificationTile(
            icon: Icons.check_circle_rounded,
            color: AppColors.info,
            title: 'Task Reminders',
            subtitle: 'Get reminded about upcoming and overdue tasks',
            value: settings.taskReminders,
            onChanged: () => ref
                .read(notificationSettingsProvider.notifier)
                .toggle('taskReminders'),
            isDark: isDark,
          ),
          _NotificationTile(
            icon: Icons.loop_rounded,
            color: AppColors.xpPrimary,
            title: 'Habit Reminders',
            subtitle: 'Daily reminders for your habits',
            value: settings.habitReminders,
            onChanged: () => ref
                .read(notificationSettingsProvider.notifier)
                .toggle('habitReminders'),
            isDark: isDark,
          ),
          _NotificationTile(
            icon: Icons.flag_rounded,
            color: AppColors.tertiary,
            title: 'Goal Deadlines',
            subtitle: 'Alerts when goal deadlines are approaching',
            value: settings.goalDeadlines,
            onChanged: () => ref
                .read(notificationSettingsProvider.notifier)
                .toggle('goalDeadlines'),
            isDark: isDark,
          ),
          _NotificationTile(
            icon: Icons.emoji_events_rounded,
            color: AppColors.badgeLegendary,
            title: 'Achievement Notifications',
            subtitle: 'Celebrate when you unlock new achievements',
            value: settings.achievementNotifications,
            onChanged: () => ref
                .read(notificationSettingsProvider.notifier)
                .toggle('achievementNotifications'),
            isDark: isDark,
          ),
          _NotificationTile(
            icon: Icons.summarize_rounded,
            color: AppColors.secondary,
            title: 'Daily Summary',
            subtitle: 'End-of-day summary of your progress',
            value: settings.dailySummary,
            onChanged: () => ref
                .read(notificationSettingsProvider.notifier)
                .toggle('dailySummary'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onChanged;
  final bool isDark;

  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: SwitchListTile.adaptive(
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: (_) => onChanged(),
        activeTrackColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
