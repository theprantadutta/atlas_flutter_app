import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/achievement.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/repositories/achievement_repository.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';

// ─── Achievements State ──────────────────────────────────────────

class AchievementsState {
  final List<Achievement> achievements;
  final AchievementType? typeFilter;
  final bool? unlockedFilter;
  final bool isGridView;
  final bool isLoading;
  final String? error;

  const AchievementsState({
    this.achievements = const [],
    this.typeFilter,
    this.unlockedFilter,
    this.isGridView = true,
    this.isLoading = true,
    this.error,
  });

  AchievementsState copyWith({
    List<Achievement>? achievements,
    AchievementType? typeFilter,
    bool? unlockedFilter,
    bool? isGridView,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearTypeFilter = false,
    bool clearUnlockedFilter = false,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      unlockedFilter:
          clearUnlockedFilter ? null : (unlockedFilter ?? this.unlockedFilter),
      isGridView: isGridView ?? this.isGridView,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Filtered achievements list.
  List<Achievement> get filteredAchievements {
    var result = achievements;

    if (typeFilter != null) {
      result =
          result.where((a) => a.achievementType == typeFilter).toList();
    }

    if (unlockedFilter != null) {
      result = result.where((a) => a.isUnlocked == unlockedFilter).toList();
    }

    return result;
  }

  /// Total achievement count.
  int get totalCount => achievements.length;

  /// Unlocked count.
  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

  /// Tier breakdown map.
  Map<String, int> get tierBreakdown {
    final map = <String, int>{
      'bronze': 0,
      'common': 0,
      'rare': 0,
      'epic': 0,
      'legendary': 0,
    };
    for (final a in achievements.where((a) => a.isUnlocked)) {
      final tier = a.badgeTier;
      map[tier] = (map[tier] ?? 0) + 1;
    }
    return map;
  }
}

// ─── Achievements Notifier ───────────────────────────────────────

class AchievementsNotifier extends Notifier<AchievementsState> {
  late final AchievementRepository _achievementRepository;

  @override
  AchievementsState build() {
    _achievementRepository = ref.read(achievementRepositoryProvider);
    Future.microtask(() => loadAchievements());
    return const AchievementsState();
  }

  Future<void> loadAchievements() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final achievements = await _achievementRepository.getAchievements();
      state = state.copyWith(achievements: achievements, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setTypeFilter(AchievementType? type) {
    if (type == state.typeFilter) {
      state = state.copyWith(clearTypeFilter: true);
    } else {
      state = state.copyWith(typeFilter: type);
    }
  }

  void setUnlockedFilter(bool? unlocked) {
    if (unlocked == state.unlockedFilter) {
      state = state.copyWith(clearUnlockedFilter: true);
    } else {
      state = state.copyWith(unlockedFilter: unlocked);
    }
  }

  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
  AchievementsNotifier.new,
);
