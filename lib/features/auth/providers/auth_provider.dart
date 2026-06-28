import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/services/auth_service.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

// ─── Auth State ───────────────────────────────────────────────────

class AuthState {
  final bool isInitializing;
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({
    this.isInitializing = true,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Auth Notifier ────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    // Kick off initial auth check asynchronously
    Future.microtask(() => checkAuthStatus());
    return const AuthState();
  }

  /// Check whether the user has valid tokens and, if so, load their profile.
  Future<void> checkAuthStatus() async {
    try {
      final hasTokens = await _authService.isAuthenticated();
      if (!hasTokens) {
        state = const AuthState(isInitializing: false);
        return;
      }

      final user = await _authService.getCurrentUser();
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (_) {
      state = const AuthState(isInitializing: false);
    }
  }

  /// Log in with email & password.
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Register with email, password, and full name.
  Future<void> register(
    String email,
    String password,
    String fullName,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sign in with Google (via Firebase).
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInWithGoogle();
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Force the session to the logged-out state without calling the server.
  ///
  /// Used when a token refresh fails irrecoverably (e.g. the refresh token has
  /// expired or been revoked). The API client has already cleared the stored
  /// tokens at that point, so we only reset local state; the router redirect
  /// then sends the user to the login screen.
  void markLoggedOut() {
    if (!state.isAuthenticated && !state.isInitializing) return;
    ref.read(signalRServiceProvider).disconnect();
    state = const AuthState(
      isInitializing: false,
      isAuthenticated: false,
    );
  }

  /// Log out and clear auth state.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Unregister FCM token before logout
      try {
        await ref.read(fcmServiceProvider).unregisterToken();
      } catch (_) {
        // Continue logout regardless of FCM errors
      }

      await _authService.logout();

      // Clean up offline services
      ref.read(signalRServiceProvider).disconnect();
      await ref.read(syncDaoProvider).clearAll();
    } catch (_) {
      // Continue logout regardless of errors
    } finally {
      state = const AuthState(
        isInitializing: false,
        isAuthenticated: false,
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
