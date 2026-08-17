import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/widgets/quick_add_sheet.dart';
import 'package:atlas_flutter_app/features/onboarding/widgets/coach_marks.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';
import 'package:atlas_flutter_app/shared/widgets/feedback/atlas_toast.dart';

/// How long the "press back again" offer stays open. Matched to the info
/// toast's own lifetime so the hint is never on screen after it has expired.
const _kExitWindow = Duration(seconds: 3);

/// Calm five-tab shell with the custom Aurora navigation:
/// Home · Grow · Aurora · World · You. The nav floats over the body so content
/// scrolls beneath the frosted glass.
class AppNavigationShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends ConsumerState<AppNavigationShell> {
  /// When the last unanswered back press happened, or null if there isn't one.
  DateTime? _armedAt;

  @override
  void didUpdateWidget(AppNavigationShell old) {
    super.didUpdateWidget(old);
    // Changing tabs cancels a pending exit. Otherwise a quick round trip to
    // another tab and back could leave within the window, without the hint the
    // user is owed.
    if (old.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _armedAt = null;
    }
  }

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

  /// The hardware back button, once nothing above the shell can absorb it.
  ///
  /// From any other tab, back walks home rather than leaving. From Home it
  /// takes two presses, so nobody loses their place by reflex.
  void _handleBack() {
    final shell = widget.navigationShell;
    if (shell.currentIndex != 0) {
      shell.goBranch(0);
      return;
    }

    final armedAt = _armedAt;
    final now = DateTime.now();
    if (armedAt != null && now.difference(armedAt) < _kExitWindow) {
      AtlasToast.dismiss();
      SystemNavigator.pop();
      return;
    }

    setState(() => _armedAt = now);
    AtlasToast.info(context, 'Press back again to leave Atlas.');
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final coachKeys = ref.watch(coachMarkKeysProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            shell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AuroraNavBar(
                currentIndex: shell.currentIndex,
                items: _items(coachKeys),
                onTap: (index) {
                  shell.goBranch(
                    index,
                    initialLocation: index == shell.currentIndex,
                  );
                },
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
            CoachMarks(enabled: shell.currentIndex == 0),
          ],
        ),
      ),
    );
  }
}
