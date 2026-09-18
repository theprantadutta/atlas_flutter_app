import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import 'package:atlas_flutter_app/features/billing/data/purchase_mapping.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart'
    show AtlasProducts;

/// One buyable plan, resolved from whatever the store actually offers this user.
///
/// The store returns one product per id with its offers nested inside, so a
/// plan and its free-trial offer no longer arrive as two entries competing for
/// the same id. What still needs care is the price: a subscription's headline
/// [ProductCommon.displayPrice] is its FIRST pricing phase, which reads "Free"
/// whenever a trial comes first. [displayPrice] here is the recurring one.
class AtlasOffer {
  const AtlasOffer({
    required this.productId,
    required this.product,
    required this.displayPrice,
    this.trialDays = 0,
    this.trialEligibilityKnown = true,
  });

  /// The Atlas product id (`atlas_aurora_monthly`, …).
  final String productId;

  /// The store product this offer was built from. Carries the subscription
  /// offers, and the offer token the purchase request needs.
  final ProductCommon product;

  /// The recurring price, store-localized: what the user pays once any free
  /// phase ends. Never the "Free" of a trial phase.
  final String displayPrice;

  /// Length of the free trial attached to this plan, in days. 0 when the store
  /// reports none.
  ///
  /// On Android this also means *eligible*: Play omits offers the account has
  /// already consumed. On iOS it does not — see [trialEligibilityKnown].
  final int trialDays;

  /// Whether [trialDays] reflects this specific user's eligibility.
  ///
  /// True on Android. False on iOS: StoreKit exposes the introductory offer on
  /// the product regardless of whether this Apple ID has already used it. So on
  /// iOS the trial is shown as available *to new subscribers* rather than
  /// promised outright — a returning subscriber is charged immediately, and the
  /// copy must not contradict that.
  final bool trialEligibilityKnown;

  bool get hasTrial => trialDays > 0;

  /// Apply the server's trial-eligibility answer.
  ///
  /// A no-op where the store already knows (Android): Play filters offers by
  /// the Google account, which is better information than the server's
  /// per-Atlas-account view. On iOS, where StoreKit tells us nothing, this is
  /// what turns a hedged "available to new subscribers" into either a confident
  /// trial or none at all.
  ///
  /// [eligible] is null while the entitlement snapshot is still loading — leave
  /// the offer hedged rather than guessing in either direction.
  AtlasOffer withServerEligibility({
    required bool? eligible,
    required bool confirmed,
  }) {
    if (trialEligibilityKnown || eligible == null) return this;

    return AtlasOffer(
      productId: productId,
      product: product,
      displayPrice: displayPrice,
      // Ineligible: drop the trial entirely rather than showing an offer that
      // won't apply and charging the user immediately.
      trialDays: eligible ? trialDays : 0,
      // Only claim certainty when the server actually had proof.
      trialEligibilityKnown: confirmed || eligible,
    );
  }
}

/// Collapse the store's product list into one offer per Atlas plan.
Map<String, AtlasOffer> resolveOffers(List<ProductCommon> products) {
  final byId = <String, AtlasOffer>{};

  for (final product in products) {
    if (!AtlasProducts.all.contains(product.id)) continue;
    byId[product.id] = _resolve(product);
  }

  return byId;
}

AtlasOffer _resolve(ProductCommon product) {
  final offers = subscriptionOffersOf(product);

  // The product's own subtype says which store answered, so this needs no
  // Platform check and stays testable for both on any host.
  final appleShaped = product is ProductSubscriptionIOS || product is ProductIOS;

  var trialDays = 0;
  for (final offer in offers) {
    final days = trialDaysFromOffer(offer);
    if (days != null && days > trialDays) trialDays = days;
  }

  return AtlasOffer(
    productId: product.id,
    product: product,
    displayPrice: recurringPriceFromOffers(offers) ?? product.displayPrice,
    trialDays: trialDays,
    // Play only returns offers this account can still use, so a trial it
    // reports is one it will honour. StoreKit reports the product's configured
    // offer either way, so iOS stays hedged until the server rules on it.
    trialEligibilityKnown: !(appleShaped && trialDays > 0),
  );
}
