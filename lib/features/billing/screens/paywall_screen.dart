import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/core/config/legal_config.dart';
import 'package:atlas_flutter_app/core/errors/error_messages.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/living_horizon.dart';

final _log = AppLog('Billing');

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
    fallbackPrice: r'$99.99',
    cadence: 'per year',
    badge: 'Save 17%',
    subtitle: 'Our best value, billed yearly',
  ),
  _PlanOption(
    productId: AtlasProducts.monthly,
    title: 'Monthly',
    fallbackPrice: r'$9.99',
    cadence: 'per month',
  ),
  _PlanOption(
    productId: AtlasProducts.lifetime,
    title: 'Founder',
    fallbackPrice: r'$199.99',
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
  (
    Icons.stacked_line_chart_rounded,
    'Deep insights & export',
    'Full history, trends and CSV / JSON export.',
  ),
];

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selected = _plans.first.productId;
  bool _purchasing = false;

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    try {
      final result =
          await ref.read(entitlementControllerProvider).purchase(_selected);
      if (!mounted) return;
      if (result.isPremium) {
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
    } on StoreException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      _log.e('Purchase failed', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrors.message(e))),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _manageSubscription() async {
    try {
      await ref
          .read(entitlementControllerProvider)
          .manageSubscription(productId: _selected);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t open subscription settings.')),
      );
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

  String _shortCadence(String productId) => switch (productId) {
        AtlasProducts.yearly => '/yr',
        AtlasProducts.monthly => '/mo',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productsProvider).value ?? const [];
    final priceFor = <String, String>{
      for (final p in products) p.id: p.price,
    };
    final selectedPrice = priceFor[_selected] ??
        _plans.firstWhere((p) => p.productId == _selected).fallbackPrice;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Hero(onClose: () => context.pop())
                    .animate()
                    .fadeIn(duration: AppMotion.medium),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Everything in Aurora',
                          style: theme.textTheme.titleLarge),
                      AppSpacing.gapMd,
                      ..._benefits.map((b) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _BenefitRow(
                                icon: b.$1, title: b.$2, subtitle: b.$3),
                          )),
                      AppSpacing.gapSm,
                      Text('Choose your plan',
                          style: theme.textTheme.titleLarge),
                      AppSpacing.gapMd,
                      ..._plans.map((plan) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _PlanCard(
                              plan: plan,
                              price: priceFor[plan.productId] ??
                                  plan.fallbackPrice,
                              selected: _selected == plan.productId,
                              onTap: () =>
                                  setState(() => _selected = plan.productId),
                            ),
                          )),
                      AppSpacing.gapSm,
                      Text(
                        'Cancel anytime. Atlas works fully offline on the free '
                        'plan — premium adds Aurora’s depth and cloud sync.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      AppSpacing.gapMd,
                    ],
                  ),
                ),
              ],
            ),
          ),
          _StickyCta(
            label: _purchasing
                ? 'Please wait…'
                : 'Continue · $selectedPrice${_shortCadence(_selected)}',
            purchasing: _purchasing,
            onContinue: _purchasing ? null : _purchase,
            onRestore: _purchasing ? null : _restore,
            onManage: _purchasing ? null : _manageSubscription,
          ),
        ],
      ),
    );
  }
}

// ─── Hero (full-bleed, atmospheric) ─────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final height = topInset + 288;
    final pageColor = theme.scaffoldBackgroundColor;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const LivingHorizon(
            height: double.infinity,
            progress: 1,
            brightness: Brightness.dark,
            borderRadius: BorderRadius.zero,
          ),
          // Scrim for headline legibility + a soft melt into the page below.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                  AppColors.surfaceDark.withValues(alpha: 0.55),
                  pageColor,
                ],
                stops: const [0.0, 0.32, 0.82, 1.0],
              ),
            ),
          ),
          Positioned(
            top: topInset + AppSpacing.xxs,
            left: AppSpacing.xs,
            child: Material(
              color: Colors.black.withValues(alpha: 0.22),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Atlas Aurora',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tend your world,\nwith Aurora by your side',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(color: Colors.white, height: 1.1),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Premium unlocks the full companion and keeps your world in sync.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sticky bottom call-to-action ───────────────────────────────────

class _StickyCta extends StatelessWidget {
  const _StickyCta({
    required this.label,
    required this.purchasing,
    required this.onContinue,
    required this.onRestore,
    required this.onManage,
  });

  final String label;
  final bool purchasing;
  final VoidCallback? onContinue;
  final VoidCallback? onRestore;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm,
              AppSpacing.gutter, AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: label,
                icon: Icons.auto_awesome_rounded,
                isLoading: purchasing,
                onPressed: onContinue,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: onRestore,
                    child: Text('Restore',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Text('·',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  TextButton(
                    onPressed: onManage,
                    child: Text('Manage subscription',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
              // Guideline 3.1.2 requires the renewal terms plus links to the
              // terms/EULA and privacy policy on the purchase screen itself.
              const _LegalFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto-renewal disclosure + the two legal links App Review looks for.
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 11,
      height: 1.35,
    );
    final link = muted?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Column(
        children: [
          Text(
            LegalConfig.subscriptionDisclosure,
            textAlign: TextAlign.center,
            style: muted,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _open(LegalConfig.termsOfUseUrl),
                child: Text('Terms of Use', style: link),
              ),
              Text('   ·   ', style: muted),
              GestureDetector(
                onTap: () => _open(LegalConfig.privacyPolicyUrl),
                child: Text('Privacy Policy', style: link),
              ),
            ],
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
