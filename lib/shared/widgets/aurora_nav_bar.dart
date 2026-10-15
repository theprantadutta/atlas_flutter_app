import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// One destination in the Atlas nav.
class AtlasNavItem {
  const AtlasNavItem({
    required this.icon,
    required this.label,
    this.anchorKey,
  });

  /// A Material Symbol; drawn outlined when inactive and filled when active.
  final IconData icon;
  final String label;

  /// Optional key so the coach marks can point at this slot.
  final GlobalKey? anchorKey;
}

/// Where the floating nav sits above the bottom edge. On iPhones this lands
/// at the mock's 26pt; with a tall Android button bar it rises above it.
double navBottomOffset(BuildContext context) =>
    math.max(AppSpacing.navBottom, MediaQuery.paddingOf(context).bottom - 8);

/// Bottom scroll padding so content always clears the floating nav:
/// nav offset + 64 bar + 24 breathing room (114 on a standard phone).
double navScrollPadding(BuildContext context) =>
    navBottomOffset(context) + AppSpacing.navHeight + AppSpacing.lg;

/// Scroll controllers for the four tab roots, so re-tapping the active tab
/// can scroll it back to the top.
class TabScrollControllers {
  final _controllers = <int, ScrollController>{};

  ScrollController of(int tab) =>
      _controllers.putIfAbsent(tab, () => ScrollController());

  /// Scroll [tab] to the top; returns false when it was already there (or
  /// not attached), so the caller can do something else instead.
  bool scrollToTop(int tab, {bool reduceMotion = false}) {
    final c = _controllers[tab];
    if (c == null || !c.hasClients || c.offset <= 0) return false;
    if (reduceMotion) {
      c.jumpTo(0);
    } else {
      c.animateTo(0, duration: AppMotion.medium, curve: AppMotion.standard);
    }
    return true;
  }
}

final tabScrollControllersProvider =
    Provider<TabScrollControllers>((ref) => TabScrollControllers());

/// The floating ink pill with four destinations. The active one is a single
/// white (cream in dark) pill that slides and resizes between slots; its
/// label fades in once it settles. Inactive slots are outlined icons.
class AtlasNavBar extends StatelessWidget {
  const AtlasNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AtlasNavItem> items;

  /// -1 when no tab is active (e.g. on Profile).
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _inactiveSlot = 48.0;
  static const _pad = 8.0;
  static const _iconActive = 21.0;
  static const _iconInactive = 24.0;

  double _labelWidth(BuildContext context, String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: AppTypography.navLabel),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = AppMotion.reduceMotion(context);
    final duration = reduce ? Duration.zero : AppMotion.medium;

    return Container(
      height: AppSpacing.navHeight,
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: p.raisedBorderSide,
      ),
      child: LayoutBuilder(builder: (context, c) {
        final inner = c.maxWidth - _pad * 2 - (p.raisedBorder.a == 0 ? 0 : 2);
        final n = items.length;
        final active = currentIndex;
        final activeW = active < 0
            ? _inactiveSlot
            : 16 + _iconActive + 6 + _labelWidth(context, items[active].label) + 16;
        final widths = [
          for (var i = 0; i < n; i++) i == active ? activeW : _inactiveSlot,
        ];
        final gap = math.max(0.0, (inner - widths.fold<double>(0, (a, b) => a + b)) / (n - 1));
        final lefts = <double>[];
        var x = 0.0;
        for (var i = 0; i < n; i++) {
          lefts.add(x);
          x += widths[i] + gap;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pad),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // The single sliding pill.
              if (active >= 0)
                AnimatedPositioned(
                  duration: duration,
                  curve: AppMotion.standard,
                  left: lefts[active],
                  width: activeW,
                  top: (AppSpacing.navHeight - AppSpacing.navActivePillHeight) / 2 -
                      (p.raisedBorder.a == 0 ? 0 : 1),
                  height: AppSpacing.navActivePillHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.navPill,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                ),
              for (var i = 0; i < n; i++)
                AnimatedPositioned(
                  duration: duration,
                  curve: AppMotion.standard,
                  left: lefts[i],
                  width: widths[i],
                  top: 0,
                  bottom: 0,
                  child: _Slot(
                    key: items[i].anchorKey,
                    item: items[i],
                    active: i == active,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  final AtlasNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: active ? .97 : AppMotion.pressScaleCircle,
      semanticLabel: '${item.label} tab',
      child: Semantics(
        selected: active,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.instant,
              child: AtlasIcon(
                item.icon,
                key: ValueKey(active),
                filled: active,
                size: active ? AtlasNavBar._iconActive : AtlasNavBar._iconInactive,
                color: active ? AppColors.ink : p.iconInactive,
              ),
            ),
            if (active)
              Flexible(
                child: _FadeInLabel(label: item.label),
              ),
          ],
        ),
      ),
    );
  }
}

class _FadeInLabel extends StatelessWidget {
  const _FadeInLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: AppTypography.navLabel.copyWith(color: AppColors.ink),
      ),
    );
    if (AppMotion.reduceMotion(context)) return text;
    // The label waits for the pill to (mostly) settle, then fades in.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium + AppMotion.instant,
      curve: const Interval(.66, 1),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: text,
    );
  }
}

/// The 64 sunrise FAB. Its plus turns 45° into a × while [open].
class AtlasFab extends StatelessWidget {
  const AtlasFab({super.key, required this.onTap, this.open = false});

  final VoidCallback onTap;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      circle: true,
      haptic: PressHaptic.light,
      semanticLabel: open ? 'Close' : 'Add something',
      child: Container(
        width: AppSpacing.fabSize,
        height: AppSpacing.fabSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.sunrise,
          boxShadow: AppColors.fabShadow,
        ),
        child: AnimatedRotation(
          turns: open ? .125 : 0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: const AtlasIcon(Symbols.add_rounded,
              size: 30, color: AppColors.white, weight: 500),
        ),
      ),
    );
  }
}

/// The vertical ink rail for wide layouts (tablets), with the same active
/// pill, plus "You" and the FAB at the bottom.
class AtlasNavRail extends StatelessWidget {
  const AtlasNavRail({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.profileName,
    required this.onProfile,
    required this.profileActive,
    required this.fab,
  });

  final List<AtlasNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String profileName;
  final VoidCallback onProfile;
  final bool profileActive;
  final Widget fab;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(44),
        border: p.raisedBorderSide,
      ),
      child: Column(
        children: [
          const AtlasSpark(size: 30),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < items.length; i++) ...[
            Pressable(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(i);
              },
              semanticLabel: '${items[i].label} tab',
              child: AnimatedContainer(
                key: items[i].anchorKey,
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == currentIndex ? p.navPill : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(children: [
                  AtlasIcon(items[i].icon,
                      filled: i == currentIndex,
                      size: 24,
                      color: i == currentIndex ? AppColors.ink : p.iconInactive),
                  const SizedBox(height: 4),
                  Text(items[i].label,
                      style: AppTypography.sans(
                        size: 11,
                        weight: FontWeight.w800,
                        height: 1,
                        color: i == currentIndex ? AppColors.ink : p.iconInactive,
                      )),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Spacer(),
          AvatarRing(name: profileName, size: 48, onTap: onProfile),
          const SizedBox(height: AppSpacing.md),
          fab,
        ],
      ),
    );
  }
}
