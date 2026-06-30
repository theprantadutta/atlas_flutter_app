import 'package:atlas_flutter_app/data/services/api_service.dart';

/// The entitlement the backend reports after verifying a purchase (or via
/// `/auth/me`). Mirrors the backend `EntitlementDto` (snake_case on the wire).
class EntitlementResult {
  const EntitlementResult({
    required this.isPremium,
    this.premiumUntil,
    this.isLifetime = false,
  });

  final bool isPremium;
  final DateTime? premiumUntil;
  final bool isLifetime;

  factory EntitlementResult.fromJson(Map<String, dynamic> json) {
    final until = json['premium_until'] as String?;
    return EntitlementResult(
      isPremium: json['is_premium'] == true,
      premiumUntil: until == null ? null : DateTime.tryParse(until),
      isLifetime: json['is_lifetime'] == true,
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
}
