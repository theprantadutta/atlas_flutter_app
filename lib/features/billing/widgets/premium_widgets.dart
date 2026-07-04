import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/billing/data/entitlements.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// A calm, on-brand invitation to upgrade. The aurora gradient badge is the
/// single bold accent; the whole card taps through to the paywall.
class UpgradeCtaCard extends StatelessWidget {
  const UpgradeCtaCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel = 'Go Premium',
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onTap ?? () => context.push('/paywall'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.auroraGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF10243B)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _AuroraPill(label: actionLabel),
        ],
      ),
    );
  }
}

class _AuroraPill extends StatelessWidget {
  const _AuroraPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: AppColors.auroraGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF10243B),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// A live Aurora usage meter for free users: "n/3 chats left · resets Mon".
/// When exhausted it turns into an inline upgrade CTA. Renders nothing for
/// premium users or before the entitlement snapshot loads.
class AuroraUsageMeter extends ConsumerWidget {
  const AuroraUsageMeter({super.key});

  static const _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(auroraUsageProvider);
    final remaining = usage?.chatRemaining;
    // No meter for premium (unlimited) or before the snapshot resolves.
    if (usage == null || remaining == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final limit = usage.chatLimit ?? 0;
    final exhausted = remaining <= 0;
    final resets = _resetLabel(usage);

    if (exhausted) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xs),
        child: UpgradeCtaCard(
          icon: Icons.auto_awesome_rounded,
          title: 'You’ve used your free chats',
          subtitle: 'Upgrade for unlimited Aurora$resets.',
          actionLabel: 'Upgrade',
        ),
      );
    }

    final fraction = limit == 0 ? 0.0 : remaining / limit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$remaining/$limit chat${remaining == 1 ? '' : 's'} left',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (resets.isNotEmpty)
            Text(
              ' ·$resets',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AtlasProgressBar(fraction: fraction, height: 6),
          ),
        ],
      ),
    );
  }

  String _resetLabel(AuroraUsage usage) {
    final resets = usage.weekResetsAt;
    if (resets == null) return '';
    return ' resets ${_weekdays[resets.weekday - 1]}';
  }
}
