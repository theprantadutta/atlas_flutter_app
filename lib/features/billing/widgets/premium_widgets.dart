import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/billing/data/entitlements.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// A calm invitation to upgrade: a soft letter-tinted tile with the spark
/// and one ink pill. The whole tile taps through to the paywall.
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
    final p = context.palette;
    final open = onTap ?? () => context.push('/paywall');
    return AtlasTile(
      gradient: p.letter,
      onTap: open,
      semanticLabel: '$title. $subtitle',
      child: Row(
        children: [
          const AtlasSpark(size: 30, animated: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.meta.copyWith(color: p.textMuted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          PillButton(label: actionLabel, height: 36, onTap: open),
        ],
      ),
    );
  }
}

/// A live Aurora usage meter for free users: "2/3 chats left · resets Mon".
/// When exhausted it turns into an inline upgrade invitation. Renders nothing
/// for premium users or before the entitlement snapshot loads.
class AuroraUsageMeter extends ConsumerWidget {
  const AuroraUsageMeter({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
  });

  final EdgeInsetsGeometry padding;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(auroraUsageProvider);
    final remaining = usage?.chatRemaining;
    if (usage == null || remaining == null) return const SizedBox.shrink();

    final p = context.palette;
    final limit = usage.chatLimit ?? 0;
    final resets = _resetLabel(usage);

    if (remaining <= 0) {
      // Only offer the trial the store says this user can still start.
      final trialDays = ref.watch(availableTrialDaysProvider);
      return Padding(
        padding: padding,
        child: UpgradeCtaCard(
          icon: Symbols.auto_awesome_rounded,
          title: 'You’ve used this week’s chats',
          subtitle: trialDays > 0
              ? 'Try $trialDays days free for unlimited Aurora.$resets'
              : 'Unlimited Aurora with Premium.$resets',
          actionLabel: trialDays > 0 ? 'Try free' : 'Upgrade',
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          const AtlasSpark(size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$remaining of $limit chats left',
            style: AppTypography.metaStrong.copyWith(color: p.textPrimary),
          ),
          if (resets.isNotEmpty)
            Text(resets, style: AppTypography.meta.copyWith(color: p.textMuted)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: GradientBar(value: limit == 0 ? 0 : remaining / limit)),
        ],
      ),
    );
  }

  String _resetLabel(AuroraUsage usage) {
    final resets = usage.weekResetsAt;
    if (resets == null) return '';
    return ' · resets ${_weekdays[resets.weekday - 1]}';
  }
}
