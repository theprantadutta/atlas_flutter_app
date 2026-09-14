import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/features/billing/data/billing_repository.dart';
import 'package:atlas_flutter_app/features/billing/data/purchase_mapping.dart';
import 'package:atlas_flutter_app/features/billing/data/store_offer.dart';

final _log = AppLog('Billing');

/// Product identifiers — must match the IDs created in Play Console / App Store
/// Connect *and* the backend's accepted product IDs.
class AtlasProducts {
  AtlasProducts._();

  static const monthly = 'atlas_aurora_monthly';
  static const yearly = 'atlas_aurora_yearly';
  static const lifetime = 'atlas_founder_lifetime';

  static const Set<String> all = {monthly, yearly, lifetime};

  /// The auto-renewing plans. The lifetime unlock is a one-time product, which
  /// the store queries and purchases through a different path entirely.
  static const Set<String> subscriptions = {monthly, yearly};

  static bool isSubscription(String productId) =>
      subscriptions.contains(productId);

  /// Free-trial lengths as configured in the stores. These are only a FALLBACK
  /// for copy shown before the store's own offer data arrives — the live
  /// [AtlasOffer.trialDays] is authoritative, because it reflects whether this
  /// particular user is still eligible. Never promise a trial from these alone.
  static const declaredTrialDays = <String, int>{
    monthly: 3,
    yearly: 7,
  };
}

/// Android application id — used to deep-link into Play's subscription screen.
const _androidPackage = 'com.pranta.atlas';

/// Wraps `flutter_inapp_purchase` (OpenIAP) and the backend verify flow.
///
/// Everything funnels through ONE pair of long-lived listeners started at
/// [start]. That matters more than it looks: the store delivers purchases
/// completed on another device and deferred payments that cleared while the app
/// was closed — none of which are tied to a buy the user just tapped.
///
/// Restores no longer arrive that way. Under the old plugin they were replayed
/// on the purchase stream; OpenIAP returns them from [getAvailablePurchases]
/// instead, so [restore] and [reconcileStoreState] ask for them directly.
///
/// Dev path: when the store is unavailable or the product isn't configured yet,
/// fall back to a dev token — but ONLY in debug builds, and the backend honours
/// it only when `BILLING_DEV_BYPASS` is on.
class EntitlementService {
  EntitlementService(this._billing);

  final BillingRepository _billing;
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  StreamSubscription<Purchase>? _purchaseSub;
  StreamSubscription<PurchaseError>? _errorSub;
  bool _started = false;
  bool _connected = false;

  /// Fires whenever the store hands us a purchase this account owns. Carries the
  /// backend result for a fresh verification, or null when we'd already verified
  /// that transaction this session.
  final _owned = StreamController<EntitlementResult?>.broadcast();

  /// Backend-verified entitlements, for listeners that want to re-fetch state.
  Stream<EntitlementResult> get onVerified =>
      _owned.stream.where((r) => r != null).cast<EntitlementResult>();

  /// Resolves the signed-in backend user id. Tagged onto every purchase so the
  /// Play RTDN webhook can map an orphaned token back to this account.
  String? Function()? _userIdGetter;

  /// Buys awaiting a terminal store event, keyed by product id.
  final Map<String, Completer<EntitlementResult>> _pending = {};

  /// Products whose billing sheet was launched but which have produced no store
  /// event yet — see [notifyAppResumed].
  final Set<String> _inFlight = {};
  Timer? _cancelWatchdog;

  /// Purchase identities already verified, so a replay doesn't re-hit the API.
  final Set<String> _verifiedPurchaseIds = {};

  /// Purchases being fulfilled right now.
  ///
  /// Closing the billing sheet IS an app resume, so the listener event and the
  /// resume reconcile see the same fresh purchase within a second of each
  /// other. Without this they both verify it, and the backend's unique index on
  /// (platform, transaction) turns the loser into a 500.
  final Set<String> _fulfilling = {};

  /// A genuine purchase often lands a beat after the app resumes from the
  /// billing sheet, so wait this long before calling a silent return a cancel.
  static const _resumeCancelGrace = Duration(seconds: 3);

  /// Purchases whose backend verification failed for a retryable reason.
  static const _pendingVerificationsKey = 'billing_pending_verifications';

  /// Must match the backend validator keys exactly. macOS is grouped with iOS
  /// because both are validated as App Store transactions.
  String get _platform => Platform.isIOS || Platform.isMacOS ? 'ios' : 'android';

  /// Wire the backend user id getter. On Android it becomes Play Billing's
  /// `obfuscatedAccountId`, which Google echoes back to our RTDN webhook as
  /// `obfuscatedExternalAccountId`. Without it, a deferred payment (carrier
  /// billing, bank transfer) that clears while the app is closed produces a
  /// notification for a purchase token no ledger row has ever seen — and the
  /// user never gets the premium they paid for. On iOS it maps to
  /// `appAccountToken`, which must be a UUID or the plugin throws.
  void setUserIdGetter(String? Function() getUserId) {
    _userIdGetter = getUserId;
  }

  /// Begin listening for store events. Idempotent.
  ///
  /// Both listeners are attached BEFORE the connection opens, or a store that
  /// replays something immediately delivers it to nobody.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _purchaseSub = _iap.purchaseUpdatedListener.listen(
      (purchase) => unawaited(_onPurchase(purchase)),
      onError: (Object e, StackTrace st) =>
          _log.e('Purchase stream error', error: e, stackTrace: st),
    );
    _errorSub = _iap.purchaseErrorListener.listen(_onPurchaseError);

    try {
      _connected = await _iap.initConnection();
      if (!_connected) _log.i('Store unavailable; billing is disabled.');
    } catch (e) {
      // A device with no Play Services, or a simulator with no store account.
      // Not fatal: the app runs, premium simply cannot be bought here.
      _connected = false;
      _log.w('Could not connect to the store: $e');
    }
  }

  void dispose() {
    _cancelWatchdog?.cancel();
    _purchaseSub?.cancel();
    _errorSub?.cancel();
    _owned.close();
    if (_connected) unawaited(_iap.endConnection());
    _connected = false;
    _started = false;
  }

  /// Whether a real store purchase is possible right now. The paywall uses this
  /// to decide between a real buy and the debug fallback.
  Future<bool> get isStoreAvailable async {
    await start();
    return _connected;
  }

  // ─── Products ─────────────────────────────────────────────────────

  /// Store offers for the paywall, collapsed to one per plan with the trial the
  /// user is actually eligible for. Empty when the store is unavailable or the
  /// products aren't configured yet.
  Future<Map<String, AtlasOffer>> loadOffers() async {
    await start();
    if (!_connected) return const {};

    // Two calls, not one: the store keeps subscriptions and one-time products
    // in separate catalogues and asking the wrong one returns nothing.
    final products = <ProductCommon>[];
    try {
      products.addAll(await _iap.fetchProducts<ProductSubscription>(
        skus: AtlasProducts.subscriptions.toList(),
        type: ProductQueryType.Subs,
      ));
    } catch (e) {
      _log.w('Could not load subscriptions from the store: $e');
    }
    try {
      products.addAll(await _iap.fetchProducts<Product>(
        skus: const [AtlasProducts.lifetime],
        type: ProductQueryType.InApp,
      ));
    } catch (e) {
      _log.w('Could not load the lifetime product from the store: $e');
    }

    final found = products.map((p) => p.id).toSet();
    final missing = AtlasProducts.all.difference(found);
    if (missing.isNotEmpty) {
      _log.w('Products missing from the store: $missing');
    }

    final offers = resolveOffers(products);
    _reportTrialMismatches(offers);
    return offers;
  }

  /// Warn when the store grants a shorter trial than the one configured for a
  /// product, or none at all.
  ///
  /// The paywall only ever promises what the store confirms, because a trial the
  /// store will not honour turns "start your free trial" into an immediate
  /// charge. That is the right policy, but on its own it fails silently: an
  /// offer that is inactive, still propagating, attached to the wrong base plan,
  /// or filtered out because this account is not eligible all look identical to
  /// a product that never had a trial. This is the only place the two can be
  /// compared, so it is the only place that difference can be noticed.
  void _reportTrialMismatches(Map<String, AtlasOffer> offers) {
    AtlasProducts.declaredTrialDays.forEach((productId, declared) {
      final offer = offers[productId];
      if (offer == null) return;
      if (offer.trialDays >= declared) return;

      _log.w(
        'Store trial for $productId is ${offer.trialDays} day(s), but $declared '
        'is configured. The paywall will show what the store returned. Usual '
        'causes: the offer is not Active, it has not propagated yet, it is on a '
        'different base plan, or this account is not eligible for it.',
      );
    });
  }

  // ─── Buying ───────────────────────────────────────────────────────

  /// Buy [offer] and verify it with the backend. Returns the resulting
  /// entitlement.
  ///
  /// Throws [PurchaseCancelledException] if the user backs out, or
  /// [StoreException] when the store itself refuses. Pass [replacing] to switch
  /// plans rather than start a second subscription, which Play rejects as
  /// already owned; [replacementMode] decides the billing.
  Future<EntitlementResult> purchase(
    AtlasOffer offer, {
    OwnedSubscription? replacing,
    SubscriptionReplacementModeAndroid? replacementMode,
  }) async {
    await start();

    final productId = offer.productId;
    final completer = Completer<EntitlementResult>();
    _pending[productId] = completer;

    try {
      final request = buildPurchaseRequest(
        product: offer.product,
        isSubscription: AtlasProducts.isSubscription(productId),
        accountId: _userIdGetter?.call(),
        replacing: replacing,
        replacementMode: replacementMode,
      );

      // The outcome never comes back from this call: it arrives on the
      // listeners, which is why the completer exists.
      await _iap.requestPurchase(request);

      _inFlight.add(productId);
      return await completer.future;
    } catch (e) {
      _pending.remove(productId);
      _inFlight.remove(productId);
      if (e is PurchaseCancelledException ||
          e is PurchasePendingException ||
          e is PurchaseNotYetVerifiedException ||
          e is StoreException) {
        rethrow;
      }
      throw StoreException('The store couldn’t start that purchase.');
    } finally {
      _pending.remove(productId);
      _inFlight.remove(productId);
    }
  }

  /// Debug-only fallback so the full flow is exercisable without a store listing.
  Future<EntitlementResult> purchaseDevFallback(String productId) {
    return _billing.verify(
      platform: _platform,
      productId: productId,
      purchaseToken: 'dev-token',
    );
  }

  // ─── Owned purchases ──────────────────────────────────────────────

  /// Re-sync entitlement from what this account owns. Returns whether the store
  /// handed back anything at all.
  ///
  /// Under the old plugin a restore replayed purchases on the stream, so this
  /// had to subscribe and race a timeout. OpenIAP returns them directly, which
  /// removes both the race and the "we waited long enough, you must not have
  /// bought anything" failure mode.
  Future<bool> restore() async {
    await start();
    if (!_connected) {
      throw const StoreException('The store is unavailable right now.');
    }

    try {
      // iOS only in substance: an AppStore.sync that may prompt for the Apple
      // ID password. Android owns everything locally already.
      await _iap.restorePurchases();
    } catch (e) {
      _log.w('Store sync before restore failed: $e');
    }

    return _reconcile(announceEmpty: true);
  }

  /// Verify anything the store says this account owns.
  ///
  /// Called once after sign-in and on every resume. This is what catches a
  /// purchase completed on another device, a deferred payment that cleared
  /// while the app was closed, and a verification that failed the first time.
  Future<void> reconcileStoreState() async {
    if (!_started) return;
    if (!_connected) return;
    await _reconcile(announceEmpty: false);
  }

  Future<bool> _reconcile({required bool announceEmpty}) async {
    final List<Purchase> owned;
    try {
      owned = await _iap.getAvailablePurchases();
    } catch (e) {
      _log.w('Could not read owned purchases: $e');
      throw const StoreException('Couldn’t reach the store right now.');
    }

    var found = false;
    for (final purchase in owned) {
      if (purchase.purchaseState != PurchaseState.Purchased) continue;
      found = true;
      await _fulfil(purchase);
    }

    // A second "Restore" tap must not report "no previous purchase found" just
    // because everything was already verified this session.
    if (!found && announceEmpty) _emitOwned(null);
    return found;
  }

  /// The subscription this account currently holds, or null.
  ///
  /// Read from the store rather than from our own state: a plan change needs
  /// the token Play issued, and only the store knows which base plan is live.
  Future<OwnedSubscription?> currentSubscription() async {
    await start();
    if (!_connected) return null;

    try {
      final active = await _iap.getActiveSubscriptions(
        AtlasProducts.subscriptions.toList(),
      );
      for (final sub in active) {
        if (!sub.isActive) continue;
        return OwnedSubscription(
          productId: sub.productId,
          purchaseToken: sub.purchaseTokenAndroid ?? sub.purchaseToken,
        );
      }
    } catch (e) {
      _log.w('Could not read the current subscription: $e');
    }
    return null;
  }

  /// Open the platform's subscription-management surface so the user can
  /// upgrade, downgrade or cancel.
  Future<void> openManageSubscription({String? productId}) async {
    try {
      await _iap.deepLinkToSubscriptions(
        skuAndroid: productId,
        packageNameAndroid: _androidPackage,
      );
    } catch (e) {
      _log.w('Could not open subscription settings: $e');
      throw const StoreException('Couldn’t open subscription settings.');
    }
  }

  // ─── Store events ─────────────────────────────────────────────────

  Future<void> _onPurchase(Purchase purchase) async {
    // Any event means the billing flow produced a signal, so this product is no
    // longer a silent-cancel candidate.
    _inFlight.remove(purchase.productId);

    switch (purchase.purchaseState) {
      case PurchaseState.Pending:
        // Deferred payment (carrier billing, bank transfer) or Ask-to-Buy.
        // Nothing is owed yet and no terminal event may arrive for DAYS, so the
        // caller has to be released — leaving it awaiting would pin the paywall
        // on "Please wait…" until the app is force-quit. Nothing is granted and
        // NOTHING is finished: finishing a pending purchase would tell the store
        // we delivered something that has not been paid for. When it clears,
        // Play sends an RTDN and the backend grants premium even if the app is
        // never reopened.
        _log.i('Purchase pending for ${purchase.productId}');
        _fail(purchase.productId, const PurchasePendingException());

      case PurchaseState.Purchased:
        await _fulfil(purchase);

      case PurchaseState.Unknown:
        _log.w('Store reported an unknown state for ${purchase.productId}');
        _fail(
          purchase.productId,
          const StoreException('The purchase couldn’t complete.'),
        );
    }
  }

  void _onPurchaseError(PurchaseError error) {
    final productId = error.productId;
    _log.i('Store reported ${error.code?.name ?? 'an error'}: ${error.message}');

    // A cancel is not a failure worth showing; every other code is.
    final failure = error.code == ErrorCode.UserCancelled
        ? const PurchaseCancelledException()
        : StoreException(_messageFor(error));

    if (productId != null) {
      _inFlight.remove(productId);
      _fail(productId, failure);
      return;
    }

    // No product id: fail everything waiting, or the paywall spins forever.
    for (final id in _pending.keys.toList()) {
      _inFlight.remove(id);
      _fail(id, failure);
    }
  }

  String _messageFor(PurchaseError error) => switch (error.code) {
        ErrorCode.NetworkError =>
          'The store couldn’t be reached. Check your connection and try again.',
        ErrorCode.ItemUnavailable => 'That plan isn’t available right now.',
        ErrorCode.AlreadyOwned => 'You already own this.',
        ErrorCode.DeferredPayment => 'Your purchase is awaiting approval.',
        _ => 'The purchase couldn’t complete.',
      };

  /// Verify a purchase with the backend, then tell the store it was delivered.
  Future<void> _fulfil(Purchase purchase) async {
    final identity = purchaseIdentity(purchase);

    // The listener and the resume reconcile race for the same fresh purchase.
    if (identity != null && !_fulfilling.add(identity)) return;

    try {
      if (identity != null && _verifiedPurchaseIds.contains(identity)) {
        // Everything owned comes back on every query; verifying the same
        // transaction again would just burn requests. Still announce it, so a
        // second "Restore" tap doesn't report "no previous purchase found".
        await _finish(purchase);
        _emitOwned(null);
        return;
      }

      final payload = backendPayloadFor(purchase);
      if (payload == null) {
        _log.w('Purchase for ${purchase.productId} carries no token to verify.');
        _fail(
          purchase.productId,
          const StoreException('The store didn’t return a usable receipt.'),
        );
        return;
      }

      final EntitlementResult result;
      try {
        result = await _billing.verify(
          platform: payload.platform,
          productId: payload.productId,
          purchaseToken: payload.purchaseToken,
        );
      } catch (e) {
        await _handleVerifyFailure(purchase, payload, e);
        return;
      }

      if (identity != null) _verifiedPurchaseIds.add(identity);
      await _finish(purchase);
      _emitOwned(result);
      _succeed(purchase.productId, result);
    } finally {
      if (identity != null) _fulfilling.remove(identity);
    }
  }

  Future<void> _handleVerifyFailure(
    Purchase purchase,
    BackendPurchasePayload payload,
    Object error,
  ) async {
    switch (classifyVerifyFailure(error)) {
      case VerifyOutcome.transient:
        // The money HAS moved. Finish anyway: an unacknowledged Android
        // purchase is auto-refunded after three days, which is far worse than a
        // verification we can retry on the next resume.
        await _queueForRetry(payload);
        await _finish(purchase);
        _log.w('Verification failed for ${purchase.productId}; queued for retry.');
        // Surfacing a raw server error here reads as "your payment failed",
        // which is both wrong and alarming.
        _fail(purchase.productId, const PurchaseNotYetVerifiedException());

      case VerifyOutcome.rejected:
        // The store's own answer was no. On Android, deliberately do NOT
        // finish: Play reverses an unacknowledged purchase after three days,
        // which is the correct outcome for something we will never grant. iOS
        // has no such reversal and replays unfinished transactions forever, so
        // there it must be finished to stop it coming back every launch.
        _log.e('Verification rejected for ${purchase.productId}', error: error);
        if (purchase is PurchaseIOS) await _finish(purchase);
        _fail(purchase.productId, error);
    }
  }

  void _emitOwned(EntitlementResult? result) {
    if (!_owned.isClosed) _owned.add(result);
  }

  /// Tell the store the purchase has been delivered. Mandatory on Android
  /// within three days or Play reverses the charge.
  Future<void> _finish(Purchase purchase) async {
    // Every Atlas product is owned rather than spent: subscriptions and the
    // lifetime unlock are both non-consumable, so this acknowledges and never
    // consumes. Consuming the lifetime unlock would let it be bought twice.
    if (purchase is PurchaseAndroid && purchase.isAcknowledgedAndroid == true) {
      return;
    }
    try {
      await _iap.finishTransaction(purchase: purchase, isConsumable: false);
    } catch (e) {
      _log.e('finishTransaction failed for ${purchase.productId}', error: e);
    }
  }

  void _succeed(String productId, EntitlementResult result) {
    final completer = _pending.remove(productId);
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  void _fail(String productId, Object error) {
    final completer = _pending.remove(productId);
    if (completer != null && !completer.isCompleted) completer.completeError(error);
  }

  // ─── Silent-cancel detection ──────────────────────────────────────

  /// Called when the app returns to the foreground.
  ///
  /// On Android, backing out of the Play billing sheet still sometimes emits no
  /// event at all. Without this, the paywall's "Please wait…" spinner stays up
  /// forever and the user has to force-quit. After a short grace window — so a
  /// real purchase landing just after resume still wins — anything still in
  /// flight is treated as cancelled. A late store event is still processed
  /// normally, so nothing is lost.
  void notifyAppResumed() {
    unawaited(retryPendingVerifications());
    // Closing the billing sheet is itself a resume, so this is also how a
    // purchase that produced no listener event still gets delivered.
    unawaited(reconcileStoreState());

    if (_inFlight.isEmpty) return;
    _cancelWatchdog?.cancel();
    _cancelWatchdog = Timer(_resumeCancelGrace, () {
      final abandoned = _inFlight.toList();
      _inFlight.clear();
      for (final productId in abandoned) {
        _log.i('Billing sheet returned with no event for $productId — treating as cancelled');
        _fail(productId, const PurchaseCancelledException());
      }
    });
  }

  // ─── Offline retry queue ──────────────────────────────────────────

  Future<void> _queueForRetry(BackendPurchasePayload payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_pendingVerificationsKey) ?? [];

      final entry = jsonEncode({
        ...payload.toJson(),
        'queued_at': DateTime.now().toIso8601String(),
      });

      // Same shape the old plugin queued, so an entry written before this
      // migration still parses and is still retried.
      if (queue.any((raw) => _sameReceipt(raw, payload))) return;
      queue.add(entry);
      await prefs.setStringList(_pendingVerificationsKey, queue);
    } catch (e) {
      _log.e('Could not queue purchase for retry', error: e);
    }
  }

  static bool _sameReceipt(String raw, BackendPurchasePayload payload) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json['purchase_token'] == payload.purchaseToken &&
          json['product_id'] == payload.productId;
    } catch (_) {
      return false;
    }
  }

  /// Retry queued verifications. Safe to call often — a no-op when the queue is
  /// empty. Entries that succeed, or that the backend conclusively rejects, are
  /// dropped; everything else stays for the next attempt.
  Future<void> retryPendingVerifications() async {
    List<String> queue;
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      queue = prefs.getStringList(_pendingVerificationsKey) ?? [];
    } catch (_) {
      return;
    }
    if (queue.isEmpty) return;

    _log.i('Retrying ${queue.length} pending purchase verification(s)');
    final remaining = <String>[];

    for (final raw in queue) {
      BackendPurchasePayload? payload;
      try {
        payload = BackendPurchasePayload.fromQueueEntry(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        continue; // Unparseable — drop it rather than retry forever.
      }
      if (payload == null) continue;

      try {
        final result = await _billing.verify(
          platform: payload.platform,
          productId: payload.productId,
          purchaseToken: payload.purchaseToken,
        );
        // Announce it: this is a grant the user has been waiting on since the
        // verification first failed, and nothing else would refresh their state.
        _emitOwned(result);
      } catch (e) {
        if (classifyVerifyFailure(e) == VerifyOutcome.transient) {
          remaining.add(raw);
        }
      }
    }

    try {
      if (remaining.isEmpty) {
        await prefs.remove(_pendingVerificationsKey);
      } else {
        await prefs.setStringList(_pendingVerificationsKey, remaining);
      }
    } catch (_) {/* best-effort */}
  }

  /// Whether the debug store fallback may be used. Release builds must never
  /// fake a purchase, so this is compile-time gated.
  static bool get devFallbackAllowed => kDebugMode;
}

class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();
  @override
  String toString() => 'Purchase cancelled';
}

/// The store accepted the purchase but hasn't taken payment yet — a deferred
/// method (carrier billing, bank transfer) or an Ask-to-Buy approval. Nothing is
/// owed and nothing is granted; when it clears, Play's RTDN grants premium
/// server-side even if the app never reopens.
class PurchasePendingException implements Exception {
  const PurchasePendingException();
  @override
  String toString() => 'Purchase pending approval';
}

/// Payment went through, but our backend couldn't confirm it right now. The
/// purchase is queued and retried on resume — this is emphatically NOT a failed
/// payment, and must never be shown to the user as one.
class PurchaseNotYetVerifiedException implements Exception {
  const PurchaseNotYetVerifiedException();
  @override
  String toString() => 'Purchase awaiting verification';
}

/// A recoverable store/billing problem worth surfacing to the user.
class StoreException implements Exception {
  const StoreException(this.message);
  final String message;
  @override
  String toString() => message;
}
