import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/achievements/screens/achievements_screen.dart';
import 'package:atlas_flutter_app/features/analytics/screens/analytics_screen.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/auth/screens/login_screen.dart';
import 'package:atlas_flutter_app/features/auth/screens/signup_screen.dart';
import 'package:atlas_flutter_app/features/auth/screens/splash_screen.dart';
import 'package:atlas_flutter_app/features/avatar/screens/avatar_screen.dart';
import 'package:atlas_flutter_app/features/grow/screens/grow_screen.dart';
import 'package:atlas_flutter_app/features/home/screens/home_screen.dart';
import 'package:atlas_flutter_app/features/notifications/screens/notification_center_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/notification_settings_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/profile_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/sync_management_screen.dart';
import 'package:atlas_flutter_app/features/progress/screens/progress_screen.dart';
import 'package:atlas_flutter_app/features/world/screens/world_screen.dart';
import 'package:atlas_flutter_app/router/route_names.dart';
import 'package:atlas_flutter_app/shared/widgets/app_navigation_shell.dart';

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
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isOnSplash = state.matchedLocation == '/splash';

      if (authState.isInitializing) {
        return isOnSplash ? null : '/splash';
      }

      if (isOnSplash) {
        return authState.isAuthenticated ? '/' : '/login';
      }

      final isOnAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!authState.isAuthenticated && !isOnAuthPage) return '/login';
      if (authState.isAuthenticated && isOnAuthPage) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
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

      // ─── Main shell: Home · Grow · World · You ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppNavigationShell(navigationShell: navigationShell),
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'analytics',
                    name: RouteNames.analytics,
                    builder: (context, state) => const AnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'progress',
                    name: RouteNames.progress,
                    builder: (context, state) => const ProgressScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: RouteNames.notificationCenter,
                    builder: (context, state) =>
                        const NotificationCenterScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Grow
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/grow',
                name: RouteNames.grow,
                builder: (context, state) => const GrowScreen(),
              ),
            ],
          ),

          // World
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/world',
                name: RouteNames.world,
                builder: (context, state) => const WorldScreen(),
                routes: [
                  GoRoute(
                    path: 'achievements',
                    name: RouteNames.achievements,
                    builder: (context, state) => const AchievementsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // You
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'avatar',
                    name: RouteNames.avatar,
                    builder: (context, state) => const AvatarScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: RouteNames.notifications,
                    builder: (context, state) =>
                        const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'sync',
                    name: RouteNames.syncManagement,
                    builder: (context, state) => const SyncManagementScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
