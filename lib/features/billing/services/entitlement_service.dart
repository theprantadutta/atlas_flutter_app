import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:in_app_purchase/in_app_purchase.dart';
// Plan switching is Play-specific: the old purchase and the replacement mode
// have no equivalent in the platform-agnostic API.
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/features/billing/data/billing_repository.dart';
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

  /// Free-trial lengths as configured in the stores. These are only a FALLBACK
  /// for copy shown before the store's own offer data arrives — the live
  /// [AtlasOffer.trialDays] is authoritative, because it reflects whether this
  /// particular user is still eligible. Never promise a trial from these alone.
  static const declaredTrialDays = <String, int>{
    monthly: 3,
    yearly: 7,
  };
}

/// Android application id — used to build the Play subscription-management URL.
const _androidPackage = 'com.pranta.atlas';

/// Wraps `in_app_purchase` and the backend verify flow.
///
/// Everything funnels through ONE long-lived `purchaseStream` listener started at
/// [start]. That matters more than it looks: the store delivers restored purchases,
/// purchases completed on another device, and deferred payments that cleared while
/// the app was closed — none of which are tied to a buy the user just tapped. A
/// listener that only exists for the duration of a purchase call misses all of them,
/// which is why "Restore" used to do nothing server-side.
///
/// Dev path: when the store is unavailable or the product isn't configured yet, fall
/// back to a dev token — but ONLY in debug builds, and the backend honours it only
/// when `BILLING_DEV_BYPASS` is on.
class EntitlementService {
  EntitlementService(this._billing);

  final BillingRepository _billing;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _started = false;

  /// Fires whenever the store hands us a purchase this account owns. Carries the
  /// backend result for a fresh verification, or null when we'd already verified
  /// that transaction this session.
  ///
  /// This is the only way an out-of-band grant reaches the UI: a restore, a
  /// purchase that completed on another device, a deferred payment that cleared
  /// while the app was closed, or a queued retry that finally went through all
  /// arrive with no `purchase()` call waiting on them.
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

  /// Purchase ids already verified, so a restore replay doesn't re-hit the API.
  final Set<String> _verifiedPurchaseIds = {};

  /// A genuine `purchased` event often lands a beat after the app resumes from the
  /// billing sheet, so wait this long before calling a silent return a cancel.
  static const _resumeCancelGrace = Duration(seconds: 3);

  /// How long "Restore" waits for the store to replay a purchase before
  /// concluding there isn't one. Generous: it covers a store round-trip plus our
  /// own backend verification, and the cost of being wrong is telling a paying
  /// customer they never bought anything.
  static const _restoreWindow = Duration(seconds: 12);

  /// Purchases whose backend verification failed for a retryable reason.
  static const _pendingVerificationsKey = 'billing_pending_verifications';

  /// Must match the backend validator keys exactly. macOS is grouped with iOS
  /// because both are validated as App Store transactions.
  String get _platform => Platform.isIOS || Platform.isMacOS ? 'ios' : 'android';

  /// Wire the backend user id getter. On Android [PurchaseParam.applicationUserName]
  /// becomes Play Billing's `obfuscatedAccountId`, which Google echoes back to our
  /// RTDN webhook as `obfuscatedExternalAccountId`. Without it, a deferred payment
  /// (carrier billing, bank transfer) that clears while the app is closed produces
  /// a notification for a purchase token no ledger row has ever seen — and the user
  /// never gets the premium they paid for. On iOS it maps to `appAccountToken`.
  void setUserIdGetter(String? Function() getUserId) {
    _userIdGetter = getUserId;
  }

  /// Begin listening for store events. Idempotent.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (!await _iap.isAvailable()) {
      _log.i('Store unavailable; purchase listener not started.');
      return;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onDone: () => _sub?.cancel(),
      onError: (Object e, StackTrace st) =>
          _log.e('Purchase stream error', error: e, stackTrace: st),
    );
  }

  void dispose() {
    _cancelWatchdog?.cancel();
    _sub?.cancel();
    _owned.close();
    _started = false;
  }

  /// Store offers for the paywall, collapsed to one per plan with the trial the
  /// user is actually eligible for. Empty when the store is unavailable or the
  /// products aren't configured yet.
  Future<Map<String, AtlasOffer>> loadOffers() async {
    if (!await _iap.isAvailable()) return const {};
    final response = await _iap.queryProductDetails(AtlasProducts.all);
    if (response.notFoundIDs.isNotEmpty) {
      _log.w('Products missing from the store: ${response.notFoundIDs}');
    }

    final offers = resolveOffers(response.productDetails);
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

  /// Buy [offer] and verify it with the backend. Returns the resulting entitlement.
  /// Throws [PurchaseCancelledException] if the user backs out, or [StoreException]
  /// when the store itself refuses.
  /// Pass [replacing] to switch plans rather than start a new subscription.
  /// [replacementMode] decides the billing: prorated and immediate for an
  /// upgrade, deferred to the next renewal for a downgrade.
  Future<EntitlementResult> purchase(
    AtlasOffer offer, {
    GooglePlayPurchaseDetails? replacing,
    ReplacementMode? replacementMode,
  }) async {
    await start();

    final productId = offer.productId;
    final completer = Completer<EntitlementResult>();
    _pending[productId] = completer;

    try {
      // Tag the purchase with our user id so the RTDN webhook can recover it. Null
      // when unauthenticated — the buy still works, just without webhook recovery.
      // Switching plans is not a fresh purchase: Play needs the subscription
      // being replaced, or it rejects the buy as "already owned".
      final PurchaseParam param;
      if (replacing != null && offer.details is GooglePlayProductDetails) {
        param = GooglePlayPurchaseParam(
          productDetails: offer.details,
          applicationUserName: _userIdGetter?.call(),
          changeSubscriptionParam: ChangeSubscriptionParam(
            oldPurchaseDetails: replacing,
            replacementMode: replacementMode,
          ),
        );
      } else {
        param = PurchaseParam(
          productDetails: offer.details,
          applicationUserName: _userIdGetter?.call(),
        );
      }

      // Every Atlas product is non-consumable: subscriptions and the lifetime
      // unlock are both owned, never spent.
      final launched = await _iap.buyNonConsumable(purchaseParam: param);
      if (!launched) {
        _pending.remove(productId);
        throw const StoreException('The store couldn’t start that purchase.');
      }

      _inFlight.add(productId);
      return await completer.future;
    } finally {
      _pending.remove(productId);
      _inFlight.remove(productId);
    }
  }

  /// The live subscription purchase, when the store has told us about one.
  ///
  /// Play requires the OLD purchase to be named when switching plans, and the
  /// only place that object exists is the purchase stream. Cached from whatever
  /// the stream last reported as owned.
  GooglePlayPurchaseDetails? _ownedSubscription;

  void _rememberSubscription(PurchaseDetails purchase) {
    if (purchase is! GooglePlayPurchaseDetails) return;
    if (purchase.productID == AtlasProducts.lifetime) return;
    if (!AtlasProducts.all.contains(purchase.productID)) return;
    _ownedSubscription = purchase;
  }

  /// The subscription this account currently holds, or null.
  ///
  /// Falls back to a restore, because the stream only speaks when something
  /// happens: on a cold start nothing has been purchased or replayed yet, so
  /// the cache is empty even for a long-standing subscriber.
  Future<GooglePlayPurchaseDetails?> currentSubscription() async {
    if (_ownedSubscription != null) return _ownedSubscription;
    if (!Platform.isAndroid) return null;
    try {
      await restore();
    } catch (e) {
      _log.w('Could not read the current subscription: $e');
    }
    return _ownedSubscription;
  }

  /// Debug-only fallback so the full flow is exercisable without a store listing.
  Future<EntitlementResult> purchaseDevFallback(String productId) {
    return _billing.verify(
      platform: _platform,
      productId: productId,
      purchaseToken: 'dev-token',
    );
  }

  /// Whether a real store purchase is possible right now. The paywall uses this to
  /// decide between a real buy and the debug fallback.
  Future<bool> get isStoreAvailable => _iap.isAvailable();

  /// Re-sync entitlement from past purchases. Returns whether the store actually
  /// handed back something this account owns.
  ///
  /// `restorePurchases()` completes as soon as the platform call is *dispatched* —
  /// the purchases themselves arrive later on `purchaseStream` and still have to
  /// be verified with the backend. Checking entitlement the moment it returns
  /// therefore always reads "not premium yet" and tells a paying user their
  /// purchase doesn't exist. So we subscribe first, kick off the restore, then
  /// wait for the first owned purchase to land.
  Future<bool> restore() async {
    await start();
    if (!await _iap.isAvailable()) {
      throw const StoreException('The store is unavailable right now.');
    }

    // Subscribe BEFORE dispatching, or a fast store can deliver before we listen.
    final restored = _owned.stream.first
        .then((_) => true)
        .timeout(_restoreWindow, onTimeout: () => false);

    // Restores must carry the same account tag as the original buy, or Play has
    // nothing to echo back to the webhook for the replayed purchase.
    await _iap.restorePurchases(applicationUserName: _userIdGetter?.call());

    return restored;
  }

  /// Open the platform's subscription-management surface so the user can
  /// upgrade / downgrade / cancel.
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

  // ─── Store events ─────────────────────────────────────────────────

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // Any event means the billing flow produced a signal, so this product is no
      // longer a silent-cancel candidate.
      _inFlight.remove(purchase.productID);

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Deferred payment (carrier billing, bank transfer) or Ask-to-Buy.
          // Nothing is owed yet and no terminal event may arrive for DAYS, so the
          // caller has to be released — leaving it awaiting would pin the paywall
          // on "Please wait…" until the app is force-quit. The purchase is not
          // lost: when it clears, Play sends an RTDN and the backend grants
          // premium even if the app is never reopened.
          _log.i('Purchase pending for ${purchase.productID}');
          _fail(purchase.productID, const PurchasePendingException());

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleOwned(purchase);

        case PurchaseStatus.error:
          _log.e('Store reported a purchase error', error: purchase.error);
          await _complete(purchase);
          _fail(
            purchase.productID,
            StoreException(purchase.error?.message ??
                'The purchase couldn’t complete.'),
          );

        case PurchaseStatus.canceled:
          await _complete(purchase);
          _fail(purchase.productID, const PurchaseCancelledException());
      }
    }
  }

  Future<void> _handleOwned(PurchaseDetails purchase) async {
    _rememberSubscription(purchase);
    final id = purchase.purchaseID;
    if (id != null && _verifiedPurchaseIds.contains(id)) {
      // A restore replays everything the account owns on every call; verifying the
      // same transaction again would just burn requests. Still announce it, so a
      // second "Restore" tap doesn't report "no previous purchase found".
      await _complete(purchase);
      _emitOwned(null);
      return;
    }

    final EntitlementResult result;
    try {
      result = await _verify(purchase);
      if (id != null) _verifiedPurchaseIds.add(id);
    } catch (e) {
      // Acknowledge regardless of the outcome: leaving a purchase uncompleted
      // makes Play auto-refund it after three days, which is far worse than a
      // failed verification we can retry.
      await _complete(purchase);

      // Retry only what's worth retrying. A 402 means the store itself told the
      // backend this purchase isn't valid — retrying forever won't change that.
      if (_isRetryable(e)) {
        await _queueForRetry(purchase);
        _log.w('Verification failed for ${purchase.productID}; queued for retry.');
        // The user's money HAS moved. Surfacing a raw server error here reads as
        // "your payment failed", which is both wrong and alarming.
        _fail(purchase.productID, const PurchaseNotYetVerifiedException());
      } else {
        _log.e('Verification rejected for ${purchase.productID}', error: e);
        _fail(purchase.productID, e);
      }
      return;
    }

    await _complete(purchase);
    _emitOwned(result);
    _succeed(purchase.productID, result);
  }

  void _emitOwned(EntitlementResult? result) {
    if (!_owned.isClosed) _owned.add(result);
  }

  Future<EntitlementResult> _verify(PurchaseDetails purchase) {
    // On Android `serverVerificationData` IS the Play purchase token; on iOS it is
    // the StoreKit JWS. The backend picks the validator from `platform`.
    return _billing.verify(
      platform: _platform,
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
    );
  }

  /// Tell the store the purchase has been delivered. Mandatory on Android within
  /// three days or Play reverses the charge.
  Future<void> _complete(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(purchase);
    } catch (e) {
      _log.e('completePurchase failed for ${purchase.productID}', error: e);
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
  /// On Android, backing out of the Play billing sheet usually emits **no**
  /// purchaseStream event at all. Without this, the paywall's "Please wait…" spinner
  /// stays up forever and the user has to force-quit. After a short grace window —
  /// so a real `purchased` event landing just after resume still wins — anything
  /// still in flight is treated as cancelled. A late store event is still processed
  /// normally, so nothing is lost.
  void notifyAppResumed() {
    unawaited(retryPendingVerifications());

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

  static bool _isRetryable(Object error) {
    // 402 = the store rejected it, 400/404 = malformed or unknown product. Only a
    // transport/server problem is worth trying again.
    if (error is AppException) {
      final code = error.statusCode;
      return code == null || code >= 500 || code == 408 || code == 429;
    }
    return true;
  }

  Future<void> _queueForRetry(PurchaseDetails purchase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_pendingVerificationsKey) ?? [];

      final entry = jsonEncode({
        'product_id': purchase.productID,
        'purchase_token': purchase.verificationData.serverVerificationData,
        'platform': _platform,
        'queued_at': DateTime.now().toIso8601String(),
      });

      if (queue.contains(entry)) return;
      queue.add(entry);
      await prefs.setStringList(_pendingVerificationsKey, queue);
    } catch (e) {
      _log.e('Could not queue purchase for retry', error: e);
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
      Map<String, dynamic> entry;
      try {
        entry = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue; // Unparseable — drop it rather than retry forever.
      }

      try {
        final result = await _billing.verify(
          platform: entry['platform'] as String? ?? _platform,
          productId: entry['product_id'] as String,
          purchaseToken: entry['purchase_token'] as String,
        );
        // Announce it: this is a grant the user has been waiting on since the
        // verification first failed, and nothing else would refresh their state.
        _emitOwned(result);
      } catch (e) {
        if (_isRetryable(e)) remaining.add(raw);
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

  /// Whether the debug store fallback may be used. Release builds must never fake
  /// a purchase, so this is compile-time gated.
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
