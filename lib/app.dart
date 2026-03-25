import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/router/app_router.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_theme.dart';

class AtlasApp extends ConsumerStatefulWidget {
  const AtlasApp({super.key});

  @override
  ConsumerState<AtlasApp> createState() => _AtlasAppState();
}

class _AtlasAppState extends ConsumerState<AtlasApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _syncRequiredSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeOfflineServices();
  }

  void _initializeOfflineServices() {
    final offlineManager = ref.read(offlineManagerProvider);
    offlineManager.initialize(
      Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      ),
    );

    // Listen to auth state changes and update OfflineManager accordingly
    ref.listenManual<AuthState>(authProvider, (prev, next) {
      offlineManager.setAuthenticated(next.isAuthenticated, userId: next.user?.id);
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        _connectSignalR();
        _initializeFcm();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(offlineManagerProvider).onAppResumed();
        _connectSignalR();
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

  Future<void> _initializeFcm() async {
    final fcmService = ref.read(fcmServiceProvider);
    final localNotificationService = ref.read(localNotificationServiceProvider);

    // Wire FCM foreground messages to show local notifications
    fcmService.onNotificationReceived = (payload) {
      final title = payload['title'] as String? ?? '';
      final body = payload['body'] as String? ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        localNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: payload.toString(),
        );
      }
    };

    await fcmService.initialize();
    await fcmService.registerToken();
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
      routerConfig: router,
    );
  }
}
