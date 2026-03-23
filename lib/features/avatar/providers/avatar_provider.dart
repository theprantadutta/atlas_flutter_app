import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/repositories/avatar_repository.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';

// ─── Avatar State ────────────────────────────────────────────────

class AvatarState {
  final Avatar? avatar;
  final int activeTab;
  final bool isLoading;
  final String? error;

  const AvatarState({
    this.avatar,
    this.activeTab = 0,
    this.isLoading = true,
    this.error,
  });

  AvatarState copyWith({
    Avatar? avatar,
    int? activeTab,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearAvatar = false,
  }) {
    return AvatarState(
      avatar: clearAvatar ? null : (avatar ?? this.avatar),
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Avatar Notifier ─────────────────────────────────────────────

class AvatarNotifier extends Notifier<AvatarState> {
  late final AvatarRepository _avatarRepository;

  @override
  AvatarState build() {
    _avatarRepository = ref.read(avatarRepositoryProvider);
    Future.microtask(() => loadAvatar());
    return const AvatarState();
  }

  Future<void> loadAvatar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final avatar = await _avatarRepository.getAvatar();
      state = state.copyWith(avatar: avatar, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateAppearance(Map<String, dynamic> appearance) async {
    try {
      final updated = await _avatarRepository.updateAppearance(appearance);
      state = state.copyWith(avatar: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setTab(int index) {
    state = state.copyWith(activeTab: index);
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final avatarProvider = NotifierProvider<AvatarNotifier, AvatarState>(
  AvatarNotifier.new,
);
