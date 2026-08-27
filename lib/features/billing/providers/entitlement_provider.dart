import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/billing/data/billing_repository.dart';
import 'package:atlas_flutter_app/features/billing/data/entitlements.dart';
import 'package:atlas_flutter_app/features/billing/data/store_offer.dart';
import 'package:atlas_flutter_app/features/billing/services/entitlement_service.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

// ─── Services ───────────────────────────────────────────────────────

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.read(apiServiceProvider));
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  final service = EntitlementService(ref.read(billingRepositoryProvider));

  // Tag every purchase with the backend user id. On Android this becomes Play
  // Billing's obfuscatedAccountId, which Google echoes back to our RTDN webhook —
  // the only way to credit a deferred payment that clears while the app is closed.
  service.setUserIdGetter(() => ref.read(authProvider).user?.id);

  // One long-lived listener owns every store event, including restores and
  // purchases that completed elsewhere.
  unawaited(service.start());

  // Any verification that lands WITHOUT a purchase() call awaiting it — a
  // restore, a purchase made on another device, a deferred payment that cleared
  // while the app was closed, a queued retry that finally went through — has to
  // push the new entitlement into the app itself. Nothing else would, so premium
  // would otherwise stay invisible until the next app resume.
  final verified = service.onVerified.listen((_) async {
    await ref.read(authProvider.notifier).refreshUser();
    await ref.read(entitlementsProvider.notifier).refresh();
  });

  ref.onDispose(() {
    verified.cancel();
    service.dispose();
  });
  return service;
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

/// Whether premium is currently running on a free trial.
final isOnTrialProvider = Provider<bool>((ref) {
  final ent = ref.watch(entitlementsProvider).entitlements;
  return ent != null && ent.effectiveIsPremium && ent.isTrial;
});

/// Whole days left in the free trial, or null when not on one.
final trialDaysRemainingProvider = Provider<int?>((ref) {
  return ref.watch(entitlementsProvider).entitlements?.trialDaysRemaining;
});

/// Buyable plans, keyed by product id, with the trial each user is actually
/// eligible for. Empty during development when no store listing exists yet.
///
/// Combines two sources because neither is sufficient alone: the store knows the
/// trial's length and price, and on iOS only the server knows whether this user may
/// still start one.
final offersProvider = FutureProvider<Map<String, AtlasOffer>>((ref) async {
  // Watch only the two fields that change the answer — watching the whole snapshot
  // would re-query the store on every routine entitlement refresh.
  final eligible = ref.watch(
      entitlementsProvider.select((s) => s.entitlements?.trialEligible));
  final confirmed = ref.watch(
      entitlementsProvider.select((s) => s.entitlements?.trialEligibilityConfirmed ?? false));

  final offers = await ref.read(entitlementServiceProvider).loadOffers();

  return offers.map((id, offer) => MapEntry(
        id,
        offer.withServerEligibility(eligible: eligible, confirmed: confirmed),
      ));
});

/// The longest free trial this user can still start, or 0 when they can't.
///
/// Reads the resolved offers rather than a constant on purpose: on Android Play
/// omits offers a user has consumed, and on iOS the server's eligibility check has
/// already been folded in — so a returning subscriber is never promised a second
/// free trial. 0 while the store is still answering, so upsell copy defaults to the
/// honest version.
final availableTrialDaysProvider = Provider<int>((ref) {
  final offers = ref.watch(offersProvider).value;
  if (offers == null || offers.isEmpty) return 0;
  return offers.values.fold(0, (best, o) => o.trialDays > best ? o.trialDays : best);
});

// ─── Purchase controller ────────────────────────────────────────────

final entitlementControllerProvider =
    Provider<EntitlementController>((ref) => EntitlementController(ref));

class EntitlementController {
  EntitlementController(this._ref);
  final Ref _ref;

  /// Buy a plan, then refresh the user + entitlement snapshot so the derived
  /// providers reflect the new access. Returns the backend-verified entitlement.
  /// Throws on cancel/failure so the UI can surface it.
  ///
  /// [offer] is null only when the store returned nothing for this product — in a
  /// debug build that falls back to the dev token so the paywall is still
  /// exercisable, and in release it's surfaced as a store error rather than
  /// silently faking a purchase.
  Future<EntitlementResult> purchase(String productId, {AtlasOffer? offer}) async {
    final service = _ref.read(entitlementServiceProvider);

    final EntitlementResult result;
    if (offer != null) {
      result = await service.purchase(offer);
    } else if (EntitlementService.devFallbackAllowed) {
      result = await service.purchaseDevFallback(productId);
    } else {
      throw const StoreException('That plan isn’t available right now.');
    }

    await _ref.read(authProvider.notifier).refreshUser();
    await _ref.read(entitlementsProvider.notifier).refresh();
    return result;
  }

  /// Replay past purchases. Returns whether the store handed anything back, which
  /// is NOT the same question as "is this user premium now" — a restored
  /// subscription can be expired. The caller decides what to say about each.
  Future<bool> restore() async {
    final restored = await _ref.read(entitlementServiceProvider).restore();
    await _ref.read(authProvider.notifier).refreshUser();
    await _ref.read(entitlementsProvider.notifier).refresh();
    return restored;
  }

  /// Called on app resume: clears a stuck spinner when the Android billing sheet
  /// closed without emitting an event, and retries any queued verification.
  void onAppResumed() =>
      _ref.read(entitlementServiceProvider).notifyAppResumed();

  /// Open the platform's subscription-management page (Play / App Store).
  Future<void> manageSubscription({String? productId}) {
    return _ref
        .read(entitlementServiceProvider)
        .openManageSubscription(productId: productId);
  }
}
