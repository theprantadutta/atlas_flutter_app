import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';

/// Set once the primer has been shown, so it is only ever asked once.
const _kPrimerShown = 'atlas_notification_primer_shown';

final _log = AppLog('Notifications');

/// Asks, in Atlas's own words, before the OS asks in its own.
///
/// The system prompt is one-shot: on Android a second refusal makes it
/// permanently silent, and on iOS there is no second chance at all. Firing it
/// cold, before anyone has seen what Atlas does, spends that single ask on a
/// stranger. This explains what the notifications are for first, and only
/// reaches for the real prompt if the answer is yes. "Not now" leaves the OS
/// ask unused, so Settings can still spend it later.
///
/// Returns true when permission ends up granted.
Future<bool> showNotificationPrimer(BuildContext context, WidgetRef ref) async {
  final optedIn = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _NotificationPrimerSheet(),
  );

  if (optedIn != true) return false;

  // One OS permission covers both kinds of notification, so this single prompt
  // is the whole ask: POST_NOTIFICATIONS on Android, UNUserNotificationCenter
  // on iOS. Local notifications go first because that call also asks for exact
  // alarms, which the scheduled reminders need.
  final granted =
      await ref.read(localNotificationServiceProvider).requestPermissions();
  _log.i('Notification permission after primer: $granted');

  if (granted) {
    // Push needs its token fetched and registered now. Without this the user
    // said yes but stays unreachable until the next cold start, because the
    // token is only picked up at launch when permission already exists.
    await ref.read(fcmServiceProvider).onPermissionGranted();
  }

  return granted;
}

/// Show the primer once, when Atlas has earned the ask.
///
/// Skipped when it has already been asked, when permission is already granted
/// (including someone who turned it on from system settings), and while the
/// first-run tour is still on screen, so the two never overlap.
Future<void> maybeShowNotificationPrimer(
  BuildContext context,
  WidgetRef ref, {
  required bool tourFinished,
}) async {
  if (!tourFinished) return;

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kPrimerShown) ?? false) return;

  final service = ref.read(localNotificationServiceProvider);
  if (await service.hasPermission()) {
    // Nothing to ask for. Burn the flag anyway so revoking permission later
    // does not resurrect the prompt out of nowhere.
    await prefs.setBool(_kPrimerShown, true);
    return;
  }

  // Let Home settle before interrupting it.
  await Future<void>.delayed(const Duration(milliseconds: 900));
  if (!context.mounted) return;

  await showNotificationPrimer(context, ref);
  await prefs.setBool(_kPrimerShown, true);
}

// ─── Sheet ──────────────────────────────────────────────────────────

class _NotificationPrimerSheet extends StatelessWidget {
  const _NotificationPrimerSheet();

  /// The three Atlas actually sends, in the order they matter. Deliberately not
  /// all six from Settings: a list long enough to skim is a list nobody reads.
  static const _reasons = <(IconData, Color, String, String)>[
    (
      Icons.loop_rounded,
      AppColors.xpPrimary,
      'Keep your rhythm',
      'A little prompt for the habits you chose.',
    ),
    (
      Icons.check_circle_outline_rounded,
      AppColors.categoryWork,
      'Nothing slips',
      'A soft nudge when a task is actually due.',
    ),
    (
      Icons.emoji_events_rounded,
      AppColors.badgeLegendary,
      'Celebrate the wins',
      'The moments you earn, marked as they happen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.auroraGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF10243B),
                  size: 30,
                ),
              ),
            ).animate().fadeIn(duration: AppMotion.medium).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: AppMotion.standard,
                ),
            AppSpacing.gapMd,
            Text(
              'Want a gentle nudge?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            AppSpacing.gapXs,
            Text(
              'Atlas can remind you about the things you chose to tend. Quiet, '
              'occasional, and never about a streak you broke.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            AppSpacing.gapLg,
            for (final (icon, color, title, blurb) in _reasons) ...[
              _Reason(icon: icon, color: color, title: title, blurb: blurb),
              AppSpacing.gapSm,
            ],
            AppSpacing.gapSm,
            AppButton(
              label: 'Turn on reminders',
              icon: Icons.notifications_active_outlined,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
            ),
            AppSpacing.gapXs,
            AppButton(
              label: 'Not now',
              variant: AppButtonVariant.ghost,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(false);
              },
            ),
            AppSpacing.gapXs,
            Text(
              'You can change this any time in Settings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({
    required this.icon,
    required this.color,
    required this.title,
    required this.blurb,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                blurb,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
