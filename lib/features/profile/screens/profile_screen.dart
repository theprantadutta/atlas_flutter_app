import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/avatar/widgets/avatar_display.dart';
import 'package:atlas_flutter_app/features/profile/providers/profile_provider.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_card.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';
import 'package:atlas_flutter_app/shared/widgets/xp_progress_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: profileState.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingShimmer.avatar(size: 100),
                  const SizedBox(height: 24),
                  LoadingShimmer.text(lines: 2),
                ],
              ),
            )
          : profileState.error != null &&
                  profileState.user == null
              ? AppErrorDisplay(
                  message: profileState.error!,
                  onRetry: () =>
                      ref.read(profileProvider.notifier).loadProfile(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(profileProvider.notifier).loadProfile(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // Avatar + user info
                      _buildHeader(context, ref, profileState, isDark),
                      const SizedBox(height: 24),

                      // Stats grid
                      _buildStatsGrid(context, profileState, isDark),
                      const SizedBox(height: 24),

                      // Menu section
                      _buildMenuSection(context, ref, isDark),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ProfileState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final user = state.user;
    final avatar = state.avatar;
    final level = avatar?.level ?? user?.level ?? 1;
    final currentXp = avatar?.currentXp ?? user?.totalXp ?? 0;
    final requiredXp = GamificationConstants.xpRequiredForLevel(level + 1);

    return Column(
      children: [
        AvatarDisplay(
          avatar: avatar,
          size: 100,
          showLevel: true,
          showXpRing: true,
        ),
        const SizedBox(height: 14),
        Text(
          avatar?.name ?? user?.fullName ?? 'Adventurer',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Level $level',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        XpProgressBar(
          currentXp: currentXp,
          requiredXp: requiredXp > 0 ? requiredXp : 100,
          currentLevel: level,
          height: 18,
          showLabels: true,
          showXpText: true,
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    ProfileState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final stats = state.stats;
    final user = state.user;

    final items = [
      _StatItem(
        label: 'Tasks Done',
        value: '${stats?['totalTasksCompleted'] ?? 0}',
        icon: Icons.check_circle_rounded,
        color: AppColors.info,
      ),
      _StatItem(
        label: 'Habits Active',
        value: '${stats?['activeHabits'] ?? 0}',
        icon: Icons.loop_rounded,
        color: AppColors.xpPrimary,
      ),
      _StatItem(
        label: 'Goals Achieved',
        value: '${stats?['goalsCompleted'] ?? 0}',
        icon: Icons.flag_rounded,
        color: AppColors.tertiary,
      ),
      _StatItem(
        label: 'Achievements',
        value: '${stats?['achievementsUnlocked'] ?? 0}',
        icon: Icons.emoji_events_rounded,
        color: AppColors.badgeLegendary,
      ),
      _StatItem(
        label: 'Tiles Unlocked',
        value: '${stats?['tilesUnlocked'] ?? 0}',
        icon: Icons.explore_rounded,
        color: AppColors.secondary,
      ),
      _StatItem(
        label: 'Streak',
        value: '${user?.currentStreak ?? stats?['currentStreak'] ?? 0}',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.streakFlame,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 52) / 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorderLight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final currentThemeMode = ref.watch(themeProvider);
    final isDarkMode =
        currentThemeMode == ThemeMode.dark ||
        (currentThemeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.face_rounded,
            label: 'Avatar Customization',
            color: AppColors.primary,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/profile/avatar'),
          ),
          _divider(),
          _MenuTile(
            icon: Icons.emoji_events_rounded,
            label: 'Achievements',
            color: AppColors.tertiary,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/achievements'),
          ),
          _divider(),
          _MenuTile(
            icon: isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            label: 'Dark Mode',
            color: AppColors.badgeEpic,
            trailing: Switch.adaptive(
              value: isDarkMode,
              onChanged: (_) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
              activeTrackColor: AppColors.primary,
            ),
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          _divider(),
          _MenuTile(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            color: AppColors.info,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/profile/notifications'),
          ),
          _divider(),
          _MenuTile(
            icon: Icons.sync_rounded,
            label: 'Sync',
            color: AppColors.secondary,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/profile/sync'),
          ),
          _divider(),
          _MenuTile(
            icon: Icons.info_outline_rounded,
            label: 'About',
            color: AppColors.textSecondaryLight,
            onTap: () => _showAboutDialog(context),
          ),
          _divider(),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: AppColors.error,
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 56);
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Atlas'),
        content: const Text(
          'Atlas is a gamified self-improvement app that turns your daily habits, '
          'tasks, and goals into an epic adventure. Level up, unlock achievements, '
          'and explore the world as you grow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
