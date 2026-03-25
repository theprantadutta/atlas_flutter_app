import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/repositories/task_repository.dart';

// ─── Tasks State ─────────────────────────────────────────────────

class TasksState {
  final List<Task> tasks;
  final TaskType? activeTab;
  final TaskCategory? selectedCategory;
  final String? searchQuery;
  final bool isLoading;
  final String? error;
  final bool showCompletedSection;

  const TasksState({
    this.tasks = const [],
    this.activeTab,
    this.selectedCategory,
    this.searchQuery,
    this.isLoading = true,
    this.error,
    this.showCompletedSection = false,
  });

  TasksState copyWith({
    List<Task>? tasks,
    TaskType? activeTab,
    TaskCategory? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool? showCompletedSection,
    bool clearError = false,
    bool clearActiveTab = false,
    bool clearCategory = false,
    bool clearSearch = false,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      activeTab: clearActiveTab ? null : (activeTab ?? this.activeTab),
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      showCompletedSection:
          showCompletedSection ?? this.showCompletedSection,
    );
  }
}

// ─── Tasks Notifier ──────────────────────────────────────────────

class TasksNotifier extends Notifier<TasksState> {
  late final TaskRepository _taskRepo;

  @override
  TasksState build() {
    _taskRepo = ref.read(taskRepositoryProvider);
    Future.microtask(() => loadTasks());
    return const TasksState();
  }

  /// Fetch all tasks from the API.
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final tasks = await _taskRepo.getTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set the active tab filter (Daily / Weekly / Long-Term).
  void setTab(TaskType? type) {
    if (type == null) {
      state = state.copyWith(clearActiveTab: true);
    } else {
      state = state.copyWith(activeTab: type);
    }
  }

  /// Set the selected category filter.
  void setCategory(TaskCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Set the search query.
  void setSearch(String? query) {
    if (query == null || query.isEmpty) {
      state = state.copyWith(clearSearch: true);
    } else {
      state = state.copyWith(searchQuery: query);
    }
  }

  /// Create a new task.
  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      final task = await _taskRepo.createTask(data);
      state = state.copyWith(tasks: [task, ...state.tasks]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update an existing task.
  Future<bool> updateTask(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _taskRepo.updateTask(id, data);
      final updatedList =
          state.tasks.map((t) => t.id == id ? updated : t).toList();
      state = state.copyWith(tasks: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Mark a task as completed and return the API response.
  Future<Map<String, dynamic>?> completeTask(String id) async {
    try {
      final response = await _taskRepo.completeTask(id);
      final updatedList = state.tasks
          .map((t) => t.id == id ? t.copyWith(isCompleted: true) : t)
          .toList();
      state = state.copyWith(tasks: updatedList);
      return response;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Toggle visibility of the completed tasks section.
  void toggleShowCompleted() {
    state = state.copyWith(
      showCompletedSection: !state.showCompletedSection,
    );
  }

  /// Delete a task.
  Future<bool> deleteTask(String id) async {
    try {
      await _taskRepo.deleteTask(id);
      final updatedList = state.tasks.where((t) => t.id != id).toList();
      state = state.copyWith(tasks: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get filtered tasks based on current state filters.
  List<Task> get filteredTasks {
    var result = state.tasks;

    // Filter by active tab (task type)
    if (state.activeTab != null) {
      result = result.where((t) => t.type == state.activeTab).toList();
    }

    // Filter by category
    if (state.selectedCategory != null) {
      result =
          result.where((t) => t.category == state.selectedCategory).toList();
    }

    // Filter by search query
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      final query = state.searchQuery!.toLowerCase();
      result = result.where((t) {
        return t.title.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
  }

  /// Filtered tasks that are NOT completed (pending).
  List<Task> get pendingFilteredTasks {
    return filteredTasks.where((t) => !t.isCompleted).toList();
  }

  /// Filtered tasks that ARE completed.
  List<Task> get completedFilteredTasks {
    return filteredTasks.where((t) => t.isCompleted).toList();
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(
  TasksNotifier.new,
);
