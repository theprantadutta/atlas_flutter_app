import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/errors/error_messages.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/core/config/demo_config.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/services/auth_service.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/core/telemetry/telemetry.dart';

final _log = AppLog('Auth');

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
  late final TokenService _tokenService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _tokenService = ref.read(tokenServiceProvider);
    // Crash reports and analytics follow whoever is signed in, by opaque id.
    listenSelf((prev, next) {
      final id = next.isAuthenticated ? next.user?.id : null;
      final was = (prev?.isAuthenticated ?? false) ? prev?.user?.id : null;
      if (id != was) Telemetry.setUser(id);
    });
    // Kick off initial auth check asynchronously
    Future.microtask(() => checkAuthStatus());
    return const AuthState();
  }

  /// Signs in with the throwaway demo account. Returns true when the session
  /// is established, so the caller can stop and leave state authenticated.
  Future<bool> _tryDemoSignIn() async {
    try {
      final user = await _authService.login(
        email: DemoConfig.email,
        password: DemoConfig.password,
      );
      await _cacheUser(user);
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
      return true;
    } catch (_) {
      // Wrong credentials or no backend — fall through to the login screen.
      return false;
    }
  }

  // ─── Offline-first user cache ───
  Future<void> _cacheUser(User user) async {
    try {
      await _tokenService.saveUserJson(jsonEncode(user.toJson()));
    } catch (_) {/* best-effort */}
  }

  Future<User?> _loadCachedUser() async {
    try {
      final json = await _tokenService.getUserJson();
      if (json == null) return null;
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Check whether the user has valid tokens and, if so, load their profile.
  Future<void> checkAuthStatus() async {
    try {
      final hasTokens = await _authService.isAuthenticated();
      if (!hasTokens) {
        // Unattended runs (layout work, store screenshots) sign themselves in
        // rather than waiting for someone to type into a simulator. Compiled
        // out unless ATLAS_DEMO is defined.
        if (DemoConfig.isUsable && await _tryDemoSignIn()) return;
        state = const AuthState(isInitializing: false);
        return;
      }

      // Token present: try to refresh the profile online, but fall back to the
      // cached user when offline so the session survives without a network.
      try {
        final user = await _authService.getCurrentUser();
        await _cacheUser(user);
        state =
            AuthState(isInitializing: false, isAuthenticated: true, user: user);
      } catch (_) {
        final cached = await _loadCachedUser();
        state = AuthState(
          isInitializing: false,
          isAuthenticated: cached != null,
          user: cached,
        );
      }
    } catch (_) {
      state = const AuthState(isInitializing: false);
    }
  }

  /// Re-fetch the current user's profile from the backend and update state,
  /// without touching [AuthState.isInitializing] (so the router doesn't bounce
  /// to the splash). Used after a purchase to pick up new premium entitlement.
  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;
    try {
      final user = await _authService.getCurrentUser();
      await _cacheUser(user);
      state = state.copyWith(user: user);
    } catch (_) {
      // Best-effort: keep the existing cached user on failure.
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
      await _cacheUser(user);
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
      Telemetry.signedIn('email');
    } catch (e, s) {
      _log.e('Sign-in failed', error: e, stackTrace: s);
      state = state.copyWith(
        isLoading: false,
        error: AppErrors.message(e),
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
      await _cacheUser(user);
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
      Telemetry.signedUp('email');
    } catch (e, s) {
      _log.e('Sign-in failed', error: e, stackTrace: s);
      state = state.copyWith(
        isLoading: false,
        error: AppErrors.message(e),
      );
    }
  }

  /// Sign in with Google (via Firebase).
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInWithGoogle();
      await _cacheUser(user);
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
      Telemetry.signedIn('google');
    } catch (e, s) {
      _log.e('Sign-in failed', error: e, stackTrace: s);
      state = state.copyWith(
        isLoading: false,
        error: AppErrors.message(e),
      );
    }
  }

  /// Sign in with Apple (via Firebase).
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInWithApple();
      await _cacheUser(user);
      state = AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: user,
      );
      Telemetry.signedIn('apple');
    } catch (e, s) {
      _log.e('Sign-in failed', error: e, stackTrace: s);
      state = state.copyWith(
        isLoading: false,
        error: AppErrors.message(e),
      );
    }
  }

  /// Permanently delete the account, then wipe every local trace of it.
  ///
  /// Throws on failure so the caller can keep the user on the confirmation
  /// screen rather than silently pretending the account is gone.
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Stop background traffic before the account disappears underneath it.
      try {
        await ref.read(fcmServiceProvider).unregisterToken();
      } catch (_) {/* best-effort */}

      await _authService.deleteAccount();
      try {
        await Telemetry.forgetDevice();
      } catch (_) {/* best-effort */}

      ref.read(signalRServiceProvider).disconnect();
      // Purge the local database — deletion must leave nothing behind, and the
      // next account on this device must not inherit the old one's data.
      // (syncDao.clearAll() only drains the pending-operation queue.)
      await _clearUserScopedState(wipeDatabase: true);
      await _tokenService.clearUser();

      state = const AuthState(
        isInitializing: false,
        isAuthenticated: false,
      );
    } catch (e, s) {
      _log.e('Logout failed', error: e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: AppErrors.message(e));
      rethrow;
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
    _tokenService.clearUser();
    ref.read(signalRServiceProvider).disconnect();
    // The session ended involuntarily (expired refresh token), so local data
    // is kept — it may hold unsynced edits. Only the pull cursor is reset, so
    // whoever signs in next gets a full pull instead of a stale delta.
    ref.read(offlineManagerProvider).resetSyncState().catchError((Object e) {
      _log.e('Resetting sync state failed', error: e);
    });
    state = const AuthState(
      isInitializing: false,
      isAuthenticated: false,
    );
  }

  /// Log out and clear auth state.
  ///
  /// The sync cursor is reset and user-scoped prefs are removed (see
  /// [userScopedPrefKeys]), and entitled users get a best-effort final sync
  /// first. The local database is deliberately kept: Atlas is offline-first,
  /// and for anyone without cloud sync it is the only copy of their data.
  /// Every query is scoped by user id, so another account signing in on this
  /// device never sees it, and the same account signing back in finds
  /// everything where it left it. Only [deleteAccount] wipes the database.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Push pending edits while the tokens are still valid. No-op when sync
      // is off/unentitled/offline; bounded so logout never hangs.
      try {
        await ref
            .read(offlineManagerProvider)
            .flush()
            .timeout(const Duration(seconds: 15));
      } catch (_) {/* best-effort */}

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
      await _clearUserScopedState(wipeDatabase: false);
      await _tokenService.clearUser();
      state = const AuthState(
        isInitializing: false,
        isAuthenticated: false,
      );
    }
  }

  // ─── Session teardown ───

  /// SharedPreferences keys that belong to the signed-in account and must not
  /// leak into the next one. Everything else (theme, refresh rate, intro /
  /// legal / notification-primer flags, coach marks, pending store
  /// verifications) is device-level and survives logout.
  static const userScopedPrefKeys = <String>{
    'offline_manager_last_sync',
    'atlas_setup_complete',
    'atlas.snoozed.v1',
    'atlas.dayComplete.lastDate',
    'atlas.letter.lastReadId',
    'atlas.discovered.celebrated',
  };

  /// Key prefixes for user-scoped prefs (starter-data choice, Aurora's
  /// personal preferences such as the preferred name and intention).
  static const userScopedPrefPrefixes = <String>[
    'atlas_starter_',
    'atlas_aurora_',
  ];

  static bool isUserScopedPrefKey(String key) =>
      userScopedPrefKeys.contains(key) ||
      userScopedPrefPrefixes.any(key.startsWith);

  /// Stops sync, resets its cursor, optionally hard-wipes the local database,
  /// and removes user-scoped prefs. Each step is best-effort so one failure
  /// never leaves the user stuck signed in.
  Future<void> _clearUserScopedState({required bool wipeDatabase}) async {
    try {
      // Waits for an in-flight sync so it can't write rows back after the wipe.
      await ref.read(offlineManagerProvider).resetSyncState();
    } catch (e, s) {
      _log.e('Resetting sync state failed', error: e, stackTrace: s);
    }
    if (wipeDatabase) {
      try {
        await ref.read(databaseProvider).wipeAllLocalData();
      } catch (e, s) {
        _log.e('Wiping local data failed', error: e, stackTrace: s);
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where(isUserScopedPrefKey).toList()) {
        await prefs.remove(key);
      }
    } catch (e, s) {
      _log.e('Clearing user prefs failed', error: e, stackTrace: s);
    }
    // These notifiers cache prefs in memory and must start the next account
    // from first-run state. Onboarding and starter data depend on this
    // provider, so invalidating them from here is a cycle (Riverpod throws,
    // and from a finally that skipped the rest of logout); they rebuild by
    // themselves when the signed-in user changes. Aurora's preferences don't
    // depend on auth and are reset here.
    ref.invalidate(auroraPreferencesProvider);
  }
}

// ─── Provider ─────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
