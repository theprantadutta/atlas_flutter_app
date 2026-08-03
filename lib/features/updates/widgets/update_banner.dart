import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/updates/providers/app_update_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// A quiet note that a downloaded update is waiting. Renders nothing until
/// Play has the update on disk, and disappears for the session once dismissed —
/// an update should never feel like a demand.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(appUpdateProvider);
    if (!update.showBanner) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.auroraLilac.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.auroraLilac.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.auroraGradient,
            ),
            child: const Icon(Icons.arrow_downward_rounded,
                size: 18, color: Color(0xFF10243B)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A new Atlas is ready',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  'Restart to bring it in — takes a moment.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (update.installing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            )
          else ...[
            InkWell(
              onTap: () => ref.read(appUpdateProvider.notifier).dismiss(),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Icon(Icons.close_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            _InstallButton(
              onTap: () => ref.read(appUpdateProvider.notifier).install(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.medium).slideY(
        begin: -0.06, end: 0, curve: AppMotion.standard);
  }
}

class _InstallButton extends StatelessWidget {
  const _InstallButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            'Restart',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF10243B),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
