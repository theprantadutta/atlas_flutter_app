import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/features/achievements/providers/achievement_providers.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/features/world/providers/world_view.dart';
import 'package:atlas_flutter_app/shared/themes/app_theme.dart';
import 'package:atlas_flutter_app/shared/widgets/app_navigation_shell.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';

import '../helpers/golden.dart';

/// The real shell inside a real go_router, with stub screens, so routing
/// behaviour (nav on tab roots only, back, tab switching) is checked end to
/// end without the app's data layer.
GoRouter _router() {
  Widget page(String name, {String? push}) => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(name),
              if (push != null)
                TextButton(onPressed: () => context.push(push), child: Text('open $push')),
            ]),
          ),
        ),
      );
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, shell, children) => AppNavigationShell(
          navigationShell: shell,
          location: GoRouterState.of(context).uri.path,
          children: children,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => page('home', push: '/world/achievements')),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/grow', builder: (_, _) => page('grow'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/aurora', builder: (_, _) => page('aurora'))]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/world',
              builder: (_, _) => page('world'),
              routes: [GoRoute(path: 'achievements', builder: (_, _) => page('achievements'))],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => page('profile'))]),
        ],
      ),
    ],
  );
}

class _Onboarded extends OnboardingController {
  @override
  OnboardingState build() => const OnboardingState(
      loaded: true, introSeen: true, setupComplete: true, coachMarksSeen: true);
}

class _Chosen extends StarterDataController {
  @override
  StarterDataState build() => const StarterDataState(loaded: true, choiceMade: true);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'atlas_notification_primer_shown': true}));

  testWidgets('nav shows on tab roots, hides on pushed screens, and switches tabs', (tester) async {
    final semantics = tester.ensureSemantics();
    final router = _router();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        onboardingProvider.overrideWith(_Onboarded.new),
        dailyRolloverProvider.overrideWithValue(null),
        worldDiscoveryProvider.overrideWithValue(null),
        achievementEvaluatorProvider.overrideWithValue(null),
        avatarStatsSyncProvider.overrideWithValue(null),
        starterDataProvider.overrideWith(_Chosen.new),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    double navOpacity() => tester
        .widget<AnimatedOpacity>(find.ancestor(of: find.byType(AtlasNavBar), matching: find.byType(AnimatedOpacity)).first)
        .opacity;

    expect(find.text('home'), findsOneWidget);
    expect(navOpacity(), 1);

    // Switch tabs from the nav.
    final growTab = find.bySemanticsLabel('Grow tab');
    // The nav sits at the bottom of the screen (regression: it once
    // collapsed to a 0×0 stack and rendered off-screen).
    expect(tester.getCenter(growTab).dy, greaterThan(400));
    await tester.tap(growTab);
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/grow');
    expect(navOpacity(), 1);

    // A pushed screen hides the nav.
    router.go('/world/achievements');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('achievements'), findsOneWidget);
    expect(navOpacity(), 0);

    // Back returns to the tab root, and the nav comes back.
    router.pop();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/world');
    expect(navOpacity(), 1);
    semantics.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets('shell nav golden ${dark ? 'dark' : 'light'}', (tester) async {
      await loadAppFonts();
      tester.view.physicalSize = kPhone * 2;
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 100, bottom: 68);
      addTearDown(tester.view.reset);
      final router = _router();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(_Onboarded.new),
          dailyRolloverProvider.overrideWithValue(null),
          worldDiscoveryProvider.overrideWithValue(null),
          achievementEvaluatorProvider.overrideWithValue(null),
          avatarStatsSyncProvider.overrideWithValue(null),
          starterDataProvider.overrideWith(_Chosen.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: router,
        ),
      ));
      router.go('/aurora');
      await settle(tester);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../goldens/goldens/shell_${dark ? 'dark' : 'light'}.png'));
    });
  }
}
