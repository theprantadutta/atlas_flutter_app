import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';

/// Store objects shaped the way the two stores actually send them.
///
/// Built by hand rather than decoded from captured JSON so a field the plugin
/// renames breaks compilation here instead of silently changing what the
/// paywall shows.

// ─── Products ───────────────────────────────────────────────────────

ProductAndroid androidProduct(String id, {String price = r'$199.99'}) =>
    ProductAndroid(
      currency: 'USD',
      description: '',
      displayPrice: price,
      id: id,
      nameAndroid: 'Atlas',
      title: 'Atlas',
    );

ProductSubscriptionAndroid androidSubscription(
  String id, {
  required List<SubscriptionOffer> offers,
  String displayPrice = r'$9.99',
}) =>
    ProductSubscriptionAndroid(
      currency: 'USD',
      description: '',
      displayPrice: displayPrice,
      id: id,
      nameAndroid: 'Atlas Aurora',
      subscriptionOffers: offers,
      title: 'Atlas Aurora',
    );

ProductSubscriptionIOS iosSubscription(
  String id, {
  List<SubscriptionOffer>? offers,
  String displayPrice = r'$9.99',
}) =>
    ProductSubscriptionIOS(
      currency: 'USD',
      description: '',
      displayNameIOS: 'Atlas Aurora',
      displayPrice: displayPrice,
      id: id,
      introductoryPricePaymentModeIOS: PaymentModeIOS.Empty,
      isFamilyShareableIOS: false,
      jsonRepresentationIOS: '{}',
      subscriptionOffers: offers,
      title: 'Atlas Aurora',
      typeIOS: ProductTypeIOS.AutoRenewableSubscription,
    );

// ─── Subscription offers ────────────────────────────────────────────

PricingPhaseAndroid phase({
  required String micros,
  required String period,
  required int recurrence,
  String formatted = r'$9.99',
  int cycles = 1,
}) =>
    PricingPhaseAndroid(
      billingCycleCount: cycles,
      billingPeriod: period,
      formattedPrice: formatted,
      priceAmountMicros: micros,
      priceCurrencyCode: 'USD',
      recurrenceMode: recurrence,
    );

/// An Android offer, identified by its pricing phases.
SubscriptionOffer androidOffer({
  required List<PricingPhaseAndroid> phases,
  String id = 'offer',
  String? basePlan,
  String? offerToken,
}) =>
    SubscriptionOffer(
      basePlanIdAndroid: basePlan,
      displayPrice: phases.isEmpty ? r'$0.00' : phases.first.formattedPrice,
      id: id,
      offerTokenAndroid: offerToken,
      price: 0,
      pricingPhasesAndroid: PricingPhasesAndroid(pricingPhaseList: phases),
      type: DiscountOfferType.Introductory,
    );

/// A free-trial offer: a zero-priced finite phase, then the real price.
/// `recurrenceMode` 2 is finite, which is what makes it a trial rather than a
/// permanently free plan.
SubscriptionOffer trialOffer({
  String? offerToken,
  String id = 'trial',
  String period = 'P7D',
}) =>
    androidOffer(
      id: id,
      offerToken: offerToken,
      basePlan: 'plan-base',
      phases: [
        phase(micros: '0', period: period, recurrence: 2, formatted: 'Free'),
        phase(micros: '9990000', period: 'P1M', recurrence: 1),
      ],
    );

/// The bare base plan: one paid phase that recurs forever.
SubscriptionOffer baseOffer({
  String? offerToken,
  String id = 'plan-base',
  String? basePlan = 'plan-base',
}) =>
    androidOffer(
      id: id,
      offerToken: offerToken,
      basePlan: basePlan,
      phases: [phase(micros: '9990000', period: 'P1M', recurrence: 1)],
    );

// ─── Purchases ──────────────────────────────────────────────────────

PurchaseAndroid androidPurchase({
  String id = 'GPA.0000',
  String productId = AtlasProducts.monthly,
  String? token = 'token',
  PurchaseState state = PurchaseState.Purchased,
  bool acknowledged = false,
}) =>
    PurchaseAndroid(
      id: id,
      isAcknowledgedAndroid: acknowledged,
      isAutoRenewing: true,
      productId: productId,
      purchaseState: state,
      purchaseToken: token,
      quantity: 1,
      store: IapStore.Google,
      transactionDate: 0,
    );

PurchaseIOS iosPurchase({
  String id = 'ios-id',
  String transactionId = 'tx-1',
  String productId = AtlasProducts.monthly,
  String? token = 'jws',
  PurchaseState state = PurchaseState.Purchased,
}) =>
    PurchaseIOS(
      id: id,
      isAutoRenewing: true,
      productId: productId,
      purchaseState: state,
      purchaseToken: token,
      quantity: 1,
      store: IapStore.Apple,
      transactionDate: 0,
      transactionId: transactionId,
    );
