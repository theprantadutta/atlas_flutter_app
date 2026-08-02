import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _tzInitialized = false;

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
    // Initialize timezone data for scheduled notifications
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }

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

    final granted = await androidPlugin.requestNotificationsPermission();
    // Exact alarms (Android 14+) back the scheduled reminders.
    await androidPlugin.requestExactAlarmsPermission();
    _log.i('[LocalNotification] Android permission granted: $granted');
    return granted ?? false;
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

  /// Schedule a one-time notification at a specific time.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'atlas_reminders',
      'Atlas Reminders',
      channelDescription: 'Scheduled reminders from Atlas',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
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

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDateTime,
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    _log.d('[LocalNotification] Scheduled "$title" for $scheduledDate');
  }

  /// Schedule a daily repeating notification at a specific time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'atlas_reminders',
      'Atlas Reminders',
      channelDescription: 'Scheduled reminders from Atlas',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
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

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    _log.d(
        '[LocalNotification] Scheduled daily "$title" at $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Schedule a weekly repeating notification at a specific day and time.
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'atlas_reminders',
      'Atlas Reminders',
      channelDescription: 'Scheduled reminders from Atlas',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
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

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    _log.d(
        '[LocalNotification] Scheduled weekly "$title" on day $dayOfWeek at $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Get all pending scheduled notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  void _onNotificationTapped(NotificationResponse response) {
    _log.d('[LocalNotification] Tapped: ${response.payload}');
    onNotificationTapped?.call(response.payload);
  }
}
