import 'dart:io' show Platform;

import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/features/billing/data/entitlements.dart';

/// The entitlement the backend reports after verifying a purchase (or via
/// `/auth/me`). Mirrors the backend `EntitlementDto` (snake_case on the wire).
class EntitlementResult {
  const EntitlementResult({
    required this.isPremium,
    this.premiumUntil,
    this.isLifetime = false,
    this.isTrial = false,
  });

  final bool isPremium;
  final DateTime? premiumUntil;
  final bool isLifetime;

  /// True when the purchase that just unlocked premium started on its free
  /// trial, so the confirmation can say so instead of implying a charge.
  final bool isTrial;

  factory EntitlementResult.fromJson(Map<String, dynamic> json) {
    final until = json['premium_until'] as String?;
    return EntitlementResult(
      isPremium: json['is_premium'] == true,
      premiumUntil: until == null ? null : DateTime.tryParse(until),
      isLifetime: json['is_lifetime'] == true,
      isTrial: json['is_trial'] == true,
    );
  }
}

/// Talks to the backend billing endpoints. The store receipt/token is validated
/// server-side — the app never decides entitlement on its own.
class BillingRepository {
  BillingRepository(this._api);

  final ApiService _api;

  /// Verify a store purchase with the backend, which sets the user's
  /// entitlement and returns the resulting premium state.
  Future<EntitlementResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
  }) async {
    final res = await _api.post(
      '/billing/verify',
      data: {
        'platform': platform,
        'product_id': productId,
        'purchase_token': purchaseToken,
      },
    );
    return EntitlementResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Fetch the full entitlement snapshot (premium state + feature flags + Aurora
  /// usage) from the server-authoritative `GET /entitlements`. The base path
  /// already includes `/api/v1`.
  Future<Entitlements> fetchEntitlements() async {
    // The platform scopes trial eligibility to the store that would actually grant
    // it — a prior Play subscription says nothing about an App Store trial.
    final res = await _api.get(
      '/entitlements',
      queryParameters: {
        'platform': Platform.isIOS || Platform.isMacOS ? 'ios' : 'android',
      },
    );
    return Entitlements.fromJson(res.data as Map<String, dynamic>);
  }
}
