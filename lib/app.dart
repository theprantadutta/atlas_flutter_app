import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/services/local_notification_service.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/notifications/data/inbox.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_engine.dart';
import 'package:atlas_flutter_app/features/updates/providers/app_update_provider.dart';
import 'package:atlas_flutter_app/router/app_router.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/providers/refresh_rate_provider.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_theme.dart';

class AtlasApp extends ConsumerStatefulWidget {
  const AtlasApp({super.key});

  @override
  ConsumerState<AtlasApp> createState() => _AtlasAppState();
}

class _AtlasAppState extends ConsumerState<AtlasApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _syncRequiredSub;
  StreamSubscription<String>? _tapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wireUnauthorizedHandler();
    _initializeOfflineServices();
    _wireNotificationTaps();
    // Look for a Play update once the first frame is up, so the check never
    // competes with startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateProvider.notifier).check();
      // Opt into the display's high refresh rate if the user wants it. The
      // provider reads the stored preference itself on first build.
      ref.read(refreshRateProvider);
    });
  }

  /// When a token refresh fails irrecoverably, drop the session so the router
  /// redirects the user to the login screen.
  void _wireUnauthorizedHandler() {
    ref.read(apiServiceProvider).onUnauthorized = () {
      ref.read(authProvider.notifier).markLoggedOut();
    };
  }

  void _initializeOfflineServices() {
    final offlineManager = ref.read(offlineManagerProvider);
    offlineManager.initialize(
      Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      ),
    );

    // Listen to auth state changes and update OfflineManager accordingly.
    ref.listenManual<AuthState>(authProvider, (prev, next) {
      offlineManager.setAuthenticated(next.isAuthenticated, userId: next.user?.id);
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        _connectSignalR();
        _initializeFcm();
        _refreshAccountMessages();
      }
    });

    // Cloud sync is premium — drive the engine's per-user gate from the same
    // `cloud_sync` entitlement the sync UI uses (falls back to premium status
    // before the first `/entitlements` fetch resolves), so the engine never
    // runs while the UI says sync is unavailable, or vice versa.
    ref.listenManual<bool>(
      canSyncProvider,
      (prev, next) => offlineManager.setEntitled(next),
      fireImmediately: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // A new day may have started while we were away.
        ref.read(todayProvider.notifier).refresh();
        ref.read(offlineManagerProvider).onAppResumed();
        // Re-check entitlement on resume so renewals / lapses / expiry are
        // picked up without a restart.
        ref.read(entitlementsProvider.notifier).refresh();
        // Returning from the Play billing sheet: clear a stuck purchase spinner
        // when Android closed it without emitting an event, and retry any
        // verification that failed while offline.
        ref.read(entitlementControllerProvider).onAppResumed();
        // Cheap no-op once an update has already been picked up this session.
        ref.read(appUpdateProvider.notifier).check();
        // Android drops the window's preferred display mode when the app is
        // backgrounded, so re-assert it rather than silently sliding to 60 Hz.
        ref.read(refreshRateProvider.notifier).apply();
        _connectSignalR();
        // Reminders are planned a few days ahead; top the plan up, and pick
        // up account messages that arrived while we were away.
        ref.invalidate(reminderSyncProvider);
        _refreshAccountMessages();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        ref.read(offlineManagerProvider).onAppPaused();
        ref.read(signalRServiceProvider).disconnect();
        break;
      default:
        break;
    }
  }

  /// Every notification tap (a reminder, a push, or the one that launched
  /// the app) becomes a pending route, which the app shell opens once it is
  /// on screen, after the splash and the sign-in redirects.
  void _wireNotificationTaps() {
    final local = ref.read(localNotificationServiceProvider);
    final pending = ref.read(pendingNotificationRouteProvider.notifier);
    _tapSub = local.taps.listen(pending.set);
    final launch = local.launchRoute;
    if (launch != null) {
      local.launchRoute = null;
      pending.set(launch);
    }
  }

  Future<void> _initializeFcm() async {
    final fcm = ref.read(fcmServiceProvider);
    final local = ref.read(localNotificationServiceProvider);

    // The OS shows nothing for a push while the app is open, so show it here
    // (on the Account channel), and file it in the inbox either way.
    fcm.onForeground = (m) {
      final (title, body) = _fileAccountPush(m);
      if (title.isEmpty && body.isEmpty) return;
      local.show(
        id: kUnmanagedIdBase + ((m.messageId ?? '$title$body').hashCode & 0x0FFFFFFF),
        title: title,
        body: body,
        route: safeNotificationRoute(_routeOf(m)),
      );
    };
    fcm.onOpened = (m) {
      _fileAccountPush(m);
      ref.read(pendingNotificationRouteProvider.notifier).set(_routeOf(m));
    };

    await fcm.initialize();
    await fcm.registerToken();
  }

  String? _routeOf(RemoteMessage m) =>
      routeForInboxKind(m.data['kind'] as String? ?? '') ?? m.data['route'] as String?;

  /// Files an account push in the inbox under the server's id (so a later
  /// fetch of the same message lands on the same row). Returns its text.
  (String, String) _fileAccountPush(RemoteMessage m) {
    final title = m.notification?.title ?? '';
    final body = m.notification?.body ?? '';
    final id = m.data['notification_id'] as String?;
    final userId = ref.read(authProvider).user?.id;
    if (m.data['kind'] == InboxKind.account && id != null && userId != null) {
      fileAccountMessage(ref.read(inboxProvider), userId: userId, id: id, title: title, body: body);
    }
    return (title, body);
  }

  void _refreshAccountMessages() {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    refreshAccountMessages(ref.read(apiServiceProvider), ref.read(inboxProvider), userId);
  }

  void _connectSignalR() {
    final signalR = ref.read(signalRServiceProvider);
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    signalR.connect();

    // Wire SyncRequired events to trigger an immediate sync
    _syncRequiredSub?.cancel();
    _syncRequiredSub = signalR.onSyncRequired.listen((_) {
      ref.read(offlineManagerProvider).syncNow();
    });
  }

  @override
  void dispose() {
    _syncRequiredSub?.cancel();
    _tapSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: AppMotion.medium,
      themeAnimationCurve: AppMotion.standard,
      routerConfig: router,
      // Status and navigation bars follow the palette (light icons in dark).
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayFor(context.palette),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
