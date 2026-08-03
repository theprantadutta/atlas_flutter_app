import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/app_logger.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'data/services/local_notification_service.dart';

final _log = AppLog('App');

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Anything that escapes a widget or an async gap still gets recorded, so a
  // crash in the wild leaves a trail instead of vanishing.
  FlutterError.onError = (details) {
    _log.e(
      'Uncaught framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _log.e('Uncaught async error', error: error, stackTrace: stack);
    return true;
  };

  await dotenv.load();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    // Firebase unavailable — the app still runs; Google/Apple sign-in won't.
    _log.e('Firebase initialisation failed', error: e, stackTrace: st);
  }

  // Initialize local notifications
  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();

  runApp(const ProviderScope(child: AtlasApp()));
}
