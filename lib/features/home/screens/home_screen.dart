import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/models/task.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/home/providers/home_provider.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_card.dart';
import 'package:atlas_flutter_app/shared/widgets/xp_progress_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeState = ref.watch(homeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Atlas',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).loadDashboard(),
        child: homeState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // ─── Hero Avatar Card ───
                  _buildHeroCard(theme, homeState, isDark),
                  const SizedBox(height: 20),

                  // ─── Stats Row ───
                  _buildStatsRow(theme, homeState, isDark),
                  const SizedBox(height: 20),

                  // ─── Attribute Bars ───
                  if (homeState.avatar != null) ...[
                    _buildAttributeSection(theme, homeState.avatar!, isDark),
                    const SizedBox(height: 20),
                  ],

                  // ─── Quick Actions ───
                  _buildQuickActions(theme, isDark),
                  const SizedBox(height: 20),

                  // ─── Today's Tasks ───
                  _buildTodayTasks(theme, homeState.todayTasks, isDark),
                ],
              ),
      ),
    );
  }

  // ─── Hero Avatar Card ───────────────────────────────────────────

  Widget _buildHeroCard(ThemeData theme, HomeState homeState, bool isDark) {
    final user = homeState.user;
    final avatar = homeState.avatar;
    final level = avatar?.level ?? user?.level ?? 1;
    final currentXp = avatar?.currentXp ?? 0;
    final requiredXp = GamificationConstants.xpRequiredForLevel(level + 1);
    final displayName = avatar?.name ?? user?.fullName ?? 'Adventurer';

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Level $level',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            XpProgressBar(
              currentXp: currentXp,
              requiredXp: requiredXp > 0 ? requiredXp : 100,
              currentLevel: level,
              showLabels: true,
              showXpText: true,
              height: 22,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Row ──────────────────────────────────────────────────

  Widget _buildStatsRow(ThemeData theme, HomeState homeState, bool isDark) {
    final analytics = homeState.analyticsData;
    final user = homeState.user;

    final todayXp = analytics?.todayXp ?? 0;
    final streak = user?.currentStreak ?? analytics?.currentStreak ?? 0;
    final level = homeState.avatar?.level ?? user?.level ?? 1;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Today XP',
            value: '+$todayXp',
            icon: Icons.bolt_rounded,
            iconColor: AppColors.xpPrimary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '$streak',
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.streakFlame,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Level',
            value: '$level',
            icon: Icons.shield_rounded,
            iconColor: AppColors.tertiary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ─── Attribute Bars Section ─────────────────────────────────────

  Widget _buildAttributeSection(
    ThemeData theme,
    Avatar avatar,
    bool isDark,
  ) {
    return AppCard(
      header: 'Attributes',
      child: Column(
        children: [
          _AttributeBar(
            label: 'Strength',
            value: avatar.strength,
            maxValue: 100,
            color: AppColors.streakFlame,
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 14),
          _AttributeBar(
            label: 'Wisdom',
            value: avatar.wisdom,
            maxValue: 100,
            color: AppColors.info,
            icon: Icons.auto_stories_rounded,
          ),
          const SizedBox(height: 14),
          _AttributeBar(
            label: 'Intelligence',
            value: avatar.intelligence,
            maxValue: 100,
            color: AppColors.badgeEpic,
            icon: Icons.psychology_rounded,
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ──────────────────────────────────────────────

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                label: 'Tasks',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.info,
                isDark: isDark,
                onTap: () => _showComingSoon('Tasks'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: 'Habits',
                icon: Icons.loop_rounded,
                color: AppColors.xpPrimary,
                isDark: isDark,
                onTap: () => _showComingSoon('Habits'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: 'Goals',
                icon: Icons.flag_rounded,
                color: AppColors.tertiary,
                isDark: isDark,
                onTap: () => _showComingSoon('Goals'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Coming in Phase 3'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Today's Tasks ──────────────────────────────────────────────

  Widget _buildTodayTasks(
    ThemeData theme,
    List<Task> tasks,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Tasks",
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add tasks to start earning XP!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TaskCard(task: task, isDark: isDark),
              )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Private Helper Widgets
// ═══════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final IconData icon;

  const _AttributeBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isDark;

  const _TaskCard({required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _categoryColor(task.category.name),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.xpPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${task.xpReward} XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.xpPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'health' => AppColors.categoryHealth,
      'fitness' => AppColors.categoryFitness,
      'mindfulness' => AppColors.categoryMindfulness,
      'work' => AppColors.categoryWork,
      'learning' => AppColors.categoryLearning,
      'social' => AppColors.categorySocial,
      'creativity' => AppColors.categoryCreative,
      _ => AppColors.info,
    };
  }
}
