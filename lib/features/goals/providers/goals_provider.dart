import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/goal.dart';
import 'package:atlas_flutter_app/data/repositories/goal_repository.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';

// ─── Goal Filter ─────────────────────────────────────────────────

enum GoalFilter { all, active, completed, overdue, dueSoon }

// ─── Goals State ─────────────────────────────────────────────────

class GoalsState {
  final List<Goal> goals;
  final GoalFilter activeFilter;
  final GoalCategory? selectedCategory;
  final bool isLoading;
  final String? error;

  const GoalsState({
    this.goals = const [],
    this.activeFilter = GoalFilter.all,
    this.selectedCategory,
    this.isLoading = true,
    this.error,
  });

  GoalsState copyWith({
    List<Goal>? goals,
    GoalFilter? activeFilter,
    GoalCategory? selectedCategory,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearCategory = false,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Filtered goals based on the active filter and selected category.
  List<Goal> get filteredGoals {
    var result = goals;

    // Apply category filter
    if (selectedCategory != null) {
      result = result.where((g) => g.category == selectedCategory).toList();
    }

    // Apply status filter
    return switch (activeFilter) {
      GoalFilter.all => result,
      GoalFilter.active => result
          .where((g) =>
              g.status == GoalStatus.inProgress ||
              g.status == GoalStatus.notStarted)
          .toList(),
      GoalFilter.completed =>
        result.where((g) => g.status == GoalStatus.completed).toList(),
      GoalFilter.overdue => result
          .where(
              (g) => g.deadline != null && g.deadline!.isBefore(DateTime.now()) && g.status != GoalStatus.completed)
          .toList(),
      GoalFilter.dueSoon => result
          .where((g) =>
              g.deadline != null &&
              g.deadline!.isAfter(DateTime.now()) &&
              g.deadline!.isBefore(DateTime.now().add(const Duration(days: 7))) &&
              g.status != GoalStatus.completed)
          .toList(),
    };
  }
}

// ─── Goals Notifier ──────────────────────────────────────────────

class GoalsNotifier extends Notifier<GoalsState> {
  late final GoalRepository _goalRepository;

  @override
  GoalsState build() {
    _goalRepository = ref.read(goalRepositoryProvider);
    Future.microtask(() => loadGoals());
    return const GoalsState();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final goals = await _goalRepository.getGoals();
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(GoalFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setCategory(GoalCategory? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  Future<void> createGoal(Map<String, dynamic> data) async {
    try {
      final goal = await _goalRepository.createGoal(data);
      state = state.copyWith(goals: [...state.goals, goal]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _goalRepository.updateGoal(id, data);
      final goals =
          state.goals.map((g) => g.id == id ? updated : g).toList();
      state = state.copyWith(goals: goals);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateProgress(String id, double progress) async {
    try {
      await _goalRepository.updateGoalProgress(
        id,
        {'progress': progress},
      );
      final goals = state.goals
          .map((g) => g.id == id ? g.copyWith(progress: progress) : g)
          .toList();
      state = state.copyWith(goals: goals);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _goalRepository.deleteGoal(id);
      final goals = state.goals.where((g) => g.id != id).toList();
      state = state.copyWith(goals: goals);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final goalsProvider = NotifierProvider<GoalsNotifier, GoalsState>(
  GoalsNotifier.new,
);
