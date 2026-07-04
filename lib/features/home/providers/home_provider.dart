import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';
import 'package:atlas_flutter_app/features/progress/providers/progress_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

// ─── Home view-models ───────────────────────────────────────────────
//
// The home screen is derived entirely from the local Drift database (the
// source of truth) plus the cached auth user. Nothing here touches the
// network — it recomputes reactively whenever a local table changes.

/// One thing to tend today (a real task row), shown on the home screen.
class TodayItem {
  const TodayItem({
    required this.id,
    required this.title,
    required this.note,
    required this.color,
    required this.icon,
    required this.xp,
    this.done = false,
  });

  final String id;
  final String title;
  final String note;
  final Color color;
  final IconData icon;
  final int xp;
  final bool done;
}

/// Aggregate state powering the home screen.
class HomeState {
  const HomeState({
    required this.greetingName,
    required this.level,
    required this.xp,
    required this.xpForNext,
    required this.streak,
    required this.worldProgress,
    required this.today,
  });

  final String greetingName;
  final int level;
  final int xp;
  final int xpForNext;
  final int streak;
  final double worldProgress; // 0..1, how lush the world is
  final List<TodayItem> today;

  int get doneCount => today.where((t) => t.done).length;
  int get dueCount => today.where((t) => !t.done).length;
  double get dayProgress => today.isEmpty ? 0 : doneCount / today.length;
  int get xpToday => today.where((t) => t.done).fold(0, (s, t) => s + t.xp);

  static const empty = HomeState(
    greetingName: 'friend',
    level: 1,
    xp: 0,
    xpForNext: 1000,
    streak: 0,
    worldProgress: 0,
    today: [],
  );
}

/// The visual identity (colour + icon) for a task category.
({Color color, IconData icon}) categoryVisual(String category) {
  switch (category.toLowerCase()) {
    case 'mindfulness':
      return (
        color: AppColors.categoryMindfulness,
        icon: Icons.self_improvement_rounded,
      );
    case 'fitness':
      return (
        color: AppColors.categoryFitness,
        icon: Icons.directions_run_rounded,
      );
    case 'health':
      return (color: AppColors.categoryHealth, icon: Icons.favorite_rounded);
    case 'learning':
      return (color: AppColors.categoryLearning, icon: Icons.menu_book_rounded);
    case 'creative':
      return (color: AppColors.categoryCreative, icon: Icons.brush_rounded);
    case 'social':
      return (color: AppColors.categorySocial, icon: Icons.people_alt_rounded);
    case 'finance':
      return (
        color: AppColors.categoryFinance,
        icon: Icons.account_balance_wallet_rounded,
      );
    case 'work':
      return (color: AppColors.categoryWork, icon: Icons.work_outline_rounded);
    default:
      return (color: AppColors.primary, icon: Icons.check_circle_outline_rounded);
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Home, derived from Drift + the cached auth user. Returns synchronously,
/// falling back to sensible defaults while the local streams warm up.
final homeProvider = Provider.autoDispose<HomeState>((ref) {
  final user = ref.watch(authProvider).user;
  final tasks = ref.watch(tasksStreamProvider).value ?? const <Task>[];
  final progress =
      ref.watch(progressEntriesStreamProvider).value ??
          const <ProgressEntry>[];
  // Watched so the avatar's existence keeps the stream (and its seed) alive.
  ref.watch(avatarStreamProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // "Today" = tasks still to do, plus anything finished today.
  final todayTasks = tasks.where((t) {
    if (!t.isCompleted) return true;
    final done = t.lastCompletedDate;
    return done != null && _isSameDay(done, today);
  }).toList()
    ..sort((a, b) {
      // Unfinished first, then most-recently-created.
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });

  final todayItems = todayTasks.map((t) {
    final visual = categoryVisual(t.category);
    return TodayItem(
      id: t.id,
      title: t.title,
      note: (t.description == null || t.description!.isEmpty)
          ? 'Tap to tend'
          : t.description!,
      color: visual.color,
      icon: visual.icon,
      xp: t.xpReward,
      done: t.isCompleted,
    );
  }).toList();

  // World lushness = how many of the last 7 days you showed up.
  var activeDays = 0;
  for (var i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    final hit =
        progress.any((p) => _isSameDay(p.date, day) && p.xpGained > 0);
    if (hit) activeDays++;
  }
  final worldProgress = activeDays / 7.0;

  final firstName = (user?.fullName.trim().isNotEmpty ?? false)
      ? user!.fullName.trim().split(RegExp(r'\s+')).first
      : 'friend';
  final totalXp = user?.totalXp ?? 0;

  return HomeState(
    greetingName: firstName,
    level: user?.level ?? 1,
    xp: totalXp % 1000,
    xpForNext: 1000,
    streak: user?.currentStreak ?? 0,
    worldProgress: worldProgress.clamp(0.0, 1.0),
    today: todayItems,
  );
});
