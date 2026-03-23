import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/achievements/screens/achievements_screen.dart';
import 'package:atlas_flutter_app/features/analytics/screens/analytics_screen.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/auth/screens/login_screen.dart';
import 'package:atlas_flutter_app/features/auth/screens/signup_screen.dart';
import 'package:atlas_flutter_app/features/avatar/screens/avatar_screen.dart';
import 'package:atlas_flutter_app/features/goals/screens/goals_screen.dart';
import 'package:atlas_flutter_app/features/habits/screens/habits_screen.dart';
import 'package:atlas_flutter_app/features/home/screens/home_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/notification_settings_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/profile_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/sync_management_screen.dart';
import 'package:atlas_flutter_app/features/progress/screens/progress_screen.dart';
import 'package:atlas_flutter_app/features/tasks/screens/tasks_screen.dart';
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
      // ─── Auth routes (outside the shell) ───
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

      // ─── Main shell with bottom navigation ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
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
                    builder: (context, state) =>
                        const AnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'progress',
                    name: RouteNames.progress,
                    builder: (context, state) =>
                        const ProgressScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                name: RouteNames.tasks,
                builder: (context, state) =>
                    const TasksScreen(),
              ),
            ],
          ),

          // Branch 2: Habits
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                name: RouteNames.habits,
                builder: (context, state) =>
                    const HabitsScreen(),
              ),
            ],
          ),

          // Branch 3: Goals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                name: RouteNames.goals,
                builder: (context, state) =>
                    const GoalsScreen(),
              ),
            ],
          ),

          // Branch 4: World
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/world',
                name: RouteNames.world,
                builder: (context, state) =>
                    const WorldScreen(),
                routes: [
                  GoRoute(
                    path: 'achievements',
                    name: RouteNames.achievements,
                    builder: (context, state) =>
                        const AchievementsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 5: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) =>
                    const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'avatar',
                    name: RouteNames.avatar,
                    builder: (context, state) =>
                        const AvatarScreen(),
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
                    builder: (context, state) =>
                        const SyncManagementScreen(),
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
