import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/billing/data/billing_repository.dart';
import 'package:atlas_flutter_app/features/billing/data/entitlements.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

// ─── Services ───────────────────────────────────────────────────────

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.read(apiServiceProvider));
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.read(billingRepositoryProvider));
});

// ─── Entitlement state (server-authoritative, cached offline) ───────

class EntitlementState {
  const EntitlementState({this.entitlements, this.loading = false});

  final Entitlements? entitlements;
  final bool loading;

  EntitlementState copyWith({Entitlements? entitlements, bool? loading}) {
    return EntitlementState(
      entitlements: entitlements ?? this.entitlements,
      loading: loading ?? this.loading,
    );
  }
}

/// Owns the entitlement snapshot: fetches `/entitlements`, caches it in secure
/// storage (survives offline) and refreshes on login, purchase, each Aurora
/// action and app resume. Reads re-check `premiumUntil` locally (see
/// [Entitlements.effectiveIsPremium]) so a stale cache can't over-grant.
class EntitlementNotifier extends Notifier<EntitlementState> {
  @override
  EntitlementState build() {
    // Refresh whenever the user signs in; clear on sign-out.
    ref.listen(authProvider.select((s) => s.isAuthenticated), (prev, next) {
      if (next == true && prev != true) {
        refresh();
      } else if (next == false && prev == true) {
        _onLoggedOut();
      }
    });
    _init();
    return const EntitlementState(loading: true);
  }

  Future<void> _init() async {
    // Warm from the offline cache first so premium survives a cold, offline
    // start; then refresh from the server if we're authenticated.
    final cached = await _loadCache();
    if (cached != null && state.entitlements == null) {
      state = state.copyWith(entitlements: cached, loading: false);
    }
    if (ref.read(authProvider).isAuthenticated) {
      await refresh();
    } else {
      state = state.copyWith(loading: false);
    }
  }

  /// Re-fetch the entitlement snapshot from the backend. Best-effort: on failure
  /// (offline) the existing cached snapshot is kept.
  Future<void> refresh() async {
    if (!ref.read(authProvider).isAuthenticated) return;
    try {
      final ent = await ref.read(billingRepositoryProvider).fetchEntitlements();
      state = EntitlementState(entitlements: ent, loading: false);
      await _saveCache(ent);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _onLoggedOut() async {
    state = const EntitlementState();
    await ref.read(tokenServiceProvider).clearEntitlements();
  }

  Future<Entitlements?> _loadCache() async {
    try {
      final json = await ref.read(tokenServiceProvider).getEntitlementsJson();
      if (json == null) return null;
      return Entitlements.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(Entitlements ent) async {
    try {
      await ref
          .read(tokenServiceProvider)
          .saveEntitlementsJson(jsonEncode(ent.toJson()));
    } catch (_) {/* best-effort */}
  }
}

final entitlementsProvider =
    NotifierProvider<EntitlementNotifier, EntitlementState>(
        EntitlementNotifier.new);

// ─── Derived providers ──────────────────────────────────────────────

/// The single source of truth for premium access. Prefers the (expiry-aware)
/// entitlement snapshot; falls back to the cached user profile before the first
/// `/entitlements` fetch resolves. Name/behaviour kept for existing callers.
final isPremiumProvider = Provider<bool>((ref) {
  final ent = ref.watch(entitlementsProvider).entitlements;
  if (ent != null) return ent.effectiveIsPremium;
  return ref.watch(authProvider.select((s) => s.user?.isPremium ?? false));
});

/// Aurora usage for the meter — only meaningful for free users. Returns null for
/// premium (unlimited) or before the snapshot loads.
final auroraUsageProvider = Provider<AuroraUsage?>((ref) {
  final ent = ref.watch(entitlementsProvider).entitlements;
  if (ent == null || ent.effectiveIsPremium) return null;
  return ent.aurora;
});

/// Chats remaining this week for a free user, or null when unlimited/unknown.
final remainingChatsProvider = Provider<int?>((ref) {
  return ref.watch(auroraUsageProvider)?.chatRemaining;
});

/// Whether cloud sync is available to this user.
final canSyncProvider = Provider<bool>((ref) {
  final ent = ref.watch(entitlementsProvider).entitlements;
  if (ent == null) return ref.watch(isPremiumProvider);
  return ent.effectiveIsPremium && ent.cloudSync;
});

/// Whether deeper insights & export are available to this user.
final canDeepInsightsProvider = Provider<bool>((ref) {
  final ent = ref.watch(entitlementsProvider).entitlements;
  if (ent == null) return ref.watch(isPremiumProvider);
  return ent.effectiveIsPremium && ent.deepInsights;
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

  /// Buy a product, then refresh the user + entitlement snapshot so the derived
  /// providers reflect the new access. Returns the backend-verified entitlement.
  /// Throws on cancel/failure so the UI can surface it.
  Future<EntitlementResult> purchase(String productId) async {
    final result =
        await _ref.read(entitlementServiceProvider).purchase(productId);
    await _ref.read(authProvider.notifier).refreshUser();
    await _ref.read(entitlementsProvider.notifier).refresh();
    return result;
  }

  Future<void> restore() async {
    await _ref.read(entitlementServiceProvider).restore();
    await _ref.read(authProvider.notifier).refreshUser();
    await _ref.read(entitlementsProvider.notifier).refresh();
  }

  /// Open the platform's subscription-management page (Play / App Store).
  Future<void> manageSubscription({String? productId}) {
    return _ref
        .read(entitlementServiceProvider)
        .openManageSubscription(productId: productId);
  }
}
