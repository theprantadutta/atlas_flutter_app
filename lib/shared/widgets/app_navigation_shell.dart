import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/widgets/quick_add_sheet.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';

/// Calm five-tab shell with the custom Aurora navigation:
/// Home · Grow · Aurora · World · You. The nav floats over the body so content
/// scrolls beneath the frosted glass.
class AppNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({super.key, required this.navigationShell});

  static const _items = [
    AuroraNavItem(
      icon: Icons.cabin_outlined,
      selectedIcon: Icons.cabin_rounded,
      label: 'Home',
    ),
    AuroraNavItem(
      icon: Icons.eco_outlined,
      selectedIcon: Icons.eco_rounded,
      label: 'Grow',
    ),
    AuroraNavItem(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome_rounded,
      label: 'Aurora',
    ),
    AuroraNavItem(
      icon: Icons.public_outlined,
      selectedIcon: Icons.public_rounded,
      label: 'World',
    ),
    AuroraNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'You',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              items: _items,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
          // Floating "+" hovering above the bar.
          Positioned(
            right: AppSpacing.gutter,
            bottom: bottomInset + kAuroraNavBarHeight + AppSpacing.sm,
            child: AuroraFab(onTap: () => showQuickAddSheet(context)),
          ),
        ],
      ),
    );
  }
}
