import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/living_horizon.dart';

/// Atlas premium paywall — "Aurora & cloud sync". Calm, atmospheric, honest.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PlanOption {
  const _PlanOption({
    required this.productId,
    required this.title,
    required this.fallbackPrice,
    required this.cadence,
    this.badge,
    this.subtitle,
  });

  final String productId;
  final String title;
  final String fallbackPrice;
  final String cadence;
  final String? badge;
  final String? subtitle;
}

const _plans = <_PlanOption>[
  _PlanOption(
    productId: AtlasProducts.yearly,
    title: 'Yearly',
    fallbackPrice: r'$39.99',
    cadence: 'per year',
    badge: 'Best value',
    subtitle: 'Two months free vs. monthly',
  ),
  _PlanOption(
    productId: AtlasProducts.monthly,
    title: 'Monthly',
    fallbackPrice: r'$4.99',
    cadence: 'per month',
  ),
  _PlanOption(
    productId: AtlasProducts.lifetime,
    title: 'Founder',
    fallbackPrice: r'$99.99',
    cadence: 'one time',
    badge: 'Lifetime',
    subtitle: 'Pay once, yours forever',
  ),
];

const _benefits = <(IconData, String, String)>[
  (
    Icons.auto_awesome_rounded,
    'Aurora, unlimited',
    'Chat as much as you like, any day of the week.',
  ),
  (
    Icons.bolt_rounded,
    'Natural-language quick-add',
    'Turn a sentence into habits, tasks and goals.',
  ),
  (
    Icons.insights_rounded,
    'Deeper weekly reflections',
    'Richer insight from a more capable model.',
  ),
  (
    Icons.cloud_done_rounded,
    'Cloud sync & backup',
    'Your world, safe across every device.',
  ),
];

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selected = _plans.first.productId;
  bool _purchasing = false;

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    try {
      await ref.read(entitlementControllerProvider).purchase(_selected);
      if (!mounted) return;
      final premium = ref.read(isPremiumProvider);
      if (premium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Atlas premium ✨')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Purchase recorded, but premium isn’t active yet.')),
        );
      }
    } on PurchaseCancelledException {
      // User backed out — no error needed.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t complete that: $e')),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    try {
      await ref.read(entitlementControllerProvider).restore();
      if (!mounted) return;
      if (ref.read(isPremiumProvider)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Premium restored ✨')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No previous purchase found.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t restore right now.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productsProvider).value ?? const [];
    final priceFor = <String, String>{
      for (final p in products) p.id: p.price,
    };

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxl),
        children: [
          // ── Hero ──
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusXl)),
                child: const LivingHorizon(
                  height: 280,
                  progress: 1,
                  brightness: Brightness.dark,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.surfaceDark.withValues(alpha: 0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.xs,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tend your world,\nwith Aurora by your side',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Premium unlocks the full companion and keeps your world in sync.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: AppMotion.medium)
              .slideY(begin: 0.04, end: 0, curve: AppMotion.standard),
          AppSpacing.gapXl,

          // ── Benefits ──
          ..._benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _BenefitRow(icon: b.$1, title: b.$2, subtitle: b.$3),
              )),
          AppSpacing.gapMd,

          // ── Plans ──
          ..._plans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlanCard(
                  plan: plan,
                  price: priceFor[plan.productId] ?? plan.fallbackPrice,
                  selected: _selected == plan.productId,
                  onTap: () => setState(() => _selected = plan.productId),
                ),
              )),
          AppSpacing.gapLg,

          AppButton(
            label: _purchasing ? 'Please wait…' : 'Continue',
            icon: Icons.auto_awesome_rounded,
            isLoading: _purchasing,
            onPressed: _purchasing ? null : _purchase,
          ),
          AppSpacing.gapSm,
          Center(
            child: TextButton(
              onPressed: _purchasing ? null : _restore,
              child: Text('Restore purchases',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cancel anytime. Atlas works fully offline on the free plan — premium adds Aurora’s depth and cloud sync.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF10243B)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final _PlanOption plan;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.10)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected ? accent : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.title, style: theme.textTheme.titleLarge),
                      if (plan.badge != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _Badge(plan.badge!),
                      ],
                    ],
                  ),
                  if (plan.subtitle != null)
                    Text(plan.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(plan.cadence,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF3A2A00),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
