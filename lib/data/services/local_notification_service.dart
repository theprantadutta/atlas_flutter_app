import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:atlas_flutter_app/core/logging/app_logger.dart';

final _log = AppLog('Notify');

/// The Android channels Atlas posts to. Each is a separate row in the
/// system's notification settings, so people can quiet one without the rest.
enum NotifyChannel {
  /// Habit and task reminders, at the times the user set.
  reminders('atlas_reminders', 'Reminders', 'Habit and task reminders, at the times you choose',
      Importance.defaultImportance),

  /// The morning note and the weekly letter: calm, never urgent.
  daily('atlas_daily', 'Morning note and weekly letter', 'A calm look at your day, and Aurora’s weekly letter',
      Importance.low),

  /// Account messages from the server (a payment problem).
  account('atlas_account', 'Account', 'Important notes about your Atlas account', Importance.high);

  const NotifyChannel(this.id, this.name, this.description, this.importance);
  final String id;
  final String name;
  final String description;
  final Importance importance;
}

/// Ids at or above this are one-off nudges (Aurora's "Remind me") and foreground
/// pushes; below it, ids belong to the reminder planner, which owns and
/// replaces them as a set.
const kUnmanagedIdBase = 1 << 30;

/// Thin wrapper over flutter_local_notifications. One instance for the whole
/// app (created and initialised in main, handed to Riverpod), so the tap
/// callback the plugin was initialised with is the one the app listens to.
class LocalNotificationService {
  LocalNotificationService._();

  /// The one instance. The plugin delivers taps to whichever object called
  /// initialize, so a second instance would never hear them.
  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  /// Routes from notification taps while the app is running.
  Stream<String> get taps => _taps.stream;

  /// The route of the notification that launched the app, if one did. Read
  /// once, after the first frame, so the router exists.
  String? launchRoute;

  /// Initialise the plugin and the device time zone. Never asks for
  /// permission: that only happens where the user has just said yes to
  /// something (the primer, a Settings switch, "Remind me").
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Reminders are scheduled as instants, so a missing zone only matters
      // for the zone name; keep going on UTC.
      _log.w('Could not read the device time zone: $e');
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_atlas'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (r) {
        final route = r.payload;
        if (route != null && route.isNotEmpty) _taps.add(route);
      },
    );

    final android = _android;
    if (android != null) {
      for (final c in NotifyChannel.values) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(c.id, c.name, description: c.description, importance: c.importance),
        );
      }
      // The old catch-all channel; its job is now split across the three above.
      await android.deleteNotificationChannel(channelId: 'atlas_notifications');
    }

    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        launchRoute = launch!.notificationResponse?.payload;
      }
    } catch (_) {/* not available on this platform */}

    _ready = true;
    _log.i('Local notifications ready (${tz.local.name}).');
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// Whether Atlas may post notifications. Never shows a prompt.
  Future<bool> hasPermission() async {
    if (!_ready) return false;
    if (Platform.isIOS) return (await _ios?.checkPermissions())?.isEnabled ?? false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  /// Ask the OS for permission. Only from a moment of user intent. Inexact
  /// scheduling needs no alarm permission, and none is asked for: a habit
  /// tracker is not an alarm clock.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final granted = await _ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return await _android?.requestNotificationsPermission() ?? false;
  }

  NotificationDetails _details(NotifyChannel c) => NotificationDetails(
        android: AndroidNotificationDetails(
          c.id,
          c.name,
          channelDescription: c.description,
          importance: c.importance,
          priority: c == NotifyChannel.account ? Priority.high : Priority.defaultPriority,
          icon: '@drawable/ic_stat_atlas',
          color: const Color(0xFFFF5E62),
          category: c == NotifyChannel.reminders ? AndroidNotificationCategory.reminder : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: c != NotifyChannel.daily,
          threadIdentifier: c.id,
        ),
      );

  /// Show something now (an account push that arrived in the foreground).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String route,
    NotifyChannel channel = NotifyChannel.account,
  }) =>
      _plugin.show(id: id, title: title, body: body, notificationDetails: _details(channel), payload: route);

  /// Schedule [title]/[body] at [at] (a local time). Inexact on Android, so
  /// it may arrive a few minutes late, which suits a gentle reminder.
  /// Re-using an id replaces what was scheduled under it.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String route,
    required NotifyChannel channel,
  }) =>
      _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _details(channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: route,
      );

  /// Ids currently waiting to fire.
  Future<Set<int>> pendingIds() async =>
      (await _plugin.pendingNotificationRequests()).map((r) => r.id).toSet();

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
