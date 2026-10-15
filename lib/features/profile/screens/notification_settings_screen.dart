import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Notifications: gentle control over what reaches you. Calm nudges, never
/// nagging.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotifSetting {
  _NotifSetting({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  bool value;
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  late final List<_NotifSetting> _settings = [
    _NotifSetting(
      icon: Symbols.task_alt_rounded,
      color: AppColors.sky,
      title: 'Task reminders',
      subtitle: 'A soft nudge when something is due',
      value: true,
    ),
    _NotifSetting(
      icon: Symbols.repeat_rounded,
      color: AppColors.leaf,
      title: 'Habit reminders',
      subtitle: 'Little prompts to keep your rhythm',
      value: true,
    ),
    _NotifSetting(
      icon: Symbols.flag_rounded,
      color: AppColors.amber,
      title: 'Goal deadlines',
      subtitle: 'A heads-up as a goal draws near',
      value: false,
    ),
    _NotifSetting(
      icon: Symbols.trophy_rounded,
      color: AppColors.amber,
      title: 'Achievements',
      subtitle: 'Celebrate the moments you earn',
      value: true,
    ),
    _NotifSetting(
      icon: Symbols.wb_twilight_rounded,
      color: AppColors.coral,
      title: 'Daily summary',
      subtitle: 'A kind recap of your day',
      value: false,
    ),
    _NotifSetting(
      icon: Symbols.bedtime_rounded,
      color: AppColors.violet,
      title: 'Quiet hours',
      subtitle: 'We rest while you do, 10pm to 7am',
      value: true,
    ),
  ];

  /// Turning a reminder on is the first moment the OS prompt has any context,
  /// so that's where we ask, never at cold start. If the user declines at the
  /// OS level the toggle springs back, since we couldn't honour it anyway.
  Future<void> _onToggle(int index, bool value) async {
    setState(() => _settings[index].value = value);
    if (!value) return;

    final granted = await ref.read(localNotificationServiceProvider).requestPermissions();

    if (granted) {
      // Push stays unreachable until the token is fetched and registered, and
      // that only happens at launch when permission already exists.
      await ref.read(fcmServiceProvider).onPermissionGranted();
      return;
    }

    if (!mounted) return;
    setState(() => _settings[index].value = false);
    AtlasToast.warning(
      context,
      'Notifications are off for Atlas. Turn them on in Settings to get reminders.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Notifications',
      subtitle: 'Choose what reaches you',
      onBack: () => context.pop(),
      children: [
        RowGroup(
          title: 'Reminders',
          children: [
            for (var i = 0; i < 3; i++) _row(i),
          ],
        ),
        settingsGap,
        RowGroup(
          title: 'Moments',
          children: [
            for (var i = 3; i < 5; i++) _row(i),
          ],
        ),
        settingsGap,
        RowGroup(children: [_row(5)]),
        const SettingsFootnote(
          'Atlas never sends streak warnings or guilt. If you go quiet, so do we.',
        ),
      ],
    );
  }

  Widget _row(int i) => SwitchRow(
        icon: _settings[i].icon,
        iconColor: _settings[i].color,
        title: _settings[i].title,
        subtitle: _settings[i].subtitle,
        value: _settings[i].value,
        onChanged: (v) => _onToggle(i, v),
      );
}
