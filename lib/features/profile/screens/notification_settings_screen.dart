import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/services/local_notification_service.dart';
import 'package:atlas_flutter_app/features/notifications/data/notify_prefs.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_engine.dart';
import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Notifications: what Atlas may tell you, and when. Every switch here is
/// real (stored, and read by the reminder planner), and Atlas only ever
/// speaks at a time you chose.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from system settings: the answer may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final allowed = await ref.read(localNotificationServiceProvider).hasPermission();
    if (mounted) setState(() => _allowed = allowed);
  }

  /// Turning something on is the moment the OS question makes sense, so it is
  /// asked here and never at launch. Returns whether notifications can show.
  Future<bool> _ensurePermission() async {
    if (_allowed == true) return true;
    final granted = await ref.read(localNotificationServiceProvider).requestPermissions();
    if (!mounted) return granted;
    setState(() => _allowed = granted);
    if (granted) {
      await ref.read(fcmServiceProvider).onPermissionGranted();
      replanReminders(ref);
    } else {
      AtlasToast.warning(context, 'Notifications are off for Atlas. Turn them on in your phone’s settings.');
    }
    return granted;
  }

  Future<void> _set(NotifyPrefs next, {required bool turningOn}) async {
    if (turningOn && !await _ensurePermission()) return;
    await ref.read(notifyPrefsProvider.notifier).update(next);
  }

  Future<void> _pickMorning(NotifyPrefs prefs) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.morningHour, minute: prefs.morningMinute),
      helpText: 'Your morning time',
    );
    if (time == null) return;
    await ref
        .read(notifyPrefsProvider.notifier)
        .update(prefs.copyWith(morningHour: time.hour, morningMinute: time.minute));
  }

  Future<void> _sendTest() async {
    if (!await _ensurePermission()) return;
    await ref.read(localNotificationServiceProvider).show(
          id: kUnmanagedIdBase + 1,
          title: 'A small hello from Atlas',
          body: 'This is how a reminder will look. Nothing to do.',
          route: '/',
          channel: NotifyChannel.reminders,
        );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notifyPrefsProvider);
    final morning = clockLabel(prefs.morningHour, prefs.morningMinute);

    return SettingsPage(
      title: 'Notifications',
      subtitle: 'What Atlas may tell you, and when',
      onBack: () => context.pop(),
      children: [
        if (_allowed == false) ...[
          RowGroup(children: [
            GroupRow(
              icon: Symbols.notifications_off_rounded,
              iconColor: AppColors.coral,
              title: 'Notifications are off',
              subtitle: 'Tap to allow them, so your reminders can reach you',
              onTap: _ensurePermission,
            ),
          ]),
          settingsGap,
        ],
        RowGroup(
          title: 'Reminders',
          children: [
            SwitchRow(
              icon: Symbols.self_improvement_rounded,
              iconColor: AppColors.violet,
              title: 'Habit reminders',
              subtitle: 'At the time you set on each habit, until it’s done for the day',
              value: prefs.habits,
              onChanged: (v) => _set(prefs.copyWith(habits: v), turningOn: v),
            ),
            SwitchRow(
              icon: Symbols.task_alt_rounded,
              iconColor: AppColors.sky,
              title: 'Task reminders',
              subtitle: 'When a task with a time is due',
              value: prefs.tasks,
              onChanged: (v) => _set(prefs.copyWith(tasks: v), turningOn: v),
            ),
          ],
        ),
        const SettingsFootnote('Set or change a habit’s time from the habit itself, in Grow.'),
        settingsGap,
        RowGroup(
          title: 'Gentle notes',
          children: [
            SwitchRow(
              icon: Symbols.wb_twilight_rounded,
              iconColor: AppColors.amber,
              title: 'Morning note',
              subtitle: 'A calm look at your day. Skipped when the day is empty',
              value: prefs.morning,
              onChanged: (v) => _set(prefs.copyWith(morning: v), turningOn: v),
            ),
            SwitchRow(
              icon: Symbols.mail_rounded,
              iconColor: AppColors.rose,
              title: 'Weekly letter',
              subtitle: 'Sunday morning, when Aurora is ready to look back on your week',
              value: prefs.letter,
              onChanged: (v) => _set(prefs.copyWith(letter: v), turningOn: v),
            ),
            GroupRow(
              icon: Symbols.schedule_rounded,
              iconColor: AppColors.leaf,
              title: 'Morning time',
              subtitle: 'For the morning note and the Sunday letter',
              trailing: Text(morning,
                  style: AppTypography.rowTitle.copyWith(color: context.palette.textMuted)),
              onTap: prefs.morning || prefs.letter ? () => _pickMorning(prefs) : null,
            ),
          ],
        ),
        settingsGap,
        RowGroup(children: [
          GroupRow(
            icon: Symbols.notifications_active_rounded,
            iconColor: AppColors.coral,
            title: 'Send a test notification',
            subtitle: 'See how a reminder will look',
            onTap: _sendTest,
          ),
        ]),
        const SettingsFootnote(
          'Achievements, new places, levels and Aurora’s letters wait for you in your inbox. '
          'Atlas only speaks at times you chose, and never about a streak or a missed day.',
        ),
      ],
    );
  }
}
