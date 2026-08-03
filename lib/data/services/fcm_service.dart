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

  /// Request permissions, obtain the FCM token, and start listening for
  /// token refreshes and foreground messages.
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS shows a dialog; Android auto-grants)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log.w('[FCM] Notification permission denied');
        return;
      }

      // Get the current FCM token
      _currentToken = await messaging.getToken();
      _log.d('[FCM] Token obtained: ${_currentToken?.substring(0, 20)}...');

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _log.d('[FCM] Token refreshed');
        _currentToken = newToken;
        registerToken();
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    } catch (e) {
      _log.e('[FCM] Initialization failed: $e');
    }
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
