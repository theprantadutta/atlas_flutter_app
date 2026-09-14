/// The pure half of the purchase flow: everything decidable from a store object
/// or a backend reply without talking to either.
///
/// Kept apart from EntitlementService because the OpenIAP plugin is a singleton
/// over a method channel with no platform interface to substitute, so the
/// service itself cannot be faked in a unit test the way the old one could.
/// Putting the decisions here keeps them tested and leaves the service as thin
/// glue.
library;

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';

// ---------------------------------------------------------------------------
// Identity and the backend payload
// ---------------------------------------------------------------------------

/// The key a purchase is remembered under so a replay is delivered once.
///
/// Both stores repeat themselves: StoreKit replays unfinished transactions on
/// every launch, and `getAvailablePurchases` reports every owned item on every
/// call. Android uses `id`, which is the Play order id when there is one and the
/// purchase token otherwise — the order id being exactly what the previous
/// plugin reported as `purchaseID`, so a dedup set persisted by an older build
/// keeps protecting the same purchases across this upgrade.
String? purchaseIdentity(Purchase purchase) {
  final id = purchase is PurchaseIOS ? purchase.transactionId : purchase.id;
  return id.isEmpty ? null : id;
}

/// What `/billing/verify` needs for one store purchase, or null when the store
/// handed us nothing a backend could check.
///
/// The field names are the wire names and also the keys of the persisted retry
/// queue, so an entry queued by a build running the old plugin still parses.
class BackendPurchasePayload {
  const BackendPurchasePayload({
    required this.platform,
    required this.productId,
    required this.purchaseToken,
  });

  final String platform;
  final String productId;

  /// Android: the Play purchase token. iOS: the StoreKit 2 signed transaction
  /// (JWS). OpenIAP puts both on the same field, which is the same thing the
  /// old plugin's `serverVerificationData` carried, so the backend contract is
  /// unchanged by this migration.
  final String purchaseToken;

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'product_id': productId,
        'purchase_token': purchaseToken,
      };

  static BackendPurchasePayload? fromQueueEntry(Map<String, dynamic> json) {
    final productId = json['product_id'] as String?;
    final token = json['purchase_token'] as String?;
    if (productId == null || token == null || token.isEmpty) return null;
    return BackendPurchasePayload(
      platform: json['platform'] as String? ?? 'android',
      productId: productId,
      purchaseToken: token,
    );
  }
}

BackendPurchasePayload? backendPayloadFor(Purchase purchase) {
  final token = purchase.purchaseToken;
  if (token == null || token.isEmpty) return null;

  return BackendPurchasePayload(
    platform: purchase is PurchaseIOS ? 'ios' : 'android',
    productId: purchase.productId,
    purchaseToken: token,
  );
}

// ---------------------------------------------------------------------------
// Classifying the backend's answer
// ---------------------------------------------------------------------------

/// What a failed verification means for delivery.
enum VerifyOutcome {
  /// The store told the backend this purchase is not valid. Retrying cannot
  /// change that answer.
  rejected,

  /// We could not get an answer: no network, a 5xx, a timeout. The money has
  /// moved, so this must never be shown as a failed payment, and the receipt is
  /// kept for another attempt.
  transient,
}

/// Classify a thrown verification failure.
///
/// Conflating these is how an outage turns into a refund request: a transient
/// failure that reads as a rejection abandons a purchase the user has paid for,
/// while a rejection that reads as transient retries forever.
VerifyOutcome classifyVerifyFailure(Object error) {
  if (error is! AppException) return VerifyOutcome.transient;

  final code = error.statusCode;
  // 402 is the store's own no. 400/403/404 are a malformed request, a purchase
  // that belongs to another account, or an unknown product: all settled.
  if (code == null) return VerifyOutcome.transient;
  if (code >= 500 || code == 408 || code == 429) return VerifyOutcome.transient;
  return VerifyOutcome.rejected;
}

// ---------------------------------------------------------------------------
// Building a purchase request
// ---------------------------------------------------------------------------

/// The subscription this account holds, as far as the store is concerned.
class OwnedSubscription {
  const OwnedSubscription({required this.productId, this.purchaseToken});

  final String productId;

  /// Android only. Play needs the old purchase's token to run a plan change as
  /// a replacement rather than a second purchase, which it rejects as already
  /// owned.
  final String? purchaseToken;
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Whether a value is usable as an iOS `appAccountToken`.
///
/// The OpenIAP Apple module throws on a non-UUID rather than letting Apple drop
/// it silently. Atlas user ids are Guids so they pass, but an unauthenticated
/// buy has none, and anything else is left off rather than thrown at StoreKit.
/// Android's `obfuscatedAccountId` accepts any string.
bool isUuid(String? value) => value != null && _uuid.hasMatch(value);

/// The request that buys [product], tagged with the Atlas user id so Play's
/// RTDN webhook can map an orphaned token back to this account.
///
/// Pass [replacing] to move an existing Android subscription to [product]
/// rather than start a second one. StoreKit handles plan changes within a
/// subscription group itself, so the Apple half ignores it.
RequestPurchaseProps buildPurchaseRequest({
  required ProductCommon product,
  required bool isSubscription,
  required String? accountId,
  OwnedSubscription? replacing,
  SubscriptionReplacementModeAndroid? replacementMode,
}) {
  final sku = product.id;
  final appAccountToken = isUuid(accountId) ? accountId : null;

  if (!isSubscription) {
    return RequestPurchaseProps.inApp((
      apple: RequestPurchaseIosProps(sku: sku, appAccountToken: appAccountToken),
      google: RequestPurchaseAndroidProps(
        skus: [sku],
        obfuscatedAccountId: accountId,
      ),
    ));
  }

  // Play rejects a subscription purchase with no offer token as a developer
  // error. Only offers this account is eligible for come back from the store,
  // so preferring the free-trial one is safe.
  final offer = pickSubscriptionOffer(subscriptionOffersOf(product));

  return RequestPurchaseProps.subs((
    apple: RequestSubscriptionIosProps(sku: sku, appAccountToken: appAccountToken),
    google: RequestSubscriptionAndroidProps(
      skus: [sku],
      obfuscatedAccountId: accountId,
      subscriptionOffers: offer?.offerTokenAndroid == null
          ? null
          : [
              AndroidSubscriptionOfferInput(
                sku: sku,
                offerToken: offer!.offerTokenAndroid!,
              ),
            ],
      purchaseToken: replacing?.purchaseToken,
      subscriptionProductReplacementParams: replacing == null
          ? null
          : SubscriptionProductReplacementParamsAndroid(
              oldProductId: replacing.productId,
              replacementMode: replacementMode ??
                  SubscriptionReplacementModeAndroid.WithTimeProration,
            ),
    ),
  ));
}

/// Which of a subscription's offers to buy: the one with a free trial when the
/// store returned one, else the base plan, else whatever came first.
SubscriptionOffer? pickSubscriptionOffer(List<SubscriptionOffer> offers) {
  if (offers.isEmpty) return null;
  for (final offer in offers) {
    if (trialDaysFromOffer(offer) != null) return offer;
  }
  for (final offer in offers) {
    final basePlan = offer.basePlanIdAndroid;
    if (basePlan != null && offer.id == basePlan) return offer;
  }
  return offers.first;
}

/// A product's subscription offers, whichever platform shape it arrived in.
List<SubscriptionOffer> subscriptionOffersOf(ProductCommon product) =>
    switch (product) {
      ProductSubscriptionAndroid p => p.subscriptionOffers,
      ProductSubscriptionIOS p => p.subscriptionOffers ?? const [],
      ProductAndroid p => p.subscriptionOffers ?? const [],
      ProductIOS p => p.subscriptionOffers ?? const [],
      _ => const [],
    };

// ---------------------------------------------------------------------------
// Prices and trials
// ---------------------------------------------------------------------------

/// Play's recurrenceMode for a phase that repeats forever, i.e. the base price.
const _infiniteRecurring = 1;

/// The recurring price across a subscription's Android offers, or null.
///
/// A subscription's headline `displayPrice` is its FIRST pricing phase, which
/// reads "Free" whenever a trial comes first even though the real price sits in
/// a later phase. Showing that as the price is how a paywall ends up claiming a
/// paid plan costs nothing.
String? recurringPriceFromOffers(List<SubscriptionOffer> offers) {
  for (final offer in _basePlanFirst(offers)) {
    final phases = offer.pricingPhasesAndroid?.pricingPhaseList;
    if (phases == null) continue;

    PricingPhaseAndroid? recurring;
    for (final phase in phases) {
      if (_micros(phase) > 0) recurring = phase;
    }
    if (recurring != null && recurring.formattedPrice.isNotEmpty) {
      return recurring.formattedPrice;
    }
  }
  return null;
}

/// Days of free trial one offer carries, or null when it is not a trial.
///
/// Android: a zero-priced pricing phase that does not recur forever, since a
/// permanently free base plan is not a trial. iOS: an offer whose payment mode
/// is a free trial.
int? trialDaysFromOffer(SubscriptionOffer offer) {
  final phases = offer.pricingPhasesAndroid?.pricingPhaseList;
  if (phases != null) {
    for (final phase in phases) {
      if (_micros(phase) != 0) continue;
      if (phase.recurrenceMode == _infiniteRecurring) continue;
      final days = iso8601PeriodInDays(phase.billingPeriod);
      if (days == null) continue;
      final cycles = phase.billingCycleCount > 0 ? phase.billingCycleCount : 1;
      return days * cycles;
    }
    return null;
  }

  if (offer.paymentMode != PaymentMode.FreeTrial) return null;
  final period = offer.period;
  if (period == null || period.value <= 0) return null;

  final unitDays = switch (period.unit) {
    SubscriptionPeriodUnit.Day => 1,
    SubscriptionPeriodUnit.Week => 7,
    SubscriptionPeriodUnit.Month => 30,
    SubscriptionPeriodUnit.Year => 365,
    SubscriptionPeriodUnit.Unknown => 0,
  };
  if (unitDays == 0) return null;

  final rawCount = offer.periodCount ?? 1;
  final days = period.value * unitDays * (rawCount > 0 ? rawCount : 1);
  return days > 0 ? days : null;
}

/// Days in an ISO-8601 period such as "P3D", "P1W", "P1M" — the shape Play
/// reports a billing period in. Months and years are nominal (30/365); trials
/// are configured in days or weeks, so that never reaches the UI in practice.
int? iso8601PeriodInDays(String period) {
  final match =
      RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$').firstMatch(period);
  if (match == null) return null;

  int part(int group) => int.tryParse(match.group(group) ?? '') ?? 0;
  final days = part(1) * 365 + part(2) * 30 + part(3) * 7 + part(4);
  return days > 0 ? days : null;
}

/// Micros as an int. Play sends this as a STRING, and a parse failure must not
/// read as free, so an unreadable price is treated as non-zero.
int _micros(PricingPhaseAndroid phase) =>
    int.tryParse(phase.priceAmountMicros) ?? -1;

Iterable<SubscriptionOffer> _basePlanFirst(List<SubscriptionOffer> offers) {
  bool isBasePlan(SubscriptionOffer o) =>
      o.basePlanIdAndroid != null && o.id == o.basePlanIdAndroid;
  return [
    ...offers.where(isBasePlan),
    ...offers.where((o) => !isBasePlan(o)),
  ];
}
