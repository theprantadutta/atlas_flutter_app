import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/themes/app_breakpoints.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/quick_add_sheet.dart';
import 'package:atlas_flutter_app/features/achievements/providers/achievement_providers.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_engine.dart';
import 'package:atlas_flutter_app/features/notifications/widgets/notification_primer.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/widgets/coach_marks.dart';
import 'package:atlas_flutter_app/features/world/providers/world_view.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// How long the "press back again" offer stays open. Matched to the info
/// toast's own lifetime so the hint is never on screen after it has expired.
const _kExitWindow = Duration(seconds: 3);

/// The branch index of the "You" (profile) branch. It stays in the router
/// for deep links, but has no tab: Profile is reached from the avatar.
const kProfileBranch = 4;

/// Locations where the nav bar shows: the four tab roots. Pushed screens
/// (Insights, settings, achievements...) get the whole screen.
const _tabRoots = {'/', '/grow', '/aurora', '/world'};

/// Tablet breakpoint for the side rail.
const _wideBreakpoint = 840.0;

/// The app shell: four tabs (Home, Grow, Aurora, Atlas) in a floating ink
/// pill, with the sunrise "+" beside it so it never covers content.
class AppNavigationShell extends ConsumerStatefulWidget {
  const AppNavigationShell({
    super.key,
    required this.navigationShell,
    required this.location,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;

  /// The current matched path, used to hide the nav on pushed screens.
  final String location;

  /// The branch navigators, from `navigatorContainerBuilder`.
  final List<Widget> children;

  @override
  ConsumerState<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends ConsumerState<AppNavigationShell> {
  /// When the last unanswered back press happened, or null if there isn't one.
  DateTime? _armedAt;

  /// Whether the notification primer has already been considered this session.
  bool _primerConsidered = false;

  bool _quickAddOpen = false;

  @override
  void didUpdateWidget(AppNavigationShell old) {
    super.didUpdateWidget(old);
    // Changing tabs cancels a pending exit.
    if (old.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _armedAt = null;
    }
  }

  List<AtlasNavItem> _items(CoachMarkKeys keys) => [
        const AtlasNavItem(icon: Symbols.home_rounded, label: 'Home'),
        const AtlasNavItem(icon: Symbols.checklist_rounded, label: 'Grow'),
        AtlasNavItem(
          icon: Symbols.auto_awesome_rounded,
          label: 'Aurora',
          anchorKey: keys.auroraTab,
        ),
        const AtlasNavItem(icon: Symbols.language_rounded, label: 'Atlas'),
      ];

  void _onTab(int index) {
    final shell = widget.navigationShell;
    if (index == shell.currentIndex) {
      // Re-tap: at the root, scroll to top; deeper, pop back to the root.
      if (_tabRoots.contains(widget.location)) {
        ref.read(tabScrollControllersProvider).scrollToTop(
              index,
              reduceMotion: AppMotion.reduceMotion(context),
            );
      } else {
        shell.goBranch(index, initialLocation: true);
      }
      return;
    }
    shell.goBranch(index);
  }

  Future<void> _openQuickAdd() async {
    if (_quickAddOpen) return;
    setState(() => _quickAddOpen = true);
    await showQuickAddSheet(context);
    if (mounted) setState(() => _quickAddOpen = false);
  }

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

  /// Ask about notifications once the tour is out of the way.
  void _considerNotificationPrimer(OnboardingState onboarding, int tabIndex) {
    if (_primerConsidered) return;
    if (tabIndex != 0) return;
    if (!onboarding.loaded ||
        !onboarding.setupComplete ||
        !onboarding.coachMarksSeen) {
      return;
    }

    _primerConsidered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowNotificationPrimer(context, ref, tourFinished: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final coachKeys = ref.watch(coachMarkKeysProvider);
    final p = context.palette;
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final atRoot = _tabRoots.contains(widget.location);
    final tabIndex = shell.currentIndex == kProfileBranch ? -1 : shell.currentIndex;

    _considerNotificationPrimer(ref.watch(onboardingProvider), shell.currentIndex);

    // Keep the day rolling over and discoveries happening wherever you are.
    ref.watch(dailyRolloverProvider);
    ref.watch(worldDiscoveryProvider);
    ref.watch(achievementEvaluatorProvider);
    ref.watch(avatarStatsSyncProvider);
    // Reminders follow the habits, tasks and choices; the inbox files levels
    // and letters as they happen.
    ref.watch(reminderSyncProvider);
    ref.watch(inboxMomentsProvider);
    // A notification tap waiting for the app to be ready: open it now.
    final pendingRoute = ref.watch(pendingNotificationRouteProvider);
    if (pendingRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(pendingNotificationRouteProvider.notifier).clear();
        context.go(pendingRoute);
      });
    }
    ref.listen<List<String>>(pendingDiscoveriesProvider, (prev, next) {
      final fresh = next.where((id) => !(prev ?? const []).contains(id)).toList();
      if (fresh.isEmpty || shell.currentIndex == 3) return;
      final place = ref.read(worldViewProvider)?.places.where((p) => p.id == fresh.first).firstOrNull;
      if (place == null) return;
      HapticFeedback.heavyImpact();
      AtlasToast.undo(
        context,
        'You discovered ${place.name}',
        actionLabel: 'Visit',
        onUndo: () => shell.goBranch(3),
      );
    });

    final fab = AtlasFab(
      key: coachKeys.fab,
      open: _quickAddOpen,
      onTap: _openQuickAdd,
    );

    final branches = _BranchStack(
      currentIndex: shell.currentIndex,
      children: widget.children,
    );

    final Widget body;
    if (wide) {
      final name = ref.watch(authProvider.select((s) => s.user?.fullName ?? ''));
      body = Row(
        children: [
          SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AtlasNavRail(
                items: _items(coachKeys),
                currentIndex: tabIndex,
                onTap: _onTab,
                profileName: name,
                profileActive: shell.currentIndex == kProfileBranch,
                onProfile: () => shell.goBranch(kProfileBranch),
                fab: fab,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.readingColumn),
                // Tell the screens the width they actually get, so their
                // readable padding doesn't count the rail and the margins
                // a second time.
                child: LayoutBuilder(
                  builder: (context, box) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: Size(box.maxWidth, MediaQuery.sizeOf(context).height),
                    ),
                    child: branches,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final bottom = navBottomOffset(context);
      final reduce = AppMotion.reduceMotion(context);
      // expand: every child here is positioned (and the coach marks are
      // zero-size when hidden), so without it the Stack collapses to 0×0.
      body = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: branches),
          // A soft fade so content dissolves behind the floating nav.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120 + (bottom - AppSpacing.navBottom),
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: atRoot ? 1 : 0,
                duration: AppMotion.fast,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [p.canvas.withValues(alpha: 0), p.canvas],
                      stops: const [0, .5],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: reduce ? Duration.zero : AppMotion.medium,
            curve: AppMotion.standard,
            left: AppSpacing.navSide,
            right: AppSpacing.navSide,
            bottom: atRoot ? bottom : -(AppSpacing.navHeight + bottom + 24),
            child: AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: atRoot ? 1 : 0,
              child: Row(
                children: [
                  Expanded(
                    child: AtlasNavBar(
                      items: _items(coachKeys),
                      currentIndex: tabIndex,
                      onTap: _onTab,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.fabGap),
                  fab,
                ],
              ),
            ),
          ),
          // First-run tour, above everything (Home tab only).
          CoachMarks(enabled: shell.currentIndex == 0 && atRoot),
        ],
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: body,
      ),
    );
  }
}

/// Keeps every branch alive (like an IndexedStack) but crossfades tab
/// switches over 220ms with a 12px rise on the incoming page. Under reduced
/// motion it is a plain 120ms crossfade.
class _BranchStack extends StatelessWidget {
  const _BranchStack({required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _Branch(
            active: i == currentIndex,
            reduce: reduce,
            child: children[i],
          ),
      ],
    );
  }
}

class _Branch extends StatefulWidget {
  const _Branch({required this.active, required this.reduce, required this.child});
  final bool active;
  final bool reduce;
  final Widget child;

  @override
  State<_Branch> createState() => _BranchState();
}

class _BranchState extends State<_Branch> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: widget.active ? 1 : 0,
    duration: widget.reduce ? AppMotion.instant : AppMotion.fast,
  );

  @override
  void didUpdateWidget(_Branch old) {
    super.didUpdateWidget(old);
    _c.duration = widget.reduce ? AppMotion.instant : AppMotion.fast;
    if (widget.active != old.active) {
      if (widget.active) {
        _c.forward(from: 0);
      } else {
        _c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final visible = widget.active || _c.value > 0;
        final t = AppMotion.standard.transform(_c.value);
        return Offstage(
          offstage: !visible,
          child: TickerMode(
            enabled: widget.active,
            child: IgnorePointer(
              ignoring: !widget.active,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, widget.reduce ? 0 : 12 * (1 - t)),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
