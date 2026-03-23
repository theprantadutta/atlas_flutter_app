import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/auth/screens/login_screen.dart';
import 'package:atlas_flutter_app/features/auth/screens/signup_screen.dart';
import 'package:atlas_flutter_app/features/home/screens/home_screen.dart';
import 'package:atlas_flutter_app/router/route_names.dart';

// ─── Refresh Listenable that bridges Riverpod → GoRouter ──────────

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      notifyListeners();
    });
  }
}

// ─── Router Provider ──────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // While the app is still initializing, don't redirect anywhere
      if (authState.isInitializing) return null;

      final isOnLogin = state.matchedLocation == '/login';
      final isOnSignup = state.matchedLocation == '/signup';
      final isOnAuthPage = isOnLogin || isOnSignup;

      if (!authState.isAuthenticated && !isOnAuthPage) {
        return '/login';
      }

      if (authState.isAuthenticated && isOnAuthPage) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
    ],
  );
});
