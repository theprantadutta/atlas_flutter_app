import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/habit.dart';
import 'package:atlas_flutter_app/data/repositories/habit_repository.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';

// ─── Habits State ────────────────────────────────────────────────

class HabitsState {
  final List<Habit> habits;
  final HabitCategory? selectedCategory;
  final bool isLoading;
  final String? error;

  const HabitsState({
    this.habits = const [],
    this.selectedCategory,
    this.isLoading = true,
    this.error,
  });

  HabitsState copyWith({
    List<Habit>? habits,
    HabitCategory? selectedCategory,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearCategory = false,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Habits Notifier ─────────────────────────────────────────────

class HabitsNotifier extends Notifier<HabitsState> {
  late final HabitRepository _habitRepo;

  @override
  HabitsState build() {
    _habitRepo = ref.read(habitRepositoryProvider);
    Future.microtask(() => loadHabits());
    return const HabitsState();
  }

  /// Fetch all habits from the API.
  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final habits = await _habitRepo.getHabits();
      state = state.copyWith(habits: habits, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set the selected category filter.
  void setCategory(HabitCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Mark a habit as completed for today. Returns the API response.
  Future<Map<String, dynamic>?> completeHabit(String id) async {
    try {
      final response = await _habitRepo.completeHabit(id);

      // Toggle the local state
      final updatedList = state.habits.map((h) {
        if (h.id == id) {
          return h.copyWith(
            isCompletedToday: true,
            streakCount: h.streakCount + 1,
            totalCompletions: h.totalCompletions + 1,
          );
        }
        return h;
      }).toList();

      state = state.copyWith(habits: updatedList);
      return response;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Create a new habit.
  Future<bool> createHabit(Map<String, dynamic> data) async {
    try {
      final habit = await _habitRepo.createHabit(data);
      state = state.copyWith(habits: [habit, ...state.habits]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update an existing habit.
  Future<bool> updateHabit(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _habitRepo.updateHabit(id, data);
      final updatedList =
          state.habits.map((h) => h.id == id ? updated : h).toList();
      state = state.copyWith(habits: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a habit.
  Future<bool> deleteHabit(String id) async {
    try {
      await _habitRepo.deleteHabit(id);
      final updatedList = state.habits.where((h) => h.id != id).toList();
      state = state.copyWith(habits: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ─── Computed Getters ────────────────────────────────────────────

  /// Habits filtered by currently selected category.
  List<Habit> get filteredHabits {
    final habits = state.habits;
    if (state.selectedCategory == null) return habits;
    return habits.where((h) => h.category == state.selectedCategory).toList();
  }

  /// Number of habits completed today.
  int get todayCompletedCount {
    return filteredHabits.where((h) => h.isCompletedToday).length;
  }

  /// Total number of habits due today (daily + weekly habits).
  int get todayTotalCount {
    return filteredHabits.length;
  }

  /// Progress ratio for today (0.0 to 1.0).
  double get todayProgress {
    final total = todayTotalCount;
    if (total == 0) return 0.0;
    return (todayCompletedCount / total).clamp(0.0, 1.0);
  }

  /// Habits grouped by frequency.
  Map<String, List<Habit>> get habitsByFrequency {
    final grouped = <String, List<Habit>>{};
    for (final habit in filteredHabits) {
      final key = switch (habit.frequency) {
        HabitFrequency.daily => 'Daily',
        HabitFrequency.weekly => 'Weekly',
        HabitFrequency.weekdays => 'Weekdays',
        HabitFrequency.weekends => 'Weekends',
        HabitFrequency.custom => 'Custom',
      };
      grouped.putIfAbsent(key, () => []).add(habit);
    }
    return grouped;
  }

  /// Total streak across all habits (max streak for display).
  int get maxStreak {
    if (state.habits.isEmpty) return 0;
    return state.habits.fold(
      0,
      (max, h) => h.streakCount > max ? h.streakCount : max,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final habitsProvider = NotifierProvider<HabitsNotifier, HabitsState>(
  HabitsNotifier.new,
);
