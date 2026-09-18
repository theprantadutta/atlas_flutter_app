import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/widgets/quick_add_sheet.dart';
import 'package:atlas_flutter_app/features/onboarding/widgets/coach_marks.dart';
import 'package:atlas_flutter_app/shared/themes/app_breakpoints.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';

/// Calm five-tab shell with the custom Aurora navigation:
/// Home · Grow · Aurora · World · You. The nav floats over the body so content
/// scrolls beneath the frosted glass.
class AppNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({super.key, required this.navigationShell});

  List<AuroraNavItem> _items(CoachMarkKeys keys) => [
        const AuroraNavItem(
          icon: Icons.cabin_outlined,
          selectedIcon: Icons.cabin_rounded,
          label: 'Home',
        ),
        const AuroraNavItem(
          icon: Icons.eco_outlined,
          selectedIcon: Icons.eco_rounded,
          label: 'Grow',
        ),
        AuroraNavItem(
          icon: Icons.auto_awesome_outlined,
          selectedIcon: Icons.auto_awesome_rounded,
          label: 'Aurora',
          anchorKey: keys.auroraTab,
        ),
        const AuroraNavItem(
          icon: Icons.public_outlined,
          selectedIcon: Icons.public_rounded,
          label: 'World',
        ),
        const AuroraNavItem(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'You',
        ),
      ];

  void _goBranch(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachKeys = ref.watch(coachMarkKeysProvider);

    // On iPad and wide windows the navigation stands up the left edge; a
    // floating capsule at the bottom of a 13" screen is both far from the eye
    // and a waste of the sides.
    if (context.windowSize.usesSideNav) {
      return _WideShell(
        navigationShell: navigationShell,
        items: _items(coachKeys),
        fabKey: coachKeys.fab,
        onTap: _goBranch,
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AuroraNavBar(
              currentIndex: navigationShell.currentIndex,
              items: _items(coachKeys),
              onTap: _goBranch,
            ),
          ),
          // Floating "+" hovering above the bar.
          Positioned(
            right: AppSpacing.gutter,
            bottom: bottomInset + kAuroraNavBarHeight + AppSpacing.sm,
            child: AuroraFab(
              key: coachKeys.fab,
              onTap: () => showQuickAddSheet(context),
            ),
          ),
          // First-run tour, above everything (Home tab only).
          CoachMarks(enabled: navigationShell.currentIndex == 0),
        ],
      ),
    );
  }
}

/// iPad / wide-window shell: rail on the left, content filling the rest.
class _WideShell extends StatelessWidget {
  const _WideShell({
    required this.navigationShell,
    required this.items,
    required this.fabKey,
    required this.onTap,
  });

  final StatefulNavigationShell navigationShell;
  final List<AuroraNavItem> items;
  final Key? fabKey;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AuroraNavRail(
            currentIndex: navigationShell.currentIndex,
            items: items,
            onTap: onTap,
            // Quick-add lives at the foot of the rail rather than floating over
            // the content, where on a tablet it would hover in dead space.
            trailing: AuroraFab(
              key: fabKey,
              onTap: () => showQuickAddSheet(context),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                navigationShell,
                CoachMarks(enabled: navigationShell.currentIndex == 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
