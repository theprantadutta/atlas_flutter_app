import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_engine.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

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
  final optedIn = await showAtlasSheet<bool>(
    context,
    builder: (_) => const _NotificationPrimerSheet(),
  );

  if (optedIn != true) return false;

  // One OS permission covers both kinds of notification, so this single prompt
  // is the whole ask: POST_NOTIFICATIONS on Android, UNUserNotificationCenter
  // on iOS. No exact-alarm permission: reminders are scheduled inexactly.
  final granted =
      await ref.read(localNotificationServiceProvider).requestPermissions();
  _log.i('Notification permission after primer: $granted');

  if (granted) {
    // Push needs its token fetched and registered now. Without this the user
    // said yes but stays unreachable until the next cold start, because the
    // token is only picked up at launch when permission already exists.
    await ref.read(fcmServiceProvider).onPermissionGranted();
    // Reminders were waiting for this; schedule them now.
    replanReminders(ref);
    return true;
  }

  // Saying yes here and getting nothing is the confusing case. Android stops
  // showing its dialog once a denial is marked USER_FIXED, so requesting again
  // returns false without any UI at all; from the user's side the button simply
  // did nothing. Say where the switch actually lives instead.
  if (context.mounted) {
    AtlasToast.warning(
      context,
      'Notifications are blocked for Atlas. You can turn them on in your '
      'device settings.',
    );
  }
  return false;
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

  /// What Atlas actually sends, in the order it matters. Each has its own
  /// switch in Settings.
  static const _reasons = <(IconData, Color, String, String)>[
    (
      Symbols.repeat_rounded,
      AppColors.leaf,
      'Keep your rhythm',
      'A reminder at the time you set on a habit, until it’s done.',
    ),
    (
      Symbols.task_alt_rounded,
      AppColors.sky,
      'Nothing slips',
      'A soft nudge when a task with a time is due.',
    ),
    (
      Symbols.wb_twilight_rounded,
      AppColors.amber,
      'A calm morning',
      'A look at your day, and Aurora’s letter on Sundays.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AtlasSpark(size: 56, animated: true)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Want a gentle nudge?',
            textAlign: TextAlign.center,
            style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Atlas only speaks at times you chose, about the things you chose to '
            'tend. Never about a streak or a missed day.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: p.textBody),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (icon, color, title, blurb) in _reasons) ...[
            AtlasRow(
              minHeight: 64,
              leading: IconTile(style: CategoryStyle(icon, color)),
              title: title,
              metaWidget: Text(blurb, style: AppTypography.meta.copyWith(color: p.textMuted)),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Turn on reminders',
            icon: Symbols.notifications_active_rounded,
            height: 56,
            expand: true,
            haptic: PressHaptic.medium,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.xs),
          PillButton(
            label: 'Not now',
            variant: PillVariant.track,
            height: 56,
            expand: true,
            haptic: PressHaptic.selection,
            onTap: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You can change this any time in Settings.',
            textAlign: TextAlign.center,
            style: AppTypography.meta.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
