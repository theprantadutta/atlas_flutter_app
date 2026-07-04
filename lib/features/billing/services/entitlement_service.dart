import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/features/billing/data/billing_repository.dart';

/// Product identifiers — must match the IDs created in Play Console / App Store
/// Connect *and* the backend's accepted product IDs.
class AtlasProducts {
  AtlasProducts._();

  static const monthly = 'atlas_aurora_monthly';
  static const yearly = 'atlas_aurora_yearly';
  static const lifetime = 'atlas_founder_lifetime';

  static const Set<String> all = {monthly, yearly, lifetime};
}

/// Android application id — used to build the Play subscription-management URL.
const _androidPackage = 'com.pranta.atlas';

/// Wraps `in_app_purchase` and the backend verify flow.
///
/// Real purchase path: query the store → buy → on a `purchased`/`restored`
/// event take the server verification token (JWS / purchase token) → backend
/// `/billing/verify`, which validates it server-side.
///
/// Dev path: when the store is unavailable or the product isn't configured yet
/// (no store listing during development), fall back to a dev token — but ONLY in
/// debug builds. In release we surface the error instead of silently faking a
/// purchase.
class EntitlementService {
  EntitlementService(this._billing);

  final BillingRepository _billing;
  final InAppPurchase _iap = InAppPurchase.instance;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Available store products (empty when the store is unavailable or the
  /// products aren't configured yet).
  Future<List<ProductDetails>> loadProducts() async {
    if (!await _iap.isAvailable()) return const [];
    final response = await _iap.queryProductDetails(AtlasProducts.all);
    return response.productDetails;
  }

  /// Buy [productId] and verify it with the backend. Returns the resulting
  /// entitlement. Throws [PurchaseCancelledException] if the user cancels, or a
  /// [StoreException] if the store is unavailable / the product is missing (in
  /// release; debug falls back to the dev token).
  Future<EntitlementResult> purchase(String productId) async {
    if (!await _iap.isAvailable()) {
      if (kDebugMode) return _verifyDev(productId);
      throw const StoreException('The store is unavailable right now.');
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      if (kDebugMode) return _verifyDev(productId);
      throw const StoreException('That plan isn’t available right now.');
    }

    final token = await _buyAndAwaitToken(response.productDetails.first);
    return _billing.verify(
      platform: _platform,
      productId: productId,
      purchaseToken: token,
    );
  }

  /// Debug-only fallback so the full flow is exercisable without a store
  /// listing. The backend honours `dev-token` only when `BILLING_DEV_BYPASS` is
  /// on, so this can never grant premium in production.
  Future<EntitlementResult> _verifyDev(String productId) {
    return _billing.verify(
      platform: _platform,
      productId: productId,
      purchaseToken: 'dev-token',
    );
  }

  /// Re-sync entitlement from past purchases. Used by the "Restore" action.
  Future<void> restore() async {
    if (!await _iap.isAvailable()) return;
    await _iap.restorePurchases();
  }

  /// Open the platform's subscription-management surface so the user can
  /// upgrade / downgrade / cancel. Lifetime is non-renewing so this is mainly
  /// for the monthly / yearly subscriptions.
  Future<void> openManageSubscription({String? productId}) async {
    final Uri uri;
    if (Platform.isIOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      uri = Uri.https('play.google.com', '/store/account/subscriptions', {
        'sku': ?productId,
        'package': _androidPackage,
      });
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const StoreException('Couldn’t open subscription settings.');
    }
  }

  Future<String> _buyAndAwaitToken(ProductDetails product) async {
    final completer = Completer<String>();
    late final StreamSubscription<List<PurchaseDetails>> sub;

    sub = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != product.id) continue;

        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final token = purchase.verificationData.serverVerificationData;
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            if (!completer.isCompleted) completer.complete(token);
            await sub.cancel();
          case PurchaseStatus.error:
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            if (!completer.isCompleted) {
              completer.completeError(
                purchase.error ??
                    const StoreException('The purchase couldn’t complete.'),
              );
            }
            await sub.cancel();
          case PurchaseStatus.canceled:
            if (!completer.isCompleted) {
              completer.completeError(const PurchaseCancelledException());
            }
            await sub.cancel();
          case PurchaseStatus.pending:
            // Deferred / awaiting approval (e.g. Ask-to-Buy). Keep waiting; the
            // stream delivers a terminal event when the state resolves.
            break;
        }
      }
    });

    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    return completer.future;
  }
}

class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();
  @override
  String toString() => 'Purchase cancelled';
}

/// A recoverable store/billing problem worth surfacing to the user.
class StoreException implements Exception {
  const StoreException(this.message);
  final String message;
  @override
  String toString() => message;
}
