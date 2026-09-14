import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/features/billing/data/purchase_mapping.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';

import 'billing_fixtures.dart';

/// The decisions in the purchase flow that can be made without a store.
///
/// The OpenIAP plugin is a singleton over a method channel with no platform
/// interface to substitute, so EntitlementService itself cannot be faked the way
/// the old one could. Everything worth asserting lives here instead, which is
/// also why these run identically for both stores on any host — the previous
/// suite had to stay platform-agnostic and never covered the Android offer
/// parsing at all.
void main() {
  group('purchase identity', () {
    test('Android uses the Play order id when there is one', () {
      // Also what the previous plugin reported as purchaseID, so a dedup set
      // persisted before this migration still protects the same purchases.
      expect(purchaseIdentity(androidPurchase(id: 'GPA.1234')), 'GPA.1234');
    });

    test('iOS uses the transaction id, not the shared id field', () {
      final purchase = iosPurchase(id: 'ignored', transactionId: 'tx-9');
      expect(purchaseIdentity(purchase), 'tx-9');
    });

    test('an empty id is no identity at all', () {
      // Better to verify twice than to dedup every anonymous purchase together.
      expect(purchaseIdentity(androidPurchase(id: '')), isNull);
    });
  });

  group('backend payload', () {
    test('Android sends the Play purchase token', () {
      final payload = backendPayloadFor(
        androidPurchase(productId: AtlasProducts.monthly, token: 'play-token'),
      )!;

      expect(payload.platform, 'android');
      expect(payload.productId, AtlasProducts.monthly);
      expect(payload.purchaseToken, 'play-token');
    });

    test('iOS sends the StoreKit 2 signed transaction', () {
      // OpenIAP puts the JWS on the same unified field the Android token uses,
      // which is what keeps the backend contract unchanged by this migration.
      final payload = backendPayloadFor(
        iosPurchase(productId: AtlasProducts.yearly, token: 'eyJ.jws.sig'),
      )!;

      expect(payload.platform, 'ios');
      expect(payload.purchaseToken, 'eyJ.jws.sig');
    });

    test('a purchase with no token is not sendable', () {
      // Nothing a backend could check, so there is no point claiming otherwise.
      expect(backendPayloadFor(androidPurchase(token: null)), isNull);
      expect(backendPayloadFor(androidPurchase(token: '')), isNull);
    });

    test('serializes to the wire names the backend reads', () {
      final json = backendPayloadFor(androidPurchase(token: 't'))!.toJson();
      expect(json.keys, containsAll(['platform', 'product_id', 'purchase_token']));
    });

    test('parses a retry entry queued by the previous plugin', () {
      // The old build wrote these keys; an upgrade must not strand a purchase
      // whose verification had not yet gone through.
      final payload = BackendPurchasePayload.fromQueueEntry({
        'product_id': AtlasProducts.monthly,
        'purchase_token': 'old-token',
        'platform': 'android',
        'queued_at': '2026-01-01T00:00:00.000',
      })!;

      expect(payload.productId, AtlasProducts.monthly);
      expect(payload.purchaseToken, 'old-token');
    });

    test('drops a queue entry with nothing to verify', () {
      expect(
        BackendPurchasePayload.fromQueueEntry({'product_id': 'x'}),
        isNull,
      );
    });
  });

  group('classifying a failed verification', () {
    test('the store saying no is settled', () {
      // 402 is the store's own verdict; retrying cannot change it.
      expect(
        classifyVerifyFailure(const AppException('no', statusCode: 402)),
        VerifyOutcome.rejected,
      );
    });

    test('a purchase owned by another account is settled', () {
      expect(
        classifyVerifyFailure(const AppException('theirs', statusCode: 403)),
        VerifyOutcome.rejected,
      );
    });

    for (final code in [500, 502, 503, 408, 429]) {
      test('$code is worth retrying', () {
        expect(
          classifyVerifyFailure(AppException('later', statusCode: code)),
          VerifyOutcome.transient,
        );
      });
    }

    test('no status at all means we never reached the server', () {
      // The money has moved. Treating this as a rejection abandons a purchase
      // the user has paid for.
      expect(
        classifyVerifyFailure(const AppException('offline')),
        VerifyOutcome.transient,
      );
    });

    test('a non-HTTP failure is transient', () {
      expect(classifyVerifyFailure(StateError('boom')), VerifyOutcome.transient);
    });
  });

  group('account tagging', () {
    test('an Atlas user id is a usable Apple account token', () {
      expect(isUuid('b65c85a0-416c-4d6c-bdfb-f6924e24229e'), isTrue);
    });

    test('anything that is not a UUID is refused', () {
      // The OpenIAP Apple module throws on a non-UUID rather than letting Apple
      // drop it, so a bad value would fail the purchase outright.
      expect(isUuid(null), isFalse);
      expect(isUuid(''), isFalse);
      expect(isUuid('not-a-uuid'), isFalse);
      expect(isUuid('b65c85a0416c4d6cbdfbf6924e24229e'), isFalse);
    });
  });

  group('building a purchase request', () {
    test('a one-time product asks for the in-app flow', () {
      final props = buildPurchaseRequest(
        product: androidProduct(AtlasProducts.lifetime),
        isSubscription: false,
        accountId: 'b65c85a0-416c-4d6c-bdfb-f6924e24229e',
      );
      final json = props.toJson();

      expect(json['type'], 'in-app');
      expect(_google(json)['skus'], [AtlasProducts.lifetime]);
    });

    test('a subscription carries the offer token Play demands', () {
      // A subs request without one is a developer error on the native side.
      final props = buildPurchaseRequest(
        product: androidSubscription(
          AtlasProducts.yearly,
          offers: [trialOffer(offerToken: 'tok-trial')],
        ),
        isSubscription: true,
        accountId: null,
      );

      final offers = _google(props.toJson())['subscriptionOffers'] as List;
      expect(offers, hasLength(1));
      expect((offers.first as Map)['offerToken'], 'tok-trial');
    });

    test('a non-UUID account id still tags the Android purchase', () {
      // obfuscatedAccountId accepts any string, and dropping it would cost the
      // RTDN webhook its only way back to this account.
      final props = buildPurchaseRequest(
        product: androidProduct(AtlasProducts.lifetime),
        isSubscription: false,
        accountId: 'legacy-id',
      );
      expect(_google(props.toJson())['obfuscatedAccountId'], 'legacy-id');
    });

    test('a plan switch names the subscription being replaced', () {
      final props = buildPurchaseRequest(
        product: androidSubscription(
          AtlasProducts.yearly,
          offers: [baseOffer(offerToken: 'tok-base')],
        ),
        isSubscription: true,
        accountId: null,
        replacing: const OwnedSubscription(
          productId: AtlasProducts.monthly,
          purchaseToken: 'old-token',
        ),
        replacementMode: SubscriptionReplacementModeAndroid.ChargeProratedPrice,
      );

      final google = _google(props.toJson());
      expect(google['purchaseToken'], 'old-token');
      final replacement =
          google['subscriptionProductReplacementParams'] as Map;
      expect(replacement['oldProductId'], AtlasProducts.monthly);
    });

    test('an ordinary subscription buy replaces nothing', () {
      final props = buildPurchaseRequest(
        product: androidSubscription(
          AtlasProducts.monthly,
          offers: [baseOffer(offerToken: 'tok')],
        ),
        isSubscription: true,
        accountId: null,
      );

      final google = _google(props.toJson());
      expect(google['purchaseToken'], isNull);
      expect(google['subscriptionProductReplacementParams'], isNull);
    });
  });

  group('choosing which offer to buy', () {
    test('prefers the free trial when the store returned one', () {
      // Play only returns offers this account is eligible for, so a trial it
      // reports is one it will honour.
      final trial = trialOffer(offerToken: 'tok-trial', id: 'trial-offer');
      final base = baseOffer(offerToken: 'tok-base');

      expect(pickSubscriptionOffer([base, trial])?.id, 'trial-offer');
    });

    test('falls back to the base plan when there is no trial', () {
      // An offer IS the base plan when its own id matches the base plan id;
      // anything else is a promo hanging off it.
      final base = baseOffer(
        offerToken: 'tok-base',
        id: 'plan-monthly',
        basePlan: 'plan-monthly',
      );
      final promo = baseOffer(
        offerToken: 'tok-promo',
        id: 'promo',
        basePlan: 'plan-monthly',
      );

      expect(pickSubscriptionOffer([promo, base])?.id, 'plan-monthly');
    });

    test('takes the first offer rather than none at all', () {
      final odd = SubscriptionOffer(
        displayPrice: r'$1',
        id: 'odd',
        price: 1,
        type: DiscountOfferType.Promotional,
      );
      expect(pickSubscriptionOffer([odd])?.id, 'odd');
    });

    test('no offers means no token to send', () {
      expect(pickSubscriptionOffer(const []), isNull);
    });
  });

  group('reading the trial the store actually offers', () {
    test('an Android free phase is a trial', () {
      expect(trialDaysFromOffer(trialOffer(period: 'P7D')), 7);
    });

    test('a weekly free phase is counted in days', () {
      expect(trialDaysFromOffer(trialOffer(period: 'P1W')), 7);
    });

    test('a permanently free base plan is not a trial', () {
      // recurrenceMode 1 repeats forever. Reading that as a trial would promise
      // a countdown that never starts.
      final free = androidOffer(
        phases: [phase(micros: '0', period: 'P1M', recurrence: 1)],
      );
      expect(trialDaysFromOffer(free), isNull);
    });

    test('a paid-only offer has no trial', () {
      expect(trialDaysFromOffer(baseOffer(offerToken: 'tok')), isNull);
    });

    test('an unparseable price is not treated as free', () {
      // A parse failure that read as zero would invent a trial out of nothing.
      final broken = androidOffer(
        phases: [phase(micros: 'not-a-number', period: 'P3D', recurrence: 2)],
      );
      expect(trialDaysFromOffer(broken), isNull);
    });

    test('an iOS free-trial offer is read from its payment mode', () {
      final offer = SubscriptionOffer(
        displayPrice: 'Free',
        id: 'intro',
        price: 0,
        type: DiscountOfferType.Introductory,
        paymentMode: PaymentMode.FreeTrial,
        period: const SubscriptionPeriod(unit: SubscriptionPeriodUnit.Week, value: 1),
        periodCount: 1,
      );
      expect(trialDaysFromOffer(offer), 7);
    });

    test('an iOS discounted intro price is not a free trial', () {
      final offer = SubscriptionOffer(
        displayPrice: r'$0.99',
        id: 'intro',
        price: 0.99,
        type: DiscountOfferType.Introductory,
        paymentMode: PaymentMode.PayAsYouGo,
        period: const SubscriptionPeriod(unit: SubscriptionPeriodUnit.Month, value: 1),
        periodCount: 1,
      );
      expect(trialDaysFromOffer(offer), isNull);
    });
  });

  group('ISO-8601 billing periods', () {
    test('reads the shapes Play sends', () {
      expect(iso8601PeriodInDays('P3D'), 3);
      expect(iso8601PeriodInDays('P1W'), 7);
      expect(iso8601PeriodInDays('P1M'), 30);
      expect(iso8601PeriodInDays('P1Y'), 365);
    });

    test('adds the parts of a compound period', () {
      expect(iso8601PeriodInDays('P1M15D'), 45);
    });

    test('refuses anything it does not understand', () {
      expect(iso8601PeriodInDays(''), isNull);
      expect(iso8601PeriodInDays('7 days'), isNull);
      expect(iso8601PeriodInDays('P0D'), isNull);
    });
  });

  group('the recurring price', () {
    test('is the paid phase, not the free one the store leads with', () {
      // displayPrice is the FIRST pricing phase, which reads "Free" whenever a
      // trial comes first. Showing that would claim a paid plan costs nothing.
      final offers = [
        androidOffer(phases: [
          phase(micros: '0', period: 'P7D', recurrence: 2, formatted: 'Free'),
          phase(micros: '9990000', period: 'P1M', recurrence: 1, formatted: r'$9.99'),
        ]),
      ];
      expect(recurringPriceFromOffers(offers), r'$9.99');
    });

    test('is null when no offer has a paid phase', () {
      expect(recurringPriceFromOffers(const []), isNull);
    });
  });
}

/// The Android half of a request, whichever flow built it.
Map<String, dynamic> _google(Map<String, dynamic> json) {
  final request = (json['requestPurchase'] ?? json['requestSubscription']) as Map;
  return Map<String, dynamic>.from(request['google'] as Map);
}
