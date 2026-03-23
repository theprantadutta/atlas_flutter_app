import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/analytics_data.dart';
import 'package:atlas_flutter_app/data/repositories/analytics_repository.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';

// ─── Analytics Period ────────────────────────────────────────────

enum AnalyticsPeriod { week, month, allTime }

// ─── Analytics State ─────────────────────────────────────────────

class AnalyticsState {
  final AnalyticsData? data;
  final AnalyticsPeriod period;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.data,
    this.period = AnalyticsPeriod.week,
    this.isLoading = true,
    this.error,
  });

  AnalyticsState copyWith({
    AnalyticsData? data,
    AnalyticsPeriod? period,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AnalyticsState(
      data: data ?? this.data,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Analytics Notifier ──────────────────────────────────────────

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  late final AnalyticsRepository _analyticsRepository;

  @override
  AnalyticsState build() {
    _analyticsRepository = ref.read(analyticsRepositoryProvider);
    Future.microtask(() => loadAnalytics());
    return const AnalyticsState();
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _analyticsRepository.getDashboard();
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setPeriod(AnalyticsPeriod period) {
    state = state.copyWith(period: period);
    loadAnalytics();
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final analyticsProvider =
    NotifierProvider<AnalyticsNotifier, AnalyticsState>(
  AnalyticsNotifier.new,
);
