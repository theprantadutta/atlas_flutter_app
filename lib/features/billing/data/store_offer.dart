import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';

/// One buyable plan, resolved from whatever the store actually offers this user.
///
/// Android is why this type exists. `queryProductDetails` returns one
/// [ProductDetails] **per offer**, so a subscription with a free trial comes back
/// TWICE under the same product id: once for the bare base plan and once for the
/// trial offer. Worse, `ProductDetails.price` is the *first* pricing phase — which
/// for the trial entry is the free phase, i.e. "$0.00". Keying a price map by
/// product id therefore shows the wrong number, and buying the wrong entry silently
/// skips the trial: Play applies the offer identified by the [details] you hand it,
/// not "the best one available".
///
/// So we collapse the duplicates into one offer per plan: the trial entry when the
/// store returned one (Play only returns offers the user is *eligible* for, so its
/// presence is the eligibility signal), and a [displayPrice] taken from the paid
/// phase rather than the free one.
class AtlasOffer {
  const AtlasOffer({
    required this.productId,
    required this.details,
    required this.displayPrice,
    this.trialDays = 0,
    this.trialEligibilityKnown = true,
  });

  /// The Atlas product id (`atlas_aurora_monthly`, …).
  final String productId;

  /// The exact [ProductDetails] to pass to `buy…` — on Android this carries the
  /// offer token that decides whether the trial is applied.
  final ProductDetails details;

  /// The recurring price, store-localized: what the user pays once any free phase
  /// ends. Never the "$0.00" of the trial phase.
  final String displayPrice;

  /// Length of the free trial attached to this plan, in days. 0 when there is no
  /// trial offer at all.
  ///
  /// On Android this also means *eligible*: Play omits offers the account has
  /// already consumed. On iOS it does not — see [trialEligibilityKnown].
  final int trialDays;

  /// Whether [trialDays] reflects this specific user's eligibility.
  ///
  /// True on Android. False on iOS: StoreKit exposes the introductory offer on the
  /// product regardless of whether this Apple ID has already used it, and
  /// `isEligibleForIntroOffer` isn't surfaced by the plugin. So on iOS the trial is
  /// shown as available *to new subscribers* rather than promised outright — a
  /// returning subscriber is charged immediately, and the copy must not contradict
  /// that.
  final bool trialEligibilityKnown;

  bool get hasTrial => trialDays > 0;

  /// Apply the server's trial-eligibility answer.
  ///
  /// A no-op where the store already knows (Android): Play filters offers by the
  /// Google account, which is better information than the server's per-Atlas-account
  /// view. On iOS, where StoreKit tells us nothing, this is what turns a hedged
  /// "available to new subscribers" into either a confident trial or none at all.
  ///
  /// [eligible] is null while the entitlement snapshot is still loading — leave the
  /// offer hedged rather than guessing in either direction.
  AtlasOffer withServerEligibility({required bool? eligible, required bool confirmed}) {
    if (trialEligibilityKnown || eligible == null) return this;

    return AtlasOffer(
      productId: productId,
      details: details,
      displayPrice: displayPrice,
      // Ineligible: drop the trial entirely rather than showing an offer that
      // won't apply and charging the user immediately.
      trialDays: eligible ? trialDays : 0,
      // Only claim certainty when the server actually had proof.
      trialEligibilityKnown: confirmed || eligible,
    );
  }
}

/// Collapse the store's raw product list into one offer per Atlas plan.
Map<String, AtlasOffer> resolveOffers(List<ProductDetails> products) {
  final byId = <String, AtlasOffer>{};

  for (final product in products) {
    if (!AtlasProducts.all.contains(product.id)) continue;

    final resolved = _resolve(product);
    final existing = byId[product.id];

    // Two entries for the same plan: keep the one that grants a trial. Falling
    // back to the longer trial keeps this deterministic if Play ever returns
    // more than one eligible offer.
    if (existing == null || resolved.trialDays > existing.trialDays) {
      byId[product.id] = resolved;
    }
  }

  return byId;
}

AtlasOffer _resolve(ProductDetails product) {
  if (Platform.isIOS || Platform.isMacOS) return _resolveApple(product);

  if (Platform.isAndroid && product is GooglePlayProductDetails) {
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;

    if (index != null && offers != null && index < offers.length) {
      final phases = offers[index].pricingPhases;

      // A free phase (0 micros) is the trial; the paid phase that follows is the
      // real price. Both are localized by Play.
      final free = phases.where((p) => p.priceAmountMicros == 0);
      final paid = phases.where((p) => p.priceAmountMicros > 0);

      return AtlasOffer(
        productId: product.id,
        details: product,
        displayPrice: paid.isNotEmpty ? paid.last.formattedPrice : product.price,
        trialDays: free.isEmpty ? 0 : _isoDurationInDays(free.first.billingPeriod),
      );
    }
  }

  // One-time products, and every non-Android store: the plain price, no offer
  // phases to unpack.
  return AtlasOffer(
    productId: product.id,
    details: product,
    displayPrice: product.price,
  );
}

/// StoreKit2 exposes the introductory offer on the product's subscription info.
/// Unlike Play there is one [ProductDetails] per product (not per offer), so the
/// `price` here is already the recurring price and only the trial has to be read.
AtlasOffer _resolveApple(ProductDetails product) {
  if (product is AppStoreProduct2Details) {
    // Named `promotionalOffers` by the plugin, but it carries every configured
    // offer; the free trial is the *introductory* one whose payment mode is a
    // free trial (as opposed to a discounted intro price).
    final offers = product.sk2Product.subscription?.promotionalOffers;
    final trial = offers
        ?.where((o) =>
            o.type == SK2SubscriptionOfferType.introductory &&
            o.paymentMode == SK2SubscriptionOfferPaymentMode.freeTrial)
        .firstOrNull;

    if (trial != null) {
      return AtlasOffer(
        productId: product.id,
        details: product,
        displayPrice: product.price,
        trialDays: _applePeriodInDays(trial.period) * trial.periodCount,
        // StoreKit won't tell us whether THIS Apple ID already used its trial.
        trialEligibilityKnown: false,
      );
    }
  }

  // StoreKit1 fallback, the lifetime product, and any product with no offers.
  return AtlasOffer(
    productId: product.id,
    details: product,
    displayPrice: product.price,
  );
}

int _applePeriodInDays(SK2SubscriptionPeriod period) => switch (period.unit) {
      SK2SubscriptionPeriodUnit.day => period.value,
      SK2SubscriptionPeriodUnit.week => period.value * 7,
      SK2SubscriptionPeriodUnit.month => period.value * 30,
      SK2SubscriptionPeriodUnit.year => period.value * 365,
    };

/// Days in an ISO 8601 billing period as Play reports it (`P3D`, `P1W`, `P1M`).
/// Play only ever uses a single unit here, so a full duration parser would be
/// dead weight. Months/years are nominal — they exist so an unexpected unit still
/// reads as "a trial" rather than silently becoming zero.
int _isoDurationInDays(String period) {
  final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period);
  if (match == null) return 0;

  final value = int.parse(match.group(1)!);
  return switch (match.group(2)) {
    'D' => value,
    'W' => value * 7,
    'M' => value * 30,
    'Y' => value * 365,
    _ => 0,
  };
}
