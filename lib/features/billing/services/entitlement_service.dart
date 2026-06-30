import 'dart:async';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';

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

/// Wraps `in_app_purchase` and the backend verify flow.
///
/// Real purchase path: query the store → buy → on a `purchased`/`restored`
/// event take the server verification token → backend `/billing/verify`.
///
/// Dev path: when the store is unavailable or the product isn't configured yet
/// (no store listing during development), fall back to a dev token. The backend
/// honours it only when `BILLING_DEV_BYPASS` is on, so this is safe in prod.
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
  /// entitlement. Throws if the user cancels or the store/verify fails.
  Future<EntitlementResult> purchase(String productId) async {
    var purchaseToken = 'dev-token';

    try {
      if (await _iap.isAvailable()) {
        final response = await _iap.queryProductDetails({productId});
        if (response.productDetails.isNotEmpty) {
          purchaseToken = await _buyAndAwaitToken(response.productDetails.first);
        }
      }
    } on PurchaseCancelledException {
      rethrow;
    } catch (_) {
      // Store path unavailable (dev / no listing yet) — fall through to the
      // backend verify with the dev token.
    }

    return _billing.verify(
      platform: _platform,
      productId: productId,
      purchaseToken: purchaseToken,
    );
  }

  /// Re-sync entitlement from past purchases. Used by the "Restore" action.
  Future<void> restore() async {
    if (!await _iap.isAvailable()) return;
    await _iap.restorePurchases();
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
            if (!completer.isCompleted) {
              completer.completeError(
                purchase.error ?? Exception('Purchase failed'),
              );
            }
            await sub.cancel();
          case PurchaseStatus.canceled:
            if (!completer.isCompleted) {
              completer.completeError(const PurchaseCancelledException());
            }
            await sub.cancel();
          case PurchaseStatus.pending:
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
