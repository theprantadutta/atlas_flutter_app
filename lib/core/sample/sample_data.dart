import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Dummy/sample data for the redesign phase. The UI runs entirely on this so we
/// can perfect the look before wiring the real backend.
///
/// TODO(backend): replace these providers with the real repositories/providers.

/// A stand-in signed-in user for demo mode.
User sampleUser() => User(
      id: 'demo-user',
      email: 'pranta@atlas.app',
      fullName: 'Pranta',
      level: 7,
      totalXp: 4820,
      currentStreak: 12,
      longestStreak: 21,
      isEmailVerified: true,
      authProvider: 'email',
      createdAt: DateTime(2026, 1, 1),
      lastActiveDate: DateTime(2026, 6, 28),
    );

/// One thing to do today (a task or a habit), shown on the home screen.
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

  TodayItem copyWith({bool? done}) => TodayItem(
        id: id,
        title: title,
        note: note,
        color: color,
        icon: icon,
        xp: xp,
        done: done ?? this.done,
      );
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

  HomeState copyWith({List<TodayItem>? today}) => HomeState(
        greetingName: greetingName,
        level: level,
        xp: xp,
        xpForNext: xpForNext,
        streak: streak,
        worldProgress: worldProgress,
        today: today ?? this.today,
      );
}

class HomeSampleNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => HomeState(
        greetingName: 'Pranta',
        level: 7,
        xp: 320,
        xpForNext: 500,
        streak: 12,
        worldProgress: 0.62,
        today: const [
          TodayItem(
            id: 'meditate',
            title: 'Meditate',
            note: '10 minutes of calm',
            color: AppColors.categoryMindfulness,
            icon: Icons.self_improvement_rounded,
            xp: 30,
            done: true,
          ),
          TodayItem(
            id: 'read',
            title: 'Read',
            note: '20 pages',
            color: AppColors.categoryLearning,
            icon: Icons.menu_book_rounded,
            xp: 25,
          ),
          TodayItem(
            id: 'walk',
            title: 'Walk 5k',
            note: 'Move your body',
            color: AppColors.categoryFitness,
            icon: Icons.directions_walk_rounded,
            xp: 40,
          ),
          TodayItem(
            id: 'water',
            title: 'Drink water',
            note: '8 glasses today',
            color: AppColors.categoryHealth,
            icon: Icons.water_drop_rounded,
            xp: 15,
            done: true,
          ),
          TodayItem(
            id: 'journal',
            title: 'Journal',
            note: 'A few honest lines',
            color: AppColors.categoryCreative,
            icon: Icons.edit_note_rounded,
            xp: 20,
          ),
        ],
      );

  /// Toggle an item's completion (local, demo-only).
  void toggle(String id) {
    state = state.copyWith(
      today: [
        for (final t in state.today)
          if (t.id == id) t.copyWith(done: !t.done) else t,
      ],
    );
  }
}

final homeSampleProvider =
    NotifierProvider<HomeSampleNotifier, HomeState>(HomeSampleNotifier.new);
