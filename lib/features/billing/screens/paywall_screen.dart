import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/core/config/legal_config.dart';
import 'package:atlas_flutter_app/core/errors/error_messages.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/features/billing/data/store_offer.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';
import 'package:atlas_flutter_app/core/telemetry/telemetry.dart';

final _log = AppLog('Billing');

/// Atlas premium paywall: "Aurora & cloud sync". Calm, warm, honest.
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

const _benefits = <(IconData, Color, String, String)>[
  (
    Symbols.auto_awesome_rounded,
    AppColors.violet,
    'Aurora, unlimited',
    'Chat as much as you like, any day of the week.',
  ),
  (
    Symbols.wb_sunny_rounded,
    AppColors.amber,
    'Plan my day',
    'Aurora picks the few things that fit your energy.',
  ),
  (
    Symbols.bookmark_rounded,
    AppColors.violet,
    'She remembers what matters',
    'The facts you choose to keep, kept on your device.',
  ),
  (
    Symbols.bolt_rounded,
    AppColors.amber,
    'Natural-language quick-add',
    'Turn a sentence into habits, tasks and goals.',
  ),
  (
    Symbols.flag_rounded,
    AppColors.leaf,
    'Break a goal down',
    'Turn a big goal into a few steps you can tend.',
  ),
  (
    Symbols.edit_note_rounded,
    AppColors.coral,
    'Weekly and monthly letters',
    'Deeper reflections, and a longer letter for each month.',
  ),
  (
    Symbols.wb_twilight_rounded,
    AppColors.sky,
    'Every check-in, answered',
    'Aurora replies to each morning and evening check-in.',
  ),
  (
    Symbols.cloud_done_rounded,
    AppColors.sky,
    'Cloud sync and backup',
    'Your world, safe across every device.',
  ),
  (
    Symbols.insights_rounded,
    AppColors.leaf,
    'Deep insights and export',
    'Full history, trends and CSV or JSON export.',
  ),
];

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selected = _plans.first.productId;
  bool _purchasing = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    Telemetry.paywallViewed();
  }

  /// Store offers keyed by product id. Empty until the store answers (and in
  /// development, when no listing exists yet) — every read falls back to the
  /// hard-coded plan copy.
  Map<String, AtlasOffer> get _offers =>
      ref.read(offersProvider).value ?? const {};

  /// How Play should bill a switch.
  ///
  /// Upgrading charges now and credits the unused time, so premium never lapses
  /// and the user gets what they just paid for. Downgrading waits for the period
  /// they already paid for to run out: charging now would mean refunding the
  /// remainder of a year, and nobody expects a downgrade to move money.
  SubscriptionReplacementModeAndroid _replacementModeFor(String target) =>
      target == AtlasProducts.yearly
          ? SubscriptionReplacementModeAndroid.ChargeProratedPrice
          : SubscriptionReplacementModeAndroid.Deferred;

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    try {
      final current = ref.read(currentSubscriptionProvider).value;
      // Switching from an existing subscription is a replacement, not a new
      // purchase; Play rejects the latter as "already owned".
      final replacing =
          current != null && current.productId != _selected ? current : null;

      final result = await ref.read(entitlementControllerProvider).purchase(
            _selected,
            offer: _offers[_selected],
            replacing: replacing,
            replacementMode:
                replacing == null ? null : _replacementModeFor(_selected),
          );
      if (!mounted) return;
      if (result.isPremium) {
        final switched = ref.read(currentSubscriptionProvider).value != null &&
            ref.read(currentSubscriptionProvider).value!.productId != _selected;
        AtlasToast.success(
          context,
          switched
              ? (_selected == AtlasProducts.yearly
                  ? 'Switched to yearly'
                  : 'You will move to monthly when this period ends')
              : result.isTrial
                  ? 'Your free trial has started'
                  : 'Welcome to Atlas premium',
        );
        // The plan changed, so the cached purchase is stale.
        ref.invalidate(currentSubscriptionProvider);
        context.pop();
      } else {
        AtlasToast.warning(
            context, 'Purchase recorded, but premium isn’t active yet.');
      }
    } on PurchaseCancelledException {
      // User backed out — no error needed.
    } on PurchasePendingException {
      // Deferred payment or Ask-to-Buy: accepted, not yet charged. Say so and
      // close, rather than leaving the button spinning until it clears (days,
      // for carrier billing). The RTDN webhook grants premium when it does.
      if (!mounted) return;
      AtlasToast.info(
        context,
        'Your purchase is awaiting approval. Premium unlocks as soon as it '
        'clears. No need to keep the app open.',
      );
      context.pop();
    } on PurchaseNotYetVerifiedException {
      // The money moved; we just couldn't confirm it. Never call this a failure.
      if (!mounted) return;
      AtlasToast.info(
        context,
        'Payment received. We’ll unlock premium as soon as we can reach the '
        'server. It happens automatically.',
      );
      context.pop();
    } on StoreException catch (e) {
      if (!mounted) return;
      AtlasToast.error(context, e.message);
    } catch (e, st) {
      _log.e('Purchase failed', error: e, stackTrace: st);
      if (!mounted) return;
      AtlasToast.error(context, AppErrors.message(e));
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final restored = await ref.read(entitlementControllerProvider).restore();
      if (!mounted) return;

      if (ref.read(isPremiumProvider)) {
        AtlasToast.success(context, 'Premium restored');
        context.pop();
      } else if (restored) {
        // The store DID return a purchase — it's just no longer active (an
        // expired or refunded subscription). Saying "nothing found" here would
        // send the user hunting for a bug that isn't one.
        AtlasToast.info(
          context,
          'We found a past purchase, but it’s no longer active.',
        );
      } else {
        AtlasToast.info(context, 'No previous purchase found.');
      }
    } catch (_) {
      if (!mounted) return;
      AtlasToast.error(context, 'Couldn’t restore right now.');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  String _shortCadence(String productId) => switch (productId) {
        AtlasProducts.yearly => '/yr',
        AtlasProducts.monthly => '/mo',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final offersAsync = ref.watch(offersProvider);
    final offers = offersAsync.value ?? const <String, AtlasOffer>{};
    // In debug the paywall stays usable with no store listing (the dev-bypass
    // token covers it); in release, tapping before the store answers is what we
    // guard against.
    final offersLoading = offersAsync.isLoading && !kDebugMode;
    final busy = _purchasing || _restoring;

    // What this account already holds. A subscriber opening the paywall is here
    // to see their plan or move between plans, not to be sold to again.
    final isPremium = ref.watch(isPremiumProvider);
    final isLifetime =
        ref.watch(entitlementsProvider).entitlements?.isLifetime ?? false;
    final currentProductId =
        ref.watch(currentSubscriptionProvider).value?.productId;
    final onSelectedPlan = currentProductId == _selected;

    // A subscriber whose live plan we can name may move to the other one.
    // Everyone else who is already premium (a Founder, or premium granted
    // without a store purchase) has nothing to buy, so the plans and every
    // price and trial line come off the screen entirely. Showing "start your
    // 7-day free trial" to someone already paying is the exact incoherence
    // this guards.
    final canSwitchPlans =
        isPremium && !isLifetime && currentProductId != null;
    final showPlans = !isPremium || canSwitchPlans;

    // Switching is between the two subscriptions. The lifetime unlock is a
    // one-time product, and Play cannot replace a subscription with one.
    final visiblePlans = canSwitchPlans
        ? _plans.where((p) => p.productId != AtlasProducts.lifetime).toList()
        : _plans;

    final selectedPlan = _plans.firstWhere((p) => p.productId == _selected);
    final selectedOffer = offers[_selected];
    // The store's price is the RECURRING one, never the trial's "$0.00" phase:
    // see AtlasOffer. Fall back to the hard-coded anchor before the store answers.
    final selectedPrice = selectedOffer?.displayPrice ?? selectedPlan.fallbackPrice;
    final selectedTrialDays = selectedOffer?.trialDays ?? 0;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Hero(
                  onClose: () => context.pop(),
                  onRestore: busy ? null : _restore,
                  restoring: _restoring,
                ),
                Padding(
                  padding: readableInsets(context, top: AppSpacing.lg, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isPremium) ...[
                        _PremiumBanner(
                          isLifetime: isLifetime,
                          currentProductId: currentProductId,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (showPlans) ...[
                        SectionTitle(canSwitchPlans ? 'Change your plan' : 'Choose your plan'),
                        const SizedBox(height: AppSpacing.sm),
                        _PlanSelector(
                          plans: visiblePlans,
                          offers: offers,
                          selected: _selected,
                          currentProductId: currentProductId,
                          cadenceFor: _shortCadence,
                          onSelect: (id) => setState(() => _selected = id),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      SectionTitle(isPremium ? 'What you have' : 'Everything in Premium'),
                      const SizedBox(height: AppSpacing.sm),
                      AtlasTile(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Column(
                          children: [
                            for (var i = 0; i < _benefits.length; i++) ...[
                              if (i > 0) Divider(height: 1, color: p.hairline, indent: 54),
                              _BenefitRow(
                                icon: _benefits[i].$1,
                                color: _benefits[i].$2,
                                title: _benefits[i].$3,
                                subtitle: _benefits[i].$4,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Text(
                          isPremium
                              ? 'Manage or cancel any time in Google Play.'
                              : selectedTrialDays > 0
                                  ? 'Free for $selectedTrialDays days, then '
                                      '$selectedPrice${_shortCadence(_selected)}. '
                                      'Cancel anytime before it ends and you won’t be '
                                      'charged.'
                                      '${selectedOffer?.trialEligibilityKnown == false ? ' Trial available to new subscribers.' : ''}'
                                  : 'Cancel anytime. Atlas works fully offline on the '
                                      'free plan. Premium adds Aurora’s depth and '
                                      'cloud sync.',
                          textAlign: TextAlign.center,
                          style: AppTypography.meta.copyWith(color: p.textMuted, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // No bar at all when nothing can be bought: a disabled "Your current
          // plan" button is still a button, and it invites a tap that does
          // nothing.
          if (showPlans)
            _StickyCta(
              label: busy
                  ? 'Please wait'
                  : onSelectedPlan
                      ? 'Your current plan'
                      : currentProductId != null
                          ? (_selected == AtlasProducts.yearly
                              ? 'Switch to yearly · $selectedPrice'
                              : 'Switch to monthly · $selectedPrice')
                          : selectedTrialDays > 0 && !isPremium
                              ? 'Start your $selectedTrialDays-day free trial'
                              : 'Continue · $selectedPrice${_shortCadence(_selected)}',
              trialDays: isPremium ? 0 : selectedTrialDays,
              trialEligibilityKnown: selectedOffer?.trialEligibilityKnown ?? true,
              purchasing: busy,
              // Buying before the store has answered would hand purchase() a null
              // offer, which in release reads as "that plan isn't available":
              // a confusing error for a store that is merely slow.
              // Nothing to do on a plan you already hold, and a Founder has
              // nothing left to buy at all.
              onContinue: busy || offersLoading || isLifetime || onSelectedPlan
                  ? null
                  : _purchase,
            ),
        ],
      ),
    );
  }
}

/// Tells a subscriber where they stand, so the paywall stops reading as a
/// sales page to someone who has already bought.
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({
    required this.isLifetime,
    required this.currentProductId,
  });

  final bool isLifetime;

  /// Null while the store is still being asked, which is why the copy below
  /// never claims a specific plan it cannot name.
  final String? currentProductId;

  String get _planName => switch (currentProductId) {
        AtlasProducts.yearly => 'Yearly',
        AtlasProducts.monthly => 'Monthly',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final line = isLifetime
        ? 'You are a Founder. Every premium feature, yours forever.'
        : _planName.isEmpty
            ? 'Your subscription is active.'
            : 'You are on the $_planName plan.';

    final hint = isLifetime
        ? null
        : _planName.isEmpty
            ? null
            : 'Choose the other plan below to switch. Manage or cancel any time '
                'in Google Play.';

    return AtlasTile(
      color: p.successBg,
      radius: AppSpacing.radiusRow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtlasIcon(Symbols.check_circle_rounded, filled: true, size: 24, color: p.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium active', style: AppTypography.rowTitle.copyWith(color: p.success)),
                const SizedBox(height: 2),
                Text(line, style: AppTypography.meta.copyWith(color: p.textPrimary, height: 1.4)),
                if (hint != null) ...[
                  const SizedBox(height: 6),
                  Text(hint, style: AppTypography.meta.copyWith(color: p.textMuted, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero (full-bleed letter gradient) ──────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.onClose,
    required this.onRestore,
    required this.restoring,
  });

  final VoidCallback onClose;

  /// Null while a purchase or restore is already running.
  final VoidCallback? onRestore;
  final bool restoring;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: p.letter,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -78,
            bottom: 18,
            child: Opacity(opacity: .5, child: AtlasSpark(size: 170, animated: true)),
          ),
          Padding(
            padding: readableInsets(context, top: topInset + AppSpacing.xs, bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      icon: Symbols.close_rounded,
                      semanticLabel: 'Close',
                      background: p.letterSecondaryButton,
                      onTap: onClose,
                    ),
                    const Spacer(),
                    // Restore sits opposite the close button rather than under the
                    // CTA. It is a rare, recovery-shaped action: people who already
                    // paid come looking for it, and everyone else should not have
                    // to scroll past it to read what they are buying.
                    PillButton(
                      label: 'Restore',
                      variant: PillVariant.letter,
                      height: 40,
                      busy: restoring,
                      haptic: PressHaptic.selection,
                      onTap: onRestore,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('ATLAS PREMIUM', style: AppTypography.kicker.copyWith(color: p.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tend your days\nwith Aurora beside you',
                  style: AppTypography.subScreenTitle.copyWith(height: 1.08, color: p.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: 72),
                  child: Text(
                    'The whole companion, and your world kept safe in the cloud.',
                    style: AppTypography.body.copyWith(color: p.textBody),
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

// ─── Sticky bottom call-to-action ───────────────────────────────────

class _StickyCta extends StatelessWidget {
  const _StickyCta({
    required this.label,
    required this.trialDays,
    required this.trialEligibilityKnown,
    required this.purchasing,
    required this.onContinue,
  });

  final String label;
  final int trialDays;
  final bool trialEligibilityKnown;
  final bool purchasing;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.canvas,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: readableInsets(context, top: AppSpacing.sm, bottom: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PillButton(
                label: label,
                icon: purchasing ? null : Symbols.auto_awesome_rounded,
                variant: PillVariant.gradient,
                height: 56,
                expand: true,
                busy: purchasing,
                haptic: PressHaptic.medium,
                onTap: onContinue,
              ),
              // Guideline 3.1.2 requires the renewal terms plus links to the
              // terms/EULA and privacy policy on the purchase screen itself.
              // With a free trial, the conversion terms have to be here too.
              _LegalFooter(
                trialDays: trialDays,
                trialEligibilityKnown: trialEligibilityKnown,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto-renewal disclosure and the two legal links App Review looks for.
class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.trialDays,
    required this.trialEligibilityKnown,
  });

  final int trialDays;
  final bool trialEligibilityKnown;

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final muted = AppTypography.sans(size: 11, weight: FontWeight.w500, height: 1.35, color: p.textMuted);
    final link = muted.copyWith(
      color: p.textPrimary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: p.textMuted,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Column(
        children: [
          Text(
            LegalConfig.subscriptionDisclosure(
              trialDays: trialDays,
              trialEligibilityKnown: trialEligibilityKnown,
            ),
            textAlign: TextAlign.center,
            style: muted,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Pressable(
                onTap: () => _open(LegalConfig.termsOfUseUrl),
                semanticLabel: 'Terms of Use',
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Terms of Use', style: link),
                ),
              ),
              Text('·', style: muted),
              Pressable(
                onTap: () => _open(LegalConfig.privacyPolicyUrl),
                semanticLabel: 'Privacy Policy',
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Privacy Policy', style: link),
                ),
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
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconTile(style: CategoryStyle(icon, color), size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
                const SizedBox(height: 1),
                Text(subtitle, style: AppTypography.meta.copyWith(color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The plans in one raised ink card. The chosen one is a cream pill; the
/// plan you're already on is marked, not offered.
class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.plans,
    required this.offers,
    required this.selected,
    required this.currentProductId,
    required this.cadenceFor,
    required this.onSelect,
  });

  final List<_PlanOption> plans;
  final Map<String, AtlasOffer> offers;
  final String selected;
  final String? currentProductId;
  final String Function(String productId) cadenceFor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.raised,
        border: p.raisedBorderSide,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
      ),
      child: Column(
        children: [
          for (final plan in plans)
            _PlanRow(
              plan: plan,
              offer: offers[plan.productId],
              cadenceSuffix: cadenceFor(plan.productId),
              selected: selected == plan.productId,
              isCurrent: plan.productId == currentProductId,
              onTap: () => onSelect(plan.productId),
            ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.offer,
    required this.cadenceSuffix,
    required this.selected,
    required this.onTap,
    this.isCurrent = false,
  });

  /// The plan this account is already on. Marked rather than offered.
  final bool isCurrent;

  final _PlanOption plan;

  /// The live store offer, or null before the store answers.
  final AtlasOffer? offer;

  /// Compact cadence for the trial line ("/mo", "/yr", "").
  final String cadenceSuffix;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Always the recurring price: the trial's free phase is never the headline.
    final price = offer?.displayPrice ?? plan.fallbackPrice;

    // Only the store knows whether THIS user still has a trial left; Play omits
    // offers you're no longer eligible for. So an absent offer means no promise.
    final trialDays = offer?.trialDays ?? 0;

    final fg = selected ? AppColors.ink : p.onRaised;
    final sub = selected ? AppColors.ink.withValues(alpha: .6) : p.onRaised.withValues(alpha: .6);

    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      scale: .98,
      semanticLabel: '${plan.title}, $price ${plan.cadence}',
      child: Semantics(
        selected: selected,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: selected ? p.navPill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(plan.title, style: AppTypography.rowTitle.copyWith(color: fg)),
                        if (isCurrent) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _Badge('Current', flat: true, onSelected: selected),
                        ] else if (plan.badge != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _Badge(plan.badge!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (trialDays > 0)
                      Text('$trialDays days free, then $price$cadenceSuffix',
                          style: AppTypography.metaStrong.copyWith(
                              color: selected ? AtlasPalette.accent : AppColors.sunriseA))
                    else if (plan.subtitle != null)
                      Text(plan.subtitle!, style: AppTypography.meta.copyWith(color: sub)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: AppTypography.display(size: 21, color: fg)),
                  Text(plan.cadence, style: AppTypography.tiny.copyWith(color: sub)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.flat = false, this.onSelected = false});
  final String label;

  /// Sales labels wear the sunrise; a flat badge marks a statement of fact
  /// instead, like the plan the user is already on.
  final bool flat;
  final bool onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: flat ? null : AppColors.sunrise,
        color: flat ? (onSelected ? AppColors.ink.withValues(alpha: .1) : p.onRaised.withValues(alpha: .14)) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.sans(
          size: 11,
          weight: FontWeight.w800,
          height: 1.2,
          color: flat ? (onSelected ? AppColors.ink : p.onRaised) : AppColors.white,
        ),
      ),
    );
  }
}
