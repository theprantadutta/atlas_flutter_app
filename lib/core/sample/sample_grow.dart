import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Dummy data for the Grow hub (Tasks / Habits / Goals).
/// TODO(backend): replace with real repositories.

enum GrowSegment { tasks, habits, goals }

// ─── Tasks ──────────────────────────────────────────────────────────

class SampleTask {
  const SampleTask({
    required this.id,
    required this.title,
    required this.note,
    required this.color,
    required this.icon,
    required this.xp,
    required this.cadence,
    this.done = false,
  });

  final String id;
  final String title;
  final String note;
  final Color color;
  final IconData icon;
  final int xp;
  final String cadence; // Daily / Weekly / Long-term
  final bool done;

  SampleTask copyWith({bool? done}) => SampleTask(
        id: id,
        title: title,
        note: note,
        color: color,
        icon: icon,
        xp: xp,
        cadence: cadence,
        done: done ?? this.done,
      );
}

class TasksNotifier extends Notifier<List<SampleTask>> {
  @override
  List<SampleTask> build() => const [
        SampleTask(
            id: 't1',
            title: 'Reply to Sam',
            note: 'Due today',
            color: AppColors.categoryWork,
            icon: Icons.mail_outline_rounded,
            xp: 25,
            cadence: 'Daily'),
        SampleTask(
            id: 't2',
            title: 'Stretch for 10 min',
            note: 'Loosen up',
            color: AppColors.categoryFitness,
            icon: Icons.accessibility_new_rounded,
            xp: 30,
            cadence: 'Daily',
            done: true),
        SampleTask(
            id: 't3',
            title: 'Plan the week',
            note: 'Sunday ritual',
            color: AppColors.categoryMindfulness,
            icon: Icons.event_note_rounded,
            xp: 45,
            cadence: 'Weekly'),
        SampleTask(
            id: 't4',
            title: 'Tidy the desk',
            note: 'A clear space',
            color: AppColors.categoryCreative,
            icon: Icons.cleaning_services_rounded,
            xp: 20,
            cadence: 'Weekly'),
        SampleTask(
            id: 't5',
            title: 'Read "Atomic Habits"',
            note: '38% through',
            color: AppColors.categoryLearning,
            icon: Icons.menu_book_rounded,
            xp: 90,
            cadence: 'Long-term'),
      ];

  void toggle(String id) => state = [
        for (final t in state)
          if (t.id == id) t.copyWith(done: !t.done) else t,
      ];
}

final tasksProvider =
    NotifierProvider<TasksNotifier, List<SampleTask>>(TasksNotifier.new);

// ─── Habits ─────────────────────────────────────────────────────────

class SampleHabit {
  const SampleHabit({
    required this.id,
    required this.name,
    required this.note,
    required this.color,
    required this.icon,
    required this.frequency,
    required this.streak,
    required this.week,
    this.doneToday = false,
  });

  final String id;
  final String name;
  final String note;
  final Color color;
  final IconData icon;
  final String frequency; // Daily / Weekly
  final int streak;
  final List<bool> week; // last 7 days
  final bool doneToday;

  SampleHabit copyWith({bool? doneToday, int? streak, List<bool>? week}) =>
      SampleHabit(
        id: id,
        name: name,
        note: note,
        color: color,
        icon: icon,
        frequency: frequency,
        streak: streak ?? this.streak,
        week: week ?? this.week,
        doneToday: doneToday ?? this.doneToday,
      );
}

class HabitsNotifier extends Notifier<List<SampleHabit>> {
  @override
  List<SampleHabit> build() => const [
        SampleHabit(
            id: 'h1',
            name: 'Meditate',
            note: '10 min of calm',
            color: AppColors.categoryMindfulness,
            icon: Icons.self_improvement_rounded,
            frequency: 'Daily',
            streak: 12,
            week: [true, true, true, false, true, true, true],
            doneToday: true),
        SampleHabit(
            id: 'h2',
            name: 'Drink water',
            note: '8 glasses',
            color: AppColors.categoryHealth,
            icon: Icons.water_drop_rounded,
            frequency: 'Daily',
            streak: 5,
            week: [true, false, true, true, true, false, true],
            doneToday: true),
        SampleHabit(
            id: 'h3',
            name: 'Move your body',
            note: 'Any movement counts',
            color: AppColors.categoryFitness,
            icon: Icons.directions_run_rounded,
            frequency: 'Daily',
            streak: 3,
            week: [false, true, true, false, true, false, false]),
        SampleHabit(
            id: 'h4',
            name: 'Call a friend',
            note: 'Stay connected',
            color: AppColors.categorySocial,
            icon: Icons.favorite_border_rounded,
            frequency: 'Weekly',
            streak: 2,
            week: [false, false, true, false, false, false, false]),
      ];

  void toggle(String id) => state = [
        for (final h in state)
          if (h.id == id)
            h.copyWith(
              doneToday: !h.doneToday,
              streak: h.doneToday ? h.streak - 1 : h.streak + 1,
            )
          else
            h,
      ];
}

final habitsProvider =
    NotifierProvider<HabitsNotifier, List<SampleHabit>>(HabitsNotifier.new);

// ─── Goals ──────────────────────────────────────────────────────────

class SampleGoal {
  const SampleGoal({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required this.progress,
    required this.dueLabel,
    required this.status,
  });

  final String id;
  final String title;
  final Color color;
  final IconData icon;
  final double progress; // 0..1
  final String dueLabel;
  final String status; // On track / Due soon / Completed
}

final goalsProvider = Provider<List<SampleGoal>>((ref) => const [
      SampleGoal(
          id: 'g1',
          title: 'Run a half marathon',
          color: AppColors.categoryFitness,
          icon: Icons.directions_run_rounded,
          progress: 0.62,
          dueLabel: 'in 6 weeks',
          status: 'On track'),
      SampleGoal(
          id: 'g2',
          title: 'Read 24 books this year',
          color: AppColors.categoryLearning,
          icon: Icons.auto_stories_rounded,
          progress: 0.46,
          dueLabel: 'Dec 31',
          status: 'On track'),
      SampleGoal(
          id: 'g3',
          title: 'Save for a trip',
          color: AppColors.categoryFinance,
          icon: Icons.savings_rounded,
          progress: 0.8,
          dueLabel: 'in 3 weeks',
          status: 'Due soon'),
      SampleGoal(
          id: 'g4',
          title: 'Learn watercolor basics',
          color: AppColors.categoryCreative,
          icon: Icons.palette_rounded,
          progress: 1.0,
          dueLabel: 'done',
          status: 'Completed'),
    ]);
