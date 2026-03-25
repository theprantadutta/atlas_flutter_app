import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when the user taps a notification.
  Function(String?)? onNotificationTapped;

  /// Initialize the local notification plugin with platform-specific settings.
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel
    const channel = AndroidNotificationChannel(
      'atlas_notifications',
      'Atlas Notifications',
      description: 'Notifications from Atlas',
      importance: Importance.high,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    _log.d('[LocalNotification] Initialized');
  }

  /// Show an immediate local notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'atlas_notifications',
      'Atlas Notifications',
      channelDescription: 'Notifications from Atlas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  void _onNotificationTapped(NotificationResponse response) {
    _log.d('[LocalNotification] Tapped: ${response.payload}');
    onNotificationTapped?.call(response.payload);
  }
}
