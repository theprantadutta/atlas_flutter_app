import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// The tone of a nudge shapes its accent — always caring, never shaming.
enum NudgeTone { celebrate, gentle, encourage }

/// A single proactive message from Aurora, derived from local Drift data.
class AuroraNudge {
  const AuroraNudge({
    required this.key,
    required this.tone,
    required this.icon,
    required this.message,
    this.prompt,
  });

  /// Stable identity so a dismissal sticks for this session.
  final String key;
  final NudgeTone tone;
  final IconData icon;
  final String message;

  /// If set, tapping "Talk about it" opens Aurora chat with this seed.
  final String? prompt;

  Color accent() => switch (tone) {
        NudgeTone.celebrate => AppColors.tertiaryLight,
        NudgeTone.gentle => AppColors.secondary,
        NudgeTone.encourage => AppColors.xpPrimary,
      };
}

/// Session-scoped set of dismissed nudge keys.
final dismissedNudgesProvider =
    NotifierProvider<DismissedNudges, Set<String>>(DismissedNudges.new);

class DismissedNudges extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void dismiss(String key) => state = {...state, key};
}

/// The single most relevant caring nudge right now (or null). Computed entirely
/// from the local database, so it works fully offline. Priority: celebrate a
/// strong day → gently welcome back after a broken streak → check in on a
/// neglected goal → encourage when the day is full.
/// Returns null when the user has turned nudges off in Aurora's settings; the
/// card is the one thing Aurora does unprompted, so it stays opt-out.
final auroraNudgeProvider = Provider.autoDispose<AuroraNudge?>((ref) {
  if (!ref.watch(auroraPreferencesProvider).nudgesEnabled) return null;

  final habits = ref.watch(habitsStreamProvider).value ?? const [];
  final goals = ref.watch(goalsStreamProvider).value ?? const [];
  final tasks = ref.watch(tasksStreamProvider).value ?? const [];
  final dismissed = ref.watch(dismissedNudgesProvider);

  AuroraNudge? pick;

  // 1. Celebrate: several habits already tended today.
  final tendedToday = habits.where((h) => h.isCompletedToday).length;
  if (tendedToday >= 3) {
    pick = AuroraNudge(
      key: 'celebrate-today-$tendedToday',
      tone: NudgeTone.celebrate,
      icon: Icons.celebration_rounded,
      message:
          'You’ve tended $tendedToday habits today, and your world is glowing. '
          'Lovely care.',
      prompt: 'I had a good day today. Celebrate with me?',
    );
  }

  // 2. Gentle welcome back: a habit that once had a streak has reset to zero.
  if (pick == null) {
    final broken = habits.where((h) => h.longestStreak >= 3 && h.streakCount == 0);
    if (broken.isNotEmpty) {
      final h = broken.first;
      pick = AuroraNudge(
        key: 'streak-reset-${h.id}',
        tone: NudgeTone.gentle,
        icon: Icons.self_improvement_rounded,
        message:
            'Your “${h.title}” streak paused, and that’s completely okay. '
            'Rest is part of it. Want to begin again, gently?',
        prompt: 'My “${h.title}” streak broke. Can you help me restart gently?',
      );
    }
  }

  // 3. Check in on a goal that’s been quiet for a while.
  if (pick == null) {
    final now = DateTime.now();
    final stale = goals.where((g) =>
        g.status == 'inProgress' &&
        g.progress > 0 &&
        g.progress < 1 &&
        now.difference(g.updatedAt).inDays >= 5);
    if (stale.isNotEmpty) {
      final g = stale.first;
      pick = AuroraNudge(
        key: 'goal-quiet-${g.id}',
        tone: NudgeTone.encourage,
        icon: Icons.flag_rounded,
        message:
            '“${g.title}” has been quiet lately. No pressure, even a tiny step '
            'counts. Shall we look at it together?',
        prompt: 'Help me take a small step on my goal “${g.title}”.',
      );
    }
  }

  // 4. Encourage when the day looks full.
  if (pick == null) {
    final due = tasks.where((t) => !t.isCompleted).length;
    if (due >= 5) {
      pick = AuroraNudge(
        key: 'full-day-$due',
        tone: NudgeTone.encourage,
        icon: Icons.spa_rounded,
        message:
            'There’s a lot on today. You don’t have to do it all. Just pick '
            'one small thing to begin with.',
        prompt: 'I feel a bit overwhelmed by today. Where should I start?',
      );
    }
  }

  if (pick == null || dismissed.contains(pick.key)) return null;
  return pick;
});
