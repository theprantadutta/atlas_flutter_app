import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/database/daos/task_dao.dart';
import 'package:atlas_flutter_app/data/models/analytics_data.dart';
import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/offline_manager.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
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
  late final OfflineManager _offlineManager;
  late final TaskDao _taskDao;
  late final AvatarDao _avatarDao;

  @override
  HomeState build() {
    _apiService = ref.read(apiServiceProvider);
    _offlineManager = ref.read(offlineManagerProvider);
    _taskDao = ref.read(taskDaoProvider);
    _avatarDao = ref.read(avatarDaoProvider);
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
      // Offline fallback: read from the current auth state
      final authState = ref.read(authProvider);
      return authState.user;
    }
  }

  Future<Avatar?> _fetchAvatar() async {
    try {
      final response = await _apiService.get('/avatar');
      return Avatar.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // Offline fallback: read from local AvatarDao
      try {
        final userId = _offlineManager.currentUserId ?? '';
        if (userId.isEmpty) return null;
        final local = await _avatarDao.getAvatarByUserId(userId);
        if (local != null) {
          return Avatar.fromJson(_driftAvatarToJson(local));
        }
      } catch (_) {
        // DAO also failed — give up
      }
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
      // Offline fallback: read pending tasks from local TaskDao
      try {
        final userId = _offlineManager.currentUserId ?? '';
        if (userId.isEmpty) return [];
        final localTasks = await _taskDao.getPendingTasks(userId);
        return localTasks
            .map((t) => Task.fromJson(_driftTaskToJson(t)))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<AnalyticsData?> _fetchAnalytics() async {
    try {
      final response = await _apiService.get('/analytics/dashboard');
      return AnalyticsData.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // No local fallback for analytics — requires server aggregation
      return null;
    }
  }

  // ─── Drift-to-JSON Helpers ──────────────────────────────────────

  Map<String, dynamic> _driftTaskToJson(dynamic driftTask) {
    return {
      'id': driftTask.id,
      'user_id': driftTask.userId,
      'title': driftTask.title,
      'description': driftTask.description,
      'type': driftTask.type,
      'category': driftTask.category,
      'xp_reward': driftTask.xpReward,
      'difficulty': driftTask.difficulty,
      'due_date': driftTask.dueDate?.toIso8601String(),
      'is_completed': driftTask.isCompleted,
      'streak_count': driftTask.streakCount,
      'last_completed_date': driftTask.lastCompletedDate?.toIso8601String(),
      'created_at': driftTask.createdAt.toIso8601String(),
      'updated_at': driftTask.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _driftAvatarToJson(dynamic driftAvatar) {
    return {
      'id': driftAvatar.id,
      'user_id': driftAvatar.userId,
      'name': driftAvatar.name,
      'level': driftAvatar.level,
      'current_xp': driftAvatar.currentXp,
      'strength': driftAvatar.strength,
      'wisdom': driftAvatar.wisdom,
      'intelligence': driftAvatar.intelligence,
      'appearance': driftAvatar.appearanceData,
      'unlocked_items': driftAvatar.unlockedItems,
      'created_at': driftAvatar.createdAt.toIso8601String(),
      'updated_at': driftAvatar.updatedAt.toIso8601String(),
    };
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
