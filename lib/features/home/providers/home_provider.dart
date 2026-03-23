import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/analytics_data.dart';
import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

// ─── Home State ───────────────────────────────────────────────────

class HomeState {
  final User? user;
  final Avatar? avatar;
  final List<Task> todayTasks;
  final AnalyticsData? analyticsData;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.user,
    this.avatar,
    this.todayTasks = const [],
    this.analyticsData,
    this.isLoading = true,
    this.error,
  });

  HomeState copyWith({
    User? user,
    Avatar? avatar,
    List<Task>? todayTasks,
    AnalyticsData? analyticsData,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearAvatar = false,
  }) {
    return HomeState(
      user: user ?? this.user,
      avatar: clearAvatar ? null : (avatar ?? this.avatar),
      todayTasks: todayTasks ?? this.todayTasks,
      analyticsData: analyticsData ?? this.analyticsData,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Home Notifier ────────────────────────────────────────────────

class HomeNotifier extends Notifier<HomeState> {
  late final ApiService _apiService;

  @override
  HomeState build() {
    _apiService = ref.read(apiServiceProvider);
    Future.microtask(() => loadDashboard());
    return const HomeState();
  }

  /// Load all dashboard data concurrently.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fire all requests in parallel
      final results = await Future.wait([
        _fetchUser(),
        _fetchAvatar(),
        _fetchTodayTasks(),
        _fetchAnalytics(),
      ], eagerError: false);

      state = HomeState(
        user: results[0] as User?,
        avatar: results[1] as Avatar?,
        todayTasks: results[2] as List<Task>? ?? [],
        analyticsData: results[3] as AnalyticsData?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<User?> _fetchUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Avatar?> _fetchAvatar() async {
    try {
      final response = await _apiService.get('/avatar');
      return Avatar.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // 404 is expected for new users who haven't created an avatar yet
      return null;
    }
  }

  Future<List<Task>> _fetchTodayTasks() async {
    try {
      final response = await _apiService.get(
        '/tasks',
        queryParameters: {'status': 'pending'},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<AnalyticsData?> _fetchAnalytics() async {
    try {
      final response = await _apiService.get('/analytics/dashboard');
      return AnalyticsData.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // May fail for new users with no data yet
      return null;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
