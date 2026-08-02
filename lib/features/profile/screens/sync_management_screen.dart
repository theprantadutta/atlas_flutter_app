import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Sync & data — an honest, calm status page. Everything lives on this device;
/// cloud backup arrives with premium. Also where example data can be removed.
class SyncManagementScreen extends ConsumerWidget {
  const SyncManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(localItemCountProvider);
    final starter = ref.watch(starterDataProvider);

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
            AtlasHeader(title: 'Sync & data', onBack: () => context.pop()),
            AppSpacing.gapLg,
            _LocalStatusCard(
              itemCount: itemCount.value,
            )
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.05, end: 0, curve: AppMotion.standard),
            AppSpacing.gapMd,
            const _CloudBackupCard()
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 80.ms),
            AppSpacing.gapXl,
            const SectionHeader(title: 'Example data'),
            if (starter.hasStarterData)
              _ActionCard(
                icon: Icons.delete_sweep_rounded,
                color: AppColors.streakFlame,
                title: 'Remove example data',
                subtitle: 'Clear the sample content you started with',
                tinted: true,
                onTap: () => _confirmDelete(context, ref),
              ).animate().fadeIn(duration: AppMotion.medium, delay: 120.ms)
            else
              _ActionCard(
                icon: Icons.auto_awesome_motion_rounded,
                color: AppColors.secondary,
                title: 'Add example data',
                subtitle: 'Fill Atlas with sample content to explore',
                onTap: () => _addExampleData(context, ref),
              ).animate().fadeIn(duration: AppMotion.medium, delay: 120.ms),
            AppSpacing.gapXl,
            const SectionHeader(title: 'Getting started'),
            _ActionCard(
              icon: Icons.replay_rounded,
              color: AppColors.auroraLilac,
              title: 'Replay the intro',
              subtitle: 'See the welcome tour and tips again',
              onTap: () => _replayIntro(context, ref),
            ).animate().fadeIn(duration: AppMotion.medium, delay: 160.ms),
          ],
        ),
      ),
    );
  }

  Future<void> _addExampleData(BuildContext context, WidgetRef ref) async {
    await ref.read(starterDataProvider.notifier).choose(wantStarter: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Example data added')),
    );
  }

  Future<void> _replayIntro(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).reset();
    if (!context.mounted) return;
    context.go('/intro');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove example data?'),
        content: const Text(
          'This deletes the sample tasks, habits, goals, notifications and '
          'history that were added to help you get started. Anything you '
          'created yourself is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.streakFlame,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(starterDataProvider.notifier).deleteStarterData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Example data removed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LocalStatusCard extends StatelessWidget {
  const _LocalStatusCard({required this.itemCount});
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = itemCount == null
        ? 'Counting your items…'
        : '$itemCount item${itemCount == 1 ? '' : 's'} stored on this device';
    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_iphone_rounded,
              color: AppColors.success,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved on this device',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudBackupCard extends ConsumerWidget {
  const _CloudBackupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canSync = ref.watch(canSyncProvider);

    if (!canSync) {
      return const UpgradeCtaCard(
        icon: Icons.cloud_done_rounded,
        title: 'Upgrade to enable cloud sync',
        subtitle:
            'Back up your world and keep it in sync across every device.',
        actionLabel: 'Upgrade',
      );
    }

    // Premium: cloud sync is available. (The rollout kill-switch still governs
    // whether the engine actually runs.)
    return AtlasCard(
      color: AppColors.secondary.withValues(alpha: 0.10),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_done_rounded,
              color: AppColors.secondary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cloud sync is on', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Your world is backed up and kept in sync across your '
                  'devices.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable settings row: tinted icon, title, supporting line, chevron.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tinted = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Colour the title too — used for destructive actions.
  final bool tinted;

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
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: tinted ? color : null),
                ),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
