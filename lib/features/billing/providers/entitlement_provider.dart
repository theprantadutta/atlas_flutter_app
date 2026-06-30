import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/billing/data/billing_repository.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

// ─── Services ───────────────────────────────────────────────────────

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.read(apiServiceProvider));
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.read(billingRepositoryProvider));
});

// ─── Entitlement state ──────────────────────────────────────────────

/// The single source of truth for premium access, derived from the
/// backend-issued user profile (`/auth/me`). Purchases update the backend, then
/// [AuthNotifier.refreshUser] refreshes this.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((s) => s.user?.isPremium ?? false));
});

/// Available store products (for the paywall). Empty during development when
/// no store listing exists yet.
final productsProvider = FutureProvider<List<ProductDetails>>((ref) {
  return ref.read(entitlementServiceProvider).loadProducts();
});

// ─── Purchase controller ────────────────────────────────────────────

final entitlementControllerProvider =
    Provider<EntitlementController>((ref) => EntitlementController(ref));

class EntitlementController {
  EntitlementController(this._ref);
  final Ref _ref;

  /// Buy a product, then refresh the user so [isPremiumProvider] reflects the
  /// new entitlement. Throws on cancel/failure so the UI can surface it.
  Future<void> purchase(String productId) async {
    await _ref.read(entitlementServiceProvider).purchase(productId);
    await _ref.read(authProvider.notifier).refreshUser();
  }

  Future<void> restore() async {
    await _ref.read(entitlementServiceProvider).restore();
    await _ref.read(authProvider.notifier).refreshUser();
  }
}
