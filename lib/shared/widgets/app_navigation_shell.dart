import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';

/// Calm four-tab shell with the custom Aurora navigation: Home · Grow · World · You.
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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AuroraNavBar(
        currentIndex: navigationShell.currentIndex,
        items: _items,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
