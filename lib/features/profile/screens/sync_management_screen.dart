import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/config/sync_config.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Sync and data: an honest, calm status page. Everything lives on this
/// device; cloud backup arrives with premium. Also where example data can be
/// added or removed.
class SyncManagementScreen extends ConsumerWidget {
  const SyncManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(localItemCountProvider);
    final starter = ref.watch(starterDataProvider);

    return SettingsPage(
      title: 'Sync and data',
      onBack: () => context.pop(),
      children: [
        _LocalStatus(itemCount: itemCount.value),
        const SizedBox(height: 14),
        const _CloudBackup(),
        settingsGap,
        RowGroup(
          title: 'Example data',
          children: [
            if (starter.hasStarterData)
              GroupRow(
                icon: Symbols.delete_sweep_rounded,
                title: 'Remove example data',
                subtitle: 'Clear the sample content you started with',
                destructive: true,
                onTap: () => _confirmDelete(context, ref),
              )
            else
              GroupRow(
                icon: Symbols.auto_awesome_motion_rounded,
                iconColor: AppColors.leaf,
                title: 'Add example data',
                subtitle: 'Fill Atlas with sample content to explore',
                onTap: () => _addExampleData(context, ref),
              ),
          ],
        ),
        settingsGap,
        RowGroup(
          title: 'Getting started',
          children: [
            GroupRow(
              icon: Symbols.replay_rounded,
              iconColor: AppColors.violet,
              title: 'Replay the intro',
              subtitle: 'See the welcome tour and tips again',
              onTap: () => _replayIntro(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addExampleData(BuildContext context, WidgetRef ref) async {
    await ref.read(starterDataProvider.notifier).choose(wantStarter: true);
    if (!context.mounted) return;
    AtlasToast.success(context, 'Example data added');
  }

  Future<void> _replayIntro(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).reset();
    if (!context.mounted) return;
    context.go('/intro');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmSheet(
      context,
      title: 'Remove example data?',
      body: 'This deletes the sample tasks, habits, goals, notifications and history '
          'that were added to help you get started. Anything you created yourself '
          'is kept.',
      confirmLabel: 'Remove',
      cancelLabel: 'Keep it',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(starterDataProvider.notifier).deleteStarterData();
    if (!context.mounted) return;
    AtlasToast.success(context, 'Example data removed');
  }
}

class _LocalStatus extends StatelessWidget {
  const _LocalStatus({required this.itemCount});
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = p.onRaised;
    return AtlasTile.raised(
      context,
      radius: AppSpacing.radiusXl,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved on this device',
                    style: AppTypography.dateLine.copyWith(color: on.withValues(alpha: .7))),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    itemCount == null
                        ? Text('…', style: AppTypography.statNumber.copyWith(color: on))
                        : CountUpText(
                            value: itemCount!,
                            animateFromZero: true,
                            style: AppTypography.statNumber.copyWith(color: on),
                          ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(itemCount == 1 ? 'item' : 'items',
                          style: AppTypography.subtitle.copyWith(color: on.withValues(alpha: .75))),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Atlas works fully offline. Nothing here needs a connection.',
                    style: AppTypography.meta.copyWith(color: on.withValues(alpha: .65))),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AtlasIcon(Symbols.smartphone_rounded, size: 40, color: on.withValues(alpha: .35)),
        ],
      ),
    );
  }
}

class _CloudBackup extends ConsumerWidget {
  const _CloudBackup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final canSync = ref.watch(canSyncProvider);

    if (!canSync) {
      return const UpgradeCtaCard(
        icon: Symbols.cloud_done_rounded,
        title: 'Back up with cloud sync',
        subtitle: 'Keep your world safe and in step across every device.',
        actionLabel: 'Upgrade',
      );
    }

    // Entitled. The rollout switch still governs whether the engine runs, so
    // say what is actually true.
    final live = SyncConfig.enabled;
    return AtlasTile(
      child: Row(
        children: [
          IconTile(
            style: const CategoryStyle(Symbols.cloud_done_rounded, AppColors.pine),
            size: 44,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(live ? 'Cloud sync is on' : 'Cloud sync is included',
                    style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  live
                      ? 'Your world is backed up and kept in sync across your devices.'
                      : 'It switches on as soon as syncing rolls out to your account.',
                  style: AppTypography.meta.copyWith(color: p.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
          if (live) ...[
            const SizedBox(width: AppSpacing.xs),
            AtlasChip.success(context, 'On', icon: Symbols.check_rounded),
          ],
        ],
      ),
    );
  }
}
