import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:atlas_flutter_app/features/billing/data/entitlements.dart';
import 'package:atlas_flutter_app/features/billing/data/store_offer.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';

/// Platform-agnostic checks on the pieces of the billing flow that decide what a
/// user is *told* and *charged* — the parts where an Android/iOS difference would
/// quietly show the wrong price or promise a trial that won't apply.
void main() {
  group('offer resolution', () {
    test('ignores products that are not Atlas plans', () {
      final offers = resolveOffers([_plain('some_other_sku')]);
      expect(offers, isEmpty);
    });

    test('falls back to the plain price when a store exposes no offer data', () {
      // The non-Android, non-StoreKit2 path: whatever the store said is the price,
      // and nothing is promised about a trial.
      final offers = resolveOffers([_plain(AtlasProducts.lifetime)]);
      final offer = offers[AtlasProducts.lifetime]!;

      expect(offer.displayPrice, r'$199.99');
      expect(offer.trialDays, 0);
      expect(offer.hasTrial, isFalse);
    });

    test('keeps one offer per product id', () {
      final offers = resolveOffers([
        _plain(AtlasProducts.monthly),
        _plain(AtlasProducts.monthly),
        _plain(AtlasProducts.yearly),
      ]);
      expect(offers.keys, containsAll([AtlasProducts.monthly, AtlasProducts.yearly]));
      expect(offers, hasLength(2));
    });

    test('an offer with no trial defaults to eligibility-known', () {
      // Only the iOS intro-offer path may claim otherwise, because only StoreKit
      // hides eligibility. A false default here would water down Android's copy.
      final offer = resolveOffers([_plain(AtlasProducts.monthly)])[AtlasProducts.monthly]!;
      expect(offer.trialEligibilityKnown, isTrue);
    });
  });

  group('server-side trial eligibility (iOS)', () {
    // StoreKit reports the intro offer regardless of whether this Apple ID already
    // used it, so on iOS the offer arrives "unknown" and the server decides.
    final unknown = AtlasOffer(
      productId: AtlasProducts.monthly,
      details: _plain(AtlasProducts.monthly),
      displayPrice: r'$9.99',
      trialDays: 3,
      trialEligibilityKnown: false,
    );

    test('drops the trial entirely when the server says ineligible', () {
      final resolved =
          unknown.withServerEligibility(eligible: false, confirmed: true);

      expect(resolved.trialDays, 0);
      expect(resolved.hasTrial, isFalse,
          reason: 'never advertise a trial that would charge immediately');
      expect(resolved.trialEligibilityKnown, isTrue);
    });

    test('confirms the trial when the server says eligible', () {
      final resolved =
          unknown.withServerEligibility(eligible: true, confirmed: false);

      expect(resolved.trialDays, 3);
      expect(resolved.trialEligibilityKnown, isTrue,
          reason: 'the server check replaces the hedged copy');
    });

    test('stays hedged while the entitlement snapshot is still loading', () {
      final resolved =
          unknown.withServerEligibility(eligible: null, confirmed: false);

      expect(resolved.trialDays, 3, reason: 'do not hide a trial on no evidence');
      expect(resolved.trialEligibilityKnown, isFalse,
          reason: 'nor promise one — keep the "new subscribers" wording');
    });

    test('leaves Android offers alone — Play already filtered them', () {
      final androidOffer = AtlasOffer(
        productId: AtlasProducts.monthly,
        details: _plain(AtlasProducts.monthly),
        displayPrice: r'$9.99',
        trialDays: 3,
        trialEligibilityKnown: true,
      );

      // Play knows the Google account; the server only knows the Atlas account,
      // so overriding here would be strictly worse information.
      final resolved =
          androidOffer.withServerEligibility(eligible: false, confirmed: true);
      expect(resolved.trialDays, 3);
    });
  });

  group('trial reporting from the backend snapshot', () {
    test('counts remaining trial days, rounding a partial day up', () {
      final ent = _entitlements(
        isTrial: true,
        premiumUntil: DateTime.now().add(const Duration(hours: 30)),
      );
      // 30h left is "2 days", not "1" — never round a user's trial down.
      expect(ent.trialDaysRemaining, 2);
    });

    test('reports no trial days when the subscription is not on a trial', () {
      final ent = _entitlements(
        isTrial: false,
        premiumUntil: DateTime.now().add(const Duration(days: 30)),
      );
      expect(ent.trialDaysRemaining, isNull);
    });

    test('never reports negative days once the trial has lapsed', () {
      final ent = _entitlements(
        isTrial: true,
        premiumUntil: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(ent.trialDaysRemaining, 0);
    });

    test('an expired premium_until revokes access locally, even if the cache says premium',
        () {
      // The offline cache can outlive the subscription; the local expiry re-check
      // is what stops a stale snapshot from granting premium forever.
      final ent = _entitlements(
        isTrial: false,
        premiumUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(ent.isPremium, isTrue);
      expect(ent.effectiveIsPremium, isFalse);
    });

    test('lifetime never expires', () {
      final ent = _entitlements(isTrial: false, premiumUntil: null, isLifetime: true);
      expect(ent.effectiveIsPremium, isTrue);
    });

    test('defaults to an unconfirmed offer when the server omits the trial block', () {
      // An older backend or a cache written before this field existed.
      final ent = Entitlements.fromJson({
        'is_premium': false,
        'is_lifetime': false,
        'features': const {},
        'aurora': const {},
      });
      expect(ent.trialEligible, isTrue);
      expect(ent.trialEligibilityConfirmed, isFalse);
    });

    test('reads server trial eligibility off the wire', () {
      final ent = Entitlements.fromJson({
        'is_premium': false,
        'is_lifetime': false,
        'trial': const {'eligible': false, 'confirmed': true},
        'features': const {},
        'aurora': const {},
      });
      expect(ent.trialEligible, isFalse);
      expect(ent.trialEligibilityConfirmed, isTrue);
    });

    test('round-trips is_trial through the offline cache', () {
      final ent = _entitlements(
        isTrial: true,
        premiumUntil: DateTime.now().add(const Duration(days: 3)),
      );
      final restored = Entitlements.fromJson(ent.toJson());
      expect(restored.isTrial, isTrue);
    });

    test('reads the backend contract exactly as it is serialized', () {
      // snake_case on the wire — a rename on either side silently drops premium.
      final ent = Entitlements.fromJson({
        'is_premium': true,
        'is_lifetime': false,
        'is_trial': true,
        'premium_until': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'features': {
          'aurora_unlimited': true,
          'aurora_quick_add': true,
          'cloud_sync': true,
          'deep_insights': true,
          'export': true,
        },
        'aurora': {
          'chat_used': 2,
          'chat_limit': null,
          'reflection_used': 1,
          'reflection_limit': null,
          'week_resets_at': null,
        },
      });

      expect(ent.effectiveIsPremium, isTrue);
      expect(ent.isTrial, isTrue);
      expect(ent.cloudSync, isTrue);
      expect(ent.aurora.chatLimit, isNull, reason: 'null limit means unlimited');
      expect(ent.aurora.chatRemaining, isNull);
    });
  });
}

ProductDetails _plain(String id) => ProductDetails(
      id: id,
      title: 'Atlas Aurora',
      description: '',
      price: id == AtlasProducts.lifetime ? r'$199.99' : r'$9.99',
      rawPrice: id == AtlasProducts.lifetime ? 199.99 : 9.99,
      currencyCode: 'USD',
    );

Entitlements _entitlements({
  required bool isTrial,
  required DateTime? premiumUntil,
  bool isLifetime = false,
}) =>
    Entitlements(
      isPremium: true,
      isLifetime: isLifetime,
      premiumUntil: premiumUntil,
      isTrial: isTrial,
      auroraUnlimited: true,
      auroraQuickAdd: true,
      cloudSync: true,
      deepInsights: true,
      export: true,
      aurora: const AuroraUsage(chatUsed: 0, reflectionUsed: 0),
    );
