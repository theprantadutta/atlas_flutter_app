import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Sync & data — a calm, reassuring status page. Everything is safe; nothing to
/// worry about.
class SyncManagementScreen extends ConsumerWidget {
  const SyncManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
            const _SyncStatusCard()
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.05, end: 0, curve: AppMotion.standard),
            AppSpacing.gapMd,
            const _SyncStats()
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 80.ms),
            AppSpacing.gapXl,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Everything is up to date'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sync now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
            ),
            AppSpacing.gapMd,
            const _SafetyNote(),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Icons.cloud_done_rounded,
              color: AppColors.success,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('All synced', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Last synced just now',
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

class _SyncStats extends StatelessWidget {
  const _SyncStats();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: StatTile(
            icon: Icons.inventory_2_rounded,
            color: AppColors.secondary,
            value: '342',
            label: 'Synced',
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(
            icon: Icons.pending_outlined,
            color: AppColors.tertiary,
            value: '0',
            label: 'Pending',
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(
            icon: Icons.devices_rounded,
            color: AppColors.primary,
            value: '2',
            label: 'Devices',
          ),
        ),
      ],
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      color: AppColors.secondary.withValues(alpha: 0.10),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.secondary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your progress is encrypted and backed up automatically. Even '
              'offline, everything is kept safe and syncs when you return.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
