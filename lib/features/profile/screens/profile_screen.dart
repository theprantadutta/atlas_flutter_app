import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_data.dart';
import 'package:atlas_flutter_app/core/sample/sample_extra.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// You — the home for the person behind the world. A calm hero with avatar,
/// level and XP, a quiet stat strip, the attributes that grow with care, and a
/// gentle settings menu.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatXp(int xp) =>
      xp >= 1000 ? '${(xp / 1000).toStringAsFixed(1)}k' : '$xp';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = sampleUser();
    final attributes = ref.watch(attributesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.bottomNavSpace,
          ),
          children: [
            AtlasHeader(
              title: 'You',
              trailing: CircleActionButton(
                icon: isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
            ),
            AppSpacing.gapLg,
            _ProfileHero(user: user, formatXp: _formatXp)
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.05, end: 0, curve: AppMotion.standard),
            AppSpacing.gapMd,
            _StatStrip(user: user, formatXp: _formatXp)
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 80.ms),
            AppSpacing.gapXl,
            const SectionHeader(title: 'Attributes'),
            _AttributesCard(attributes: attributes)
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 120.ms),
            AppSpacing.gapXl,
            const SectionHeader(title: 'Settings'),
            _SettingsMenu(),
          ],
        ),
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user, required this.formatXp});
  final User user;
  final String Function(int) formatXp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = user.fullName.isNotEmpty
        ? user.fullName.characters.first.toUpperCase()
        : '?';
    final xpInLevel = user.totalXp % 1000;
    const xpForNext = 1000;
    final fraction = xpInLevel / xpForNext;

    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarCircle(initial: initial),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _LevelPill(level: user.level),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          AtlasProgressBar(fraction: fraction, height: 12),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpInLevel / $xpForNext XP',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${xpForNext - xpInLevel} to level ${user.level + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.auroraGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.auroraLilac.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 13, color: Color(0xFF3A2A00)),
          const SizedBox(width: 5),
          Text(
            'Level $level',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF3A2A00),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat strip ─────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.user, required this.formatXp});
  final User user;
  final String Function(int) formatXp;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      const StatTile(
        icon: Icons.check_circle_rounded,
        color: AppColors.categoryWork,
        value: '128',
        label: 'Tasks done',
      ),
      const StatTile(
        icon: Icons.loop_rounded,
        color: AppColors.xpPrimary,
        value: '9',
        label: 'Habits',
      ),
      StatTile(
        icon: Icons.local_fire_department_rounded,
        color: AppColors.streakFlame,
        value: '${user.currentStreak}',
        label: 'Streak',
      ),
      StatTile(
        icon: Icons.bolt_rounded,
        color: AppColors.tertiary,
        value: formatXp(user.totalXp),
        label: 'Total XP',
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

// ─── Attributes ─────────────────────────────────────────────────────

class _AttributesCard extends StatelessWidget {
  const _AttributesCard({required this.attributes});
  final List<AttributeStat> attributes;

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < attributes.length; i++) ...[
            if (i > 0) AppSpacing.gapLg,
            _AttributeRow(attr: attributes[i]),
          ],
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.attr});
  final AttributeStat attr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(attr.icon, color: attr.color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                attr.label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${attr.value}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: attr.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        AtlasProgressBar(
          fraction: attr.value / 100,
          height: 8,
          color: attr.color,
        ),
      ],
    );
  }
}

// ─── Settings ───────────────────────────────────────────────────────

class _SettingsMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _SettingsRow(
          icon: Icons.face_retouching_natural_rounded,
          color: AppColors.primary,
          title: 'Customize avatar',
          subtitle: 'Make this world yours',
          onTap: () => context.push('/profile/avatar'),
        ),
        AppSpacing.gapSm,
        _SettingsRow(
          icon: Icons.notifications_none_rounded,
          color: AppColors.info,
          title: 'Notifications',
          subtitle: 'Choose what reaches you',
          onTap: () => context.push('/profile/notifications'),
        ),
        AppSpacing.gapSm,
        _SettingsRow(
          icon: Icons.cloud_sync_rounded,
          color: AppColors.secondary,
          title: 'Sync & data',
          subtitle: 'Your progress, kept safe',
          onTap: () => context.push('/profile/sync'),
        ),
        AppSpacing.gapSm,
        _SettingsRow(
          icon: Icons.logout_rounded,
          color: AppColors.streakFlame,
          title: 'Log out',
          subtitle: 'See you again soon',
          destructive: true,
          onTap: () => ref.read(authProvider.notifier).logout(),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: destructive ? color : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
