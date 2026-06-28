import 'package:flutter/material.dart';

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

/// Atlas's signature navigation: a floating frosted capsule where the active
/// destination blooms into an aurora pill (icon + label) with a soft glow,
/// while the others rest as quiet glyphs. Distinctly ours, not Material default.
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
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: isDark ? 0.96 : 0.98),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
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
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 23,
              color: selected ? _onAurora : theme.colorScheme.onSurfaceVariant,
            ),
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
