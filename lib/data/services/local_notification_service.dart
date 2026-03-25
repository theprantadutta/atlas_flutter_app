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
  Future<void> initialize() async {
    // Initialize timezone data for scheduled notifications
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Create a separate channel for scheduled reminders
    const reminderChannel = AndroidNotificationChannel(
      'atlas_reminders',
      'Atlas Reminders',
      description: 'Scheduled reminders from Atlas',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(reminderChannel);

    _log.d('[LocalNotification] Initialized with timezone support');
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

  /// Schedule a notification at a specific time.
  ///
  /// Uses [AndroidScheduleMode.inexactAllowWhileIdle] to work even in Doze mode.
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
      id,
      title,
      body,
      tzDateTime,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );

    _log.d('[LocalNotification] Scheduled "$title" for $scheduledDate');
  }

  /// Schedule a daily repeating notification at a specific time.
  ///
  /// Useful for habit reminders — fires every day at the given hour:minute.
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

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    _log.d(
        '[LocalNotification] Scheduled daily "$title" at $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
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
