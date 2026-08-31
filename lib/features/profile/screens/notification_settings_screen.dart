import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';
import 'package:atlas_flutter_app/shared/widgets/feedback/atlas_toast.dart';

/// Notifications — gentle control over what reaches you. Calm nudges, never
/// nagging.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late final List<_NotifSetting> _settings = [
    _NotifSetting(
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.categoryWork,
      title: 'Task reminders',
      subtitle: 'A soft nudge when something is due',
      value: true,
    ),
    _NotifSetting(
      icon: Icons.loop_rounded,
      color: AppColors.xpPrimary,
      title: 'Habit reminders',
      subtitle: 'Little prompts to keep your rhythm',
      value: true,
    ),
    _NotifSetting(
      icon: Icons.flag_outlined,
      color: AppColors.tertiary,
      title: 'Goal deadlines',
      subtitle: 'A heads-up as a goal draws near',
      value: false,
    ),
    _NotifSetting(
      icon: Icons.emoji_events_rounded,
      color: AppColors.badgeLegendary,
      title: 'Achievements',
      subtitle: 'Celebrate the moments you earn',
      value: true,
    ),
    _NotifSetting(
      icon: Icons.wb_twilight_rounded,
      color: AppColors.secondary,
      title: 'Daily summary',
      subtitle: 'A kind recap of your day',
      value: false,
    ),
    _NotifSetting(
      icon: Icons.nightlight_round,
      color: AppColors.categoryMindfulness,
      title: 'Quiet hours',
      subtitle: 'We rest while you do, 10pm to 7am',
      value: true,
    ),
  ];

  /// Turning a reminder on is the first moment the OS prompt has any context,
  /// so that's where we ask — never at cold start. If the user declines at the
  /// OS level the toggle springs back, since we couldn't honour it anyway.
  Future<void> _onToggle(int index, bool value) async {
    setState(() => _settings[index].value = value);
    if (!value) return;

    final granted =
        await ref.read(localNotificationServiceProvider).requestPermissions();

    if (granted) {
      // Push stays unreachable until the token is fetched and registered, and
      // that only happens at launch when permission already exists. Same reason
      // the primer does this.
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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.bottomNavSpace,
          ),
          children: [
            AtlasHeader(
              title: 'Notifications',
              subtitle: 'Choose what reaches you',
              onBack: () => context.pop(),
            ),
            AppSpacing.gapLg,
            for (var i = 0; i < _settings.length; i++) ...[
              if (i > 0) AppSpacing.gapSm,
              _NotifTile(
                setting: _settings[i],
                onChanged: (v) => _onToggle(i, v),
              )
                  .animate()
                  .fadeIn(
                    duration: AppMotion.medium,
                    delay: (60 * i).ms,
                  )
                  .slideY(begin: 0.06, end: 0, curve: AppMotion.standard),
            ],
          ],
        ),
      ),
    );
  }
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

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.setting, required this.onChanged});
  final _NotifSetting setting;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: () => onChanged(!setting.value),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: setting.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(setting.icon, color: setting.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setting.title, style: theme.textTheme.titleMedium),
                Text(
                  setting.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Switch.adaptive(
            value: setting.value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.onPrimary,
            activeTrackColor: setting.color,
          ),
        ],
      ),
    );
  }
}
