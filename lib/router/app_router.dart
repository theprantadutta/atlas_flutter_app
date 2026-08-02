import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/achievements/screens/achievements_screen.dart';
import 'package:atlas_flutter_app/features/analytics/screens/analytics_screen.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/auth/screens/login_screen.dart';
import 'package:atlas_flutter_app/features/auth/screens/signup_screen.dart';
import 'package:atlas_flutter_app/features/auth/screens/splash_screen.dart';
import 'package:atlas_flutter_app/features/aurora/screens/aurora_chat_screen.dart';
import 'package:atlas_flutter_app/features/aurora/screens/aurora_screen.dart';
import 'package:atlas_flutter_app/features/avatar/screens/avatar_screen.dart';
import 'package:atlas_flutter_app/features/billing/screens/paywall_screen.dart';
import 'package:atlas_flutter_app/features/grow/screens/grow_screen.dart';
import 'package:atlas_flutter_app/features/home/screens/home_screen.dart';
import 'package:atlas_flutter_app/features/notifications/screens/notification_center_screen.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/screens/intro_screen.dart';
import 'package:atlas_flutter_app/features/onboarding/screens/setup_screen.dart';
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
    // The first-run intro also decides where the user lands.
    ref.listen<OnboardingState>(onboardingProvider, (prev, next) {
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
      final onboarding = ref.read(onboardingProvider);
      final location = state.matchedLocation;
      final isOnSplash = location == '/splash';
      final isOnAuthPage = location == '/login' || location == '/signup';
      final isOnIntro = location == '/intro';
      final isOnSetup = location == '/setup';

      if (authState.isInitializing) {
        return isOnSplash ? null : '/splash';
      }

      // Hold on the splash until the stored first-run flags are read, so we
      // never flash a screen the user is about to be moved away from.
      if (!onboarding.loaded) return isOnSplash ? null : '/splash';

      // The pitch comes before we ask for an account.
      if (!onboarding.introSeen) return isOnIntro ? null : '/intro';

      if (!authState.isAuthenticated) {
        return isOnAuthPage ? null : '/login';
      }

      // Signed in — personalise once before Home.
      if (!onboarding.setupComplete) return isOnSetup ? null : '/setup';

      if (isOnSetup || isOnIntro || isOnSplash || isOnAuthPage) return '/';
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
      GoRoute(
        path: '/intro',
        name: RouteNames.intro,
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: RouteNames.setup,
        builder: (context, state) => const SetupScreen(),
      ),

      // ─── Main shell: Home · Grow · Aurora · World · You ───
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

          // Aurora (center)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/aurora',
                name: RouteNames.aurora,
                builder: (context, state) => const AuroraScreen(),
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

      // ─── Top-level overlays (above the nav shell) ───
      GoRoute(
        path: '/aurora-chat',
        name: RouteNames.auroraChat,
        builder: (context, state) =>
            AuroraChatScreen(initialPrompt: state.extra as String?),
      ),
      GoRoute(
        path: '/paywall',
        name: RouteNames.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
    ],
  );
});
