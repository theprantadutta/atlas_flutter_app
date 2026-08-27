import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/features/billing/data/billing_repository.dart';
import 'package:atlas_flutter_app/features/billing/data/store_offer.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';

/// Drives [EntitlementService] through the real purchase flows with a fake store
/// and a fake backend, so the questions that actually matter — *does premium get
/// granted, and does the UI ever get stuck* — are answered by running the code
/// rather than by reading it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // `InAppPurchase.instance` lazily registers a real platform implementation
    // the first time it's read, keyed off defaultTargetPlatform — which
    // `flutter test` reports as android. That would both clobber our fake and
    // try to open a Play Billing connection that cannot exist here. Pinning the
    // platform to something with no implementation makes the initializer a
    // no-op, so the fake we install in setUp is the one that sticks.
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    InAppPurchase.instance;
    debugDefaultTargetPlatformOverride = null;
  });

  late _FakeStore store;
  late _FakeBilling billing;
  late EntitlementService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = _FakeStore();
    InAppPurchasePlatform.instance = store;
    billing = _FakeBilling();
    service = EntitlementService(billing);
  });

  tearDown(() => service.dispose());

  final offer = AtlasOffer(
    productId: AtlasProducts.monthly,
    details: _details(AtlasProducts.monthly),
    displayPrice: r'$9.99',
    trialDays: 3,
  );

  group('successful purchase', () {
    test('verifies with the backend and returns the granted entitlement', () async {
      billing.result = const EntitlementResult(isPremium: true, isTrial: true);

      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));

      final result = await future;
      expect(result.isPremium, isTrue);
      expect(result.isTrial, isTrue, reason: 'trial state must reach the UI');
      expect(billing.calls.single.productId, AtlasProducts.monthly);
    });

    test('sends the Play purchase token, not the local purchase id', () async {
      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased,
          token: 'play-token-abc'));

      await future;
      expect(billing.calls.single.purchaseToken, 'play-token-abc');
    });

    test('tags the purchase with the user id for RTDN recovery', () async {
      service.setUserIdGetter(() => 'user-guid-123');

      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));
      await future;

      expect(store.lastParam?.applicationUserName, 'user-guid-123');
    });

    test('acknowledges the purchase so Play cannot auto-refund it', () async {
      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));
      await future;

      expect(store.completed, hasLength(1));
    });

    test('announces the grant so out-of-band verifications refresh the UI', () async {
      final seen = <EntitlementResult>[];
      service.onVerified.listen(seen.add);

      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));
      await future;
      await store.pump();

      expect(seen, hasLength(1));
    });
  });

  group('failed purchase', () {
    test('a store error surfaces and grants nothing', () async {
      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.error,
          error: IAPError(source: 'test', code: 'declined', message: 'Card declined')));

      await expectLater(future, throwsA(isA<StoreException>()));
      expect(billing.calls, isEmpty, reason: 'never verify a failed purchase');
    });

    test('a cancel resolves as cancelled, not as an error', () async {
      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.canceled));

      await expectLater(future, throwsA(isA<PurchaseCancelledException>()));
      expect(billing.calls, isEmpty);
    });

    test('a store-rejected purchase (402) is not queued for retry', () async {
      billing.error = const AppException('Declined by the store', statusCode: 402);

      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));

      await expectLater(future, throwsA(isA<AppException>()));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('billing_pending_verifications'), anyOf(isNull, isEmpty));
    });

    test('a server outage is reported as "not yet verified", never as a failed payment',
        () async {
      billing.error = const ServerException('Server error', statusCode: 503);

      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));

      await expectLater(future, throwsA(isA<PurchaseNotYetVerifiedException>()));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('billing_pending_verifications'), hasLength(1),
          reason: 'the money moved — the grant must be retried');
      expect(store.completed, hasLength(1),
          reason: 'still acknowledge, or Play auto-refunds after 3 days');
    });

    test('the queued retry later succeeds and announces the grant', () async {
      billing.error = const ServerException('Server error', statusCode: 503);
      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));
      await expectLater(future, throwsA(isA<PurchaseNotYetVerifiedException>()));

      final seen = <EntitlementResult>[];
      service.onVerified.listen(seen.add);

      billing.error = null;
      billing.result = const EntitlementResult(isPremium: true);
      await service.retryPendingVerifications();
      await store.pump();

      expect(seen, hasLength(1), reason: 'a recovered grant must reach the UI');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('billing_pending_verifications'), anyOf(isNull, isEmpty));
    });
  });

  group('purchase never leaves the UI stuck', () {
    test('a deferred/pending purchase releases the caller instead of hanging', () async {
      final future = service.purchase(offer);
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.pending));

      // The whole point: this must resolve. A hang here is the spinner-forever bug.
      await expectLater(
        future.timeout(const Duration(seconds: 2)),
        throwsA(isA<PurchasePendingException>()),
      );
      expect(billing.calls, isEmpty, reason: 'nothing is owed yet, so grant nothing');
    });

    test('a silent Android cancel is resolved by the resume watchdog', () async {
      final future = service.purchase(offer);
      await store.pump();

      // Back out of the Play sheet: Android emits NO purchaseStream event at all.
      service.notifyAppResumed();

      await expectLater(
        future.timeout(const Duration(seconds: 8)),
        throwsA(isA<PurchaseCancelledException>()),
      );
    });

    test('a real purchase landing just after resume still wins over the watchdog',
        () async {
      final future = service.purchase(offer);
      await store.pump();

      service.notifyAppResumed();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.purchased));

      final result = await future.timeout(const Duration(seconds: 8));
      expect(result.isPremium, isTrue);
    });
  });

  group('restore', () {
    test('waits for the replayed purchase instead of answering too early', () async {
      billing.result = const EntitlementResult(isPremium: true);

      final future = service.restore();
      await store.pump();
      // The store replays asynchronously, well after restorePurchases() returns.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.restored));

      expect(await future, isTrue);
      expect(billing.calls, hasLength(1),
          reason: 'a restored purchase must be verified server-side');
    });

    test('reports false when the account owns nothing', () async {
      expect(await service.restore(), isFalse);
    });

    test('a second restore still reports the purchase it already verified', () async {
      billing.result = const EntitlementResult(isPremium: true);

      final first = service.restore();
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.restored,
          purchaseId: 'txn-1'));
      expect(await first, isTrue);

      final second = service.restore();
      await store.pump();
      store.emit(_purchase(AtlasProducts.monthly, PurchaseStatus.restored,
          purchaseId: 'txn-1'));

      expect(await second, isTrue,
          reason: 'deduping the API call must not become "no purchase found"');
      expect(billing.calls, hasLength(1), reason: 'but do not re-verify it');
    });
  });
}

// ─── Fakes ───────────────────────────────────────────────────────────

PurchaseDetails _purchase(
  String productId,
  PurchaseStatus status, {
  String token = 'token',
  String purchaseId = 'txn',
  IAPError? error,
}) {
  return PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: token,
      serverVerificationData: token,
      source: 'google_play',
    ),
    transactionDate: null,
    status: status,
  )
    ..error = error
    ..pendingCompletePurchase =
        status == PurchaseStatus.purchased || status == PurchaseStatus.restored;
}

ProductDetails _details(String id) => ProductDetails(
      id: id,
      title: 'Atlas Aurora',
      description: '',
      price: r'$9.99',
      rawPrice: 9.99,
      currencyCode: 'USD',
    );

class _VerifyCall {
  _VerifyCall(this.productId, this.purchaseToken);
  final String productId;
  final String purchaseToken;
}

class _FakeBilling implements BillingRepository {
  final List<_VerifyCall> calls = [];
  EntitlementResult result = const EntitlementResult(isPremium: true);
  Object? error;

  @override
  Future<EntitlementResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
  }) async {
    calls.add(_VerifyCall(productId, purchaseToken));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStore extends InAppPurchasePlatform {
  _FakeStore() : super();

  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  final List<PurchaseDetails> completed = [];
  PurchaseParam? lastParam;

  void emit(PurchaseDetails details) => _controller.add([details]);

  /// Let the service's async plumbing (isAvailable, stream subscription) settle.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastParam = purchaseParam;
    return true;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    lastParam = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    return ProductDetailsResponse(
      productDetails: identifiers.map(_details).toList(),
      notFoundIDs: const [],
    );
  }
}
