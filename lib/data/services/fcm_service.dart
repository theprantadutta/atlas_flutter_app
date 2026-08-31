import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';

import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

final _log = AppLog('Fcm');

class FcmService {
  final ApiService _apiService;
  final TokenService _tokenService;

  String? _currentToken;

  /// Callback the app can set to handle incoming notification payloads.
  Function(Map<String, dynamic>)? onNotificationReceived;

  FcmService(this._apiService, this._tokenService);

  /// Whether push is already authorised. Read-only: this never shows a prompt.
  Future<bool> hasPermission() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      _log.w('[FCM] Could not read notification settings: $e');
      return false;
    }
  }

  /// Start listening for token refreshes and messages, and pick up the token
  /// if push is already authorised.
  ///
  /// This deliberately does **not** ask for permission. It used to, with a
  /// comment claiming Android auto-grants; that stopped being true at Android
  /// 13, and since this runs at app start it meant the bare system dialog
  /// appeared on a cold launch, ahead of the in-app primer that exists to
  /// explain it. The OS ask is one-shot, so spending it that way is the whole
  /// problem the primer solves. Permission is requested only through
  /// [requestPermission], from a screen where the ask has context.
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Listeners are cheap and permission-independent: a user who grants
      // later should not need a restart for messages to arrive.
      messaging.onTokenRefresh.listen((newToken) {
        _log.d('[FCM] Token refreshed');
        _currentToken = newToken;
        registerToken();
      });
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      if (await hasPermission()) {
        await _fetchToken();
      } else {
        _log.i('[FCM] Not authorised yet; deferring token until permission.');
      }
    } catch (e) {
      _log.e('[FCM] Initialization failed: $e');
    }
  }

  /// Ask the OS for push permission. Shows the system dialog, so call it only
  /// once the user has said yes to the in-app primer.
  Future<bool> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      _log.i('[FCM] Permission status: ${settings.authorizationStatus}');
      if (granted) await onPermissionGranted();
      return granted;
    } catch (e) {
      _log.e('[FCM] Permission request failed: $e');
      return false;
    }
  }

  /// Pick up and register the token after permission is granted elsewhere.
  /// Without this, a user who accepts stays unreachable until the next launch.
  Future<void> onPermissionGranted() async {
    await _fetchToken();
    await registerToken();
  }

  Future<void> _fetchToken() async {
    _currentToken = await FirebaseMessaging.instance.getToken();
    final preview = _currentToken == null
        ? 'none'
        : '${_currentToken!.substring(0, 20)}...';
    _log.d('[FCM] Token obtained: $preview');
  }

  /// Register the current FCM token with the backend.
  Future<void> registerToken() async {
    if (_currentToken == null) return;

    try {
      final hasTokens = await _tokenService.hasTokens();
      if (!hasTokens) return;

      final platform = Platform.isAndroid ? 'android' : 'ios';
      await _apiService.post(
        '/device-tokens',
        data: {
          'token': _currentToken,
          'platform': platform,
        },
      );
      _log.d('[FCM] Token registered with backend');
    } catch (e) {
      _log.e('[FCM] Failed to register token: $e');
    }
  }

  /// Unregister the current FCM token from the backend (e.g. on logout).
  Future<void> unregisterToken() async {
    if (_currentToken == null) return;

    try {
      await _apiService.delete(
        '/device-tokens',
        data: {'token': _currentToken},
      );
      _log.d('[FCM] Token unregistered from backend');
    } catch (e) {
      _log.e('[FCM] Failed to unregister token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _log.d('[FCM] Foreground message: ${message.notification?.title}');

    final payload = <String, dynamic>{
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      ...message.data,
    };

    onNotificationReceived?.call(payload);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _log.d('[FCM] Message opened app: ${message.notification?.title}');

    final payload = <String, dynamic>{
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      ...message.data,
    };

    onNotificationReceived?.call(payload);
  }
}
