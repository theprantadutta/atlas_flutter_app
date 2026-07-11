import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/providers/nudge_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// A gentle, dismissible note from Aurora derived from local data. Renders
/// nothing when there's no relevant nudge (the common case).
class AuroraNudgeCard extends ConsumerWidget {
  const AuroraNudgeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nudge = ref.watch(auroraNudgeProvider);
    if (nudge == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accent = nudge.accent();

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.auroraGradient,
                ),
                child: Icon(nudge.icon,
                    size: 18, color: const Color(0xFF10243B)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    nudge.message,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurface, height: 1.4),
                  ),
                ),
              ),
              InkWell(
                onTap: () =>
                    ref.read(dismissedNudgesProvider.notifier).dismiss(nudge.key),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          if (nudge.prompt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/aurora-chat', extra: nudge.prompt),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.forum_rounded, size: 18),
                label: const Text('Talk about it'),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.medium).slideY(
        begin: -0.06, end: 0, curve: AppMotion.standard);
  }
}
