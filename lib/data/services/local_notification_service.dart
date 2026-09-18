import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';

final _log = AppLog('Notify');

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();


  /// Callback invoked when the user taps a notification.
  Function(String?)? onNotificationTapped;

  /// Initialize the local notification plugin with platform-specific settings.
  ///
  /// This deliberately does **not** ask the OS for notification permission —
  /// a cold-start permission prompt before the user has seen a single screen is
  /// hostile, converts badly, and App Review flags it. Call
  /// [requestPermissions] instead, at a moment where the ask has context (the
  /// onboarding "stay on track" step, or the Notifications settings screen).
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels + request permissions
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const mainChannel = AndroidNotificationChannel(
        'atlas_notifications',
        'Atlas Notifications',
        description: 'Push notifications from Atlas',
        importance: Importance.high,
      );
      await androidPlugin.createNotificationChannel(mainChannel);

      const reminderChannel = AndroidNotificationChannel(
        'atlas_reminders',
        'Atlas Reminders',
        description: 'Scheduled reminders from Atlas',
        importance: Importance.defaultImportance,
      );
      await androidPlugin.createNotificationChannel(reminderChannel);
    }

    _log.i('[LocalNotification] Initialized (permission not yet requested)');
  }

  /// Whether Atlas may currently post notifications.
  ///
  /// Read-only: unlike [requestPermissions] this never shows a system prompt,
  /// so it is safe to call before deciding whether to ask at all. Someone who
  /// already said yes should not be asked again, and neither should someone who
  /// turned them on from system settings without ever seeing our prompt.
  Future<bool> hasPermission() async {
    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await iosPlugin?.checkPermissions();
      return options?.isEnabled ?? false;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  /// Ask the OS for notification permission.
  ///
  /// Call this only from a context where the user has just expressed intent —
  /// e.g. tapping "Turn on reminders". Returns `true` when notifications are
  /// authorised. Safe to call repeatedly: once the user has answered, the OS
  /// returns the existing decision without showing a prompt again.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _log.i('[LocalNotification] iOS permission granted: $granted');
      return granted ?? false;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    // Notifications, and nothing else. There is deliberately no exact-alarm
    // request here: every reminder Atlas schedules uses
    // AndroidScheduleMode.inexactAllowWhileIdle, and the manifest strips
    // SCHEDULE_EXACT_ALARM and USE_EXACT_ALARM with tools:node="remove"
    // precisely because a habit tracker is not an alarm clock.
    //
    // This used to call requestExactAlarmsPermission unconditionally. That has
    // no dialog: it fires an intent that opens the full "Alarms & reminders"
    // settings screen. So a user who had permanently denied notifications saw
    // no prompt at all (Android stops showing it once the denial is USER_FIXED)
    // and was then dumped into system settings, asking for a capability the app
    // had explicitly given up.
    final granted = await androidPlugin.requestNotificationsPermission() ?? false;
    _log.i('[LocalNotification] Android permission granted: $granted');
    return granted;
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
      channelDescription: 'Push notifications from Atlas',
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

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    _log.d('[LocalNotification] Tapped: ${response.payload}');
    onNotificationTapped?.call(response.payload);
  }
}
