import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/repositories/avatar_repository.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

// ─── Profile State ───────────────────────────────────────────────

class ProfileState {
  final User? user;
  final Avatar? avatar;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.user,
    this.avatar,
    this.stats,
    this.isLoading = true,
    this.error,
  });

  ProfileState copyWith({
    User? user,
    Avatar? avatar,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      avatar: avatar ?? this.avatar,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Profile Notifier ────────────────────────────────────────────

class ProfileNotifier extends Notifier<ProfileState> {
  late final ApiService _apiService;
  late final AvatarRepository _avatarRepository;

  @override
  ProfileState build() {
    _apiService = ref.read(apiServiceProvider);
    _avatarRepository = ref.read(avatarRepositoryProvider);
    Future.microtask(() => loadProfile());
    return const ProfileState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _fetchUser(),
        _fetchAvatar(),
        _fetchStats(),
      ], eagerError: false);

      state = ProfileState(
        user: results[0] as User?,
        avatar: results[1] as Avatar?,
        stats: results[2] as Map<String, dynamic>?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      return await _avatarRepository.getAvatar();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchStats() async {
    try {
      final response = await _apiService.get('/analytics/dashboard');
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
