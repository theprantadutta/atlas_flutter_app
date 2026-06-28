import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// A destination in the [AuroraNavBar].
class AuroraNavItem {
  const AuroraNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Total height the nav bar occupies from the bottom (capsule + bottom margin),
/// excluding the safe-area inset. Used to position the floating action button.
const double kAuroraNavBarHeight = 64 + AppSpacing.sm;

/// Atlas's signature navigation: a floating frosted-glass capsule. The active
/// destination blooms into an aurora pill (icon + label) with a soft glow and a
/// little bounce; the others rest as quiet glyphs. Content scrolls under the glass.
class AuroraNavBar extends StatelessWidget {
  const AuroraNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AuroraNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: isDark ? 0.62 : 0.74),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _NavSlot(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating aurora "+" that hovers above the nav bar.
class AuroraFab extends StatelessWidget {
  const AuroraFab({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.auroraGradient,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.auroraLilac.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: -1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Color(0xFF10162B), size: 28),
      ),
    ).animate().scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final AuroraNavItem item;
  final bool selected;
  final VoidCallback onTap;

  // Deep ink reads cleanly on the bright aurora gradient in both themes.
  static const _onAurora = Color(0xFF10162B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration =
        AppMotion.reduceMotion(context) ? Duration.zero : AppMotion.medium;

    final icon = Icon(
      selected ? item.selectedIcon : item.icon,
      size: 23,
      color: selected ? _onAurora : theme.colorScheme.onSurfaceVariant,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? AppSpacing.md : AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.auroraGradient : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.auroraLilac.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            selected
                ? icon.animate(key: const ValueKey('sel')).scaleXY(
                      begin: 0.6,
                      end: 1,
                      duration: AppMotion.medium,
                      curve: Curves.elasticOut,
                    )
                : icon,
            AnimatedSize(
              duration: duration,
              curve: AppMotion.standard,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Text(
                        item.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _onAurora,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
