import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'data/services/local_notification_service.dart';

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    // Firebase unavailable — continue without it (Google Sign-In won't work)
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize local notifications
  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();

  runApp(const ProviderScope(child: AtlasApp()));
}
