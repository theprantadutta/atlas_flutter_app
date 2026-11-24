import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/errors/error_messages.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/core/telemetry/activation.dart';

/// Firebase Analytics and Crashlytics, in one place.
///
/// What is collected, and why it is safe:
/// * Crashes and errors, so they can be fixed.
/// * Which screens are opened (as route patterns such as `/users/:id`, never
///   ids), and a handful of moments: tending something, finishing a day,
///   talking to Aurora, a letter, the paywall, purchases, signing in. Every
///   event is a typed method below; parameters are app-defined values
///   (category, task type, product id), never anything a person typed.
/// * The signed-in account's opaque id, so a crash can be tied to an account
///   in support. Never an email or a name.
///
/// Collection is on only in release builds, so testing on a device doesn't
/// fill the dashboards. Build with `--dart-define=ATLAS_TELEMETRY=true` to
/// switch it on in a debug build, for example to send a test crash.
///
/// Everything is a no-op until [init] has run against an initialised
/// Firebase app, so widget and unit tests need no setup.
/// Where the paywall was opened from (the `source` on paywall events).
abstract final class PaywallSource {
  static const auroraTab = 'aurora_tab';
  static const auroraChatLimit = 'aurora_chat_limit';
  static const auroraReflectionLimit = 'aurora_reflection_limit';
  static const auroraMemories = 'aurora_memories';
  static const quickAdd = 'quick_add';
  static const goalSteps = 'goal_steps';
  static const planDay = 'plan_day';
  static const checkIn = 'check_in';
  static const insights = 'insights';
  static const sync = 'sync';
  static const profile = 'profile';
  static const unknown = 'unknown';

  /// The paywall route for [source].
  static String route(String source) => '/paywall?from=$source';
}

class Telemetry {
  Telemetry._();

  static const bool _forced = bool.fromEnvironment('ATLAS_TELEMETRY');

  /// Whether reports leave the device.
  static bool get collecting => kReleaseMode || _forced;

  /// True when a test build may trigger a deliberate crash (never in a store
  /// build: those are release builds without the define).
  static bool get canSendTestCrash => _forced;

  /// Log tag for the uncaught-error handlers, which report to Crashlytics
  /// directly.
  static const String crashTag = 'Crash';

  static bool _ready = false;
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;

  /// Call once, right after `Firebase.initializeApp`.
  static Future<void> init() async {
    if (Firebase.apps.isEmpty) return;
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      await _crashlytics!.setCrashlyticsCollectionEnabled(collecting);
      await _analytics!.setAnalyticsCollectionEnabled(collecting);
      // With collection off, nothing below is worth queueing on the device.
      _ready = collecting;
      if (!_ready) return;

      // Errors logged anywhere in the app (`_log.e(...)`) become non-fatal
      // reports, and warnings become breadcrumbs on the next report. The
      // uncaught handlers in main.dart log under [crashTag] and report
      // themselves, so they are skipped here to avoid a duplicate.
      AppLog.errorSink = (tag, message, error, stack) {
        if (tag == crashTag) return;
        if (error != null && !AppErrors.isExpected(error)) {
          recordError(error, stack, reason: '$tag: $message');
        } else {
          breadcrumb('$tag: $message');
        }
      };
      AppLog.warningSink = (tag, message) => breadcrumb('$tag: $message');
    } catch (e) {
      // Telemetry must never stop the app starting.
      debugPrint('Telemetry unavailable: $e');
    }
  }

  // ─── Crashes ───────────────────────────────────────────────────────

  /// A framework error (build, layout, paint). These are fatal to the frame,
  /// so they are reported as fatal.
  static void recordFlutterError(FlutterErrorDetails details) {
    if (!_ready) return;
    unawaited(_crashlytics!.recordFlutterFatalError(details));
  }

  static void recordError(Object error, StackTrace? stack, {String? reason, bool fatal = false}) {
    if (!_ready) return;
    unawaited(_crashlytics!.recordError(error, stack, reason: reason, fatal: fatal));
  }

  static void breadcrumb(String message) {
    if (!_ready) return;
    unawaited(_crashlytics!.log(message));
  }

  /// Ties reports to the signed-in account by its opaque id; null on sign-out.
  static Future<void> setUser(String? userId) async {
    if (!_ready) return;
    await _crashlytics!.setUserIdentifier(userId ?? '');
    await _analytics!.setUserId(id: userId);
  }

  /// After account deletion: drop this device's analytics data and identity,
  /// so nothing carries over to whoever signs in next.
  static Future<void> forgetDevice() async {
    if (!_ready) return;
    await _analytics!.resetAnalyticsData();
  }

  /// For checking the pipeline end to end from a test build.
  static void sendTestCrash() {
    if (!_ready || !canSendTestCrash) return;
    _crashlytics!.crash();
  }

  // ─── Screens ───────────────────────────────────────────────────────

  static String? _lastScreen;

  /// [route] is a route pattern from the router, e.g. `/users/:id`.
  static void screen(String route) {
    if (!_ready || route == _lastScreen) return;
    _lastScreen = route;
    unawaited(_analytics!.logScreenView(screenName: route, screenClass: route));
  }

  // ─── Moments ───────────────────────────────────────────────────────

  static void _event(String name, [Map<String, Object>? params]) {
    if (!_ready) return;
    unawaited(_analytics!.logEvent(name: name, parameters: params));
  }

  /// Categories, frequencies and types are stored as enum names. Anything
  /// that doesn't look like one is sent as `other`, so a value can never
  /// carry free text even if the column one day does.
  static String _key(String value) =>
      RegExp(r'^[A-Za-z_]{1,40}$').hasMatch(value) ? value : 'other';

  static void taskTended({required String type, required String category}) {
    _event('tend_task', {'task_type': _key(type), 'category': _key(category)});
    _activation((a) => a.tended());
  }

  static void habitTended({required String frequency, required String category}) {
    _event('tend_habit', {'frequency': _key(frequency), 'category': _key(category)});
    _activation((a) => a.tended());
  }

  /// Runs a step of [Activation] and logs whatever it reports.
  static void _activation(
    Future<(String, Map<String, Object>)?> Function(Activation) step,
  ) {
    if (!_ready) return;
    unawaited(() async {
      try {
        final event = await step(Activation(await SharedPreferences.getInstance()));
        if (event != null) _event(event.$1, event.$2);
      } catch (_) {/* measurement must never get in the way */}
    }());
  }

  static void goalReached({required String category}) =>
      _event('goal_reached', {'category': _key(category)});

  static void levelUp(int level) {
    if (!_ready) return;
    unawaited(_analytics!.logLevelUp(level: level));
  }

  static void dayComplete() => _event('day_complete');

  static void auroraMessage({required bool streamed}) =>
      _event('aurora_message', {'streamed': streamed ? 1 : 0});

  static void letterWritten() => _event('aurora_letter');

  // ─── Paywall ───────────────────────────────────────────────────────

  /// Where the open paywall was reached from, so purchases can be credited
  /// to the screen that led to them.
  static String _paywallSource = 'unknown';

  /// [source] is one of the [PaywallSource] values.
  static void paywallViewed(String source) {
    _paywallSource = _key(source);
    _event('paywall_view', {'source': _paywallSource});
  }

  /// Left the paywall without buying anything.
  static void paywallDismissed() =>
      _event('paywall_dismiss', {'source': _paywallSource});

  static void purchaseStarted(String productId) => _event('purchase_start', {
    'product_id': productId,
    'source': _paywallSource,
  });

  static void purchaseCompleted(
    String productId, {
    required bool trial,
    required bool lifetime,
  }) => _event('purchase_complete', {
    'product_id': productId,
    'trial': trial ? 1 : 0,
    'lifetime': lifetime ? 1 : 0,
    'source': _paywallSource,
  });

  // ─── First run ─────────────────────────────────────────────────────
  //
  // Together with the screen views these make the first-run funnel:
  // intro page 1 → 2 → 3 → how the intro was left → sign-in attempted →
  // signed in (or why not) → setup finished.

  /// [page] counts from 1.
  static void introPage(int page) => _event('intro_page', {'page': page});

  /// [action] is `skip`, `create_account` or `have_account`.
  static void introLeft(String action, {required int page}) =>
      _event('intro_exit', {'action': _key(action), 'page': page});

  /// [where] is `auth` (agreed by continuing on the sign-in screens) or
  /// `gate` (the full documents screen, shown when they change).
  static void legalAccepted(String where) =>
      _event('legal_accept', {'where': _key(where)});

  /// [method] is `email`, `google` or `apple`; [screen] `login` or `signup`.
  static void authAttempt(String method, {required String screen}) =>
      _event('auth_attempt', {'method': _key(method), 'screen': _key(screen)});

  /// [kind] is a coarse category from [authFailureKind], never a message.
  static void authFailed(String method, String kind) =>
      _event('auth_fail', {'method': _key(method), 'kind': _key(kind)});

  static void setupCompleted({required int focusCount}) {
    _event('setup_complete', {'focus_count': focusCount});
    _activation((a) async {
      await a.setupFinished();
      return null;
    });
  }

  static void signedIn(String method) {
    if (!_ready) return;
    unawaited(_analytics!.logLogin(loginMethod: method));
  }

  static void signedUp(String method) {
    if (!_ready) return;
    unawaited(_analytics!.logSignUp(signUpMethod: method));
  }
}
