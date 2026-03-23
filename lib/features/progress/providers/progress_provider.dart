import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/progress_entry.dart';
import 'package:atlas_flutter_app/data/repositories/progress_repository.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';

// ─── Progress State ──────────────────────────────────────────────

class ProgressState {
  final List<ProgressEntry> entries;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final String? error;

  const ProgressState({
    this.entries = const [],
    this.startDate,
    this.endDate,
    this.isLoading = true,
    this.error,
  });

  ProgressState copyWith({
    List<ProgressEntry>? entries,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProgressState(
      entries: entries ?? this.entries,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Total XP across all entries.
  int get totalXp => entries.fold<int>(0, (sum, e) => sum + e.xpGained);

  /// Total tasks completed across all entries.
  int get totalTasksCompleted =>
      entries.fold<int>(0, (sum, e) => sum + e.tasksCompleted);

  /// Average XP per day.
  double get avgXpPerDay {
    if (entries.isEmpty) return 0;
    return totalXp / entries.length;
  }
}

// ─── Progress Notifier ───────────────────────────────────────────

class ProgressNotifier extends Notifier<ProgressState> {
  late final ProgressRepository _progressRepository;

  @override
  ProgressState build() {
    _progressRepository = ref.read(progressRepositoryProvider);

    // Default range: last 30 days
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(days: 30));

    Future.microtask(() => _loadWithDates(defaultStart, now));

    return ProgressState(
      startDate: defaultStart,
      endDate: now,
    );
  }

  Future<void> loadProgress() async {
    await _loadWithDates(state.startDate, state.endDate);
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await _loadWithDates(start, end);
  }

  Future<void> _loadWithDates(DateTime? start, DateTime? end) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _progressRepository.getProgress(
        startDate: start?.toIso8601String().split('T').first,
        endDate: end?.toIso8601String().split('T').first,
      );
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final progressProvider =
    NotifierProvider<ProgressNotifier, ProgressState>(
  ProgressNotifier.new,
);
