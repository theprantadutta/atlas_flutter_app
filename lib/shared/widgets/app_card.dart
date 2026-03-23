import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// A modern card widget with optional gradient border, shadow, and header.
///
/// Features:
/// - Optional gradient border
/// - Subtle shadow with blur
/// - Optional header with action widget
/// - Custom padding
/// - onTap with ink ripple
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.header,
    this.headerAction,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.showGradientBorder = false,
    this.gradientBorderColors,
    this.gradientBorderWidth = 1.5,
    this.elevation = 0,
    this.shadowColor,
    this.backgroundColor,
  });

  /// The main content of the card.
  final Widget child;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Optional header text displayed above the child.
  final String? header;

  /// Optional action widget displayed in the header row (e.g., a button).
  final Widget? headerAction;

  /// Inner padding of the card content.
  final EdgeInsetsGeometry? padding;

  /// Outer margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Border radius of the card corners.
  final double borderRadius;

  /// When true, displays a gradient border.
  final bool showGradientBorder;

  /// Colors used for the gradient border.
  /// Defaults to [AppColors.primary, AppColors.secondaryLight].
  final List<Color>? gradientBorderColors;

  /// Width of the gradient border.
  final double gradientBorderWidth;

  /// Elevation of the card shadow.
  final double elevation;

  /// Color of the shadow.
  final Color? shadowColor;

  /// Background color override.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = backgroundColor ??
        (isDark ? AppColors.cardDark : AppColors.cardLight);

    final borderColor =
        isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;

    final effectiveShadowColor = shadowColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.06));

    Widget cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    header!,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (headerAction != null) ?headerAction,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );

    // Wrap with InkWell if tappable
    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: cardContent,
        ),
      );
    }

    // Gradient border wrapping
    if (showGradientBorder) {
      final colors = gradientBorderColors ??
          [AppColors.primary, AppColors.secondaryLight];

      return Container(
        margin: margin,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            if (elevation > 0)
              BoxShadow(
                color: effectiveShadowColor,
                blurRadius: elevation * 4,
                offset: Offset(0, elevation),
              ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(gradientBorderWidth),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius:
                BorderRadius.circular(borderRadius - gradientBorderWidth),
          ),
          clipBehavior: Clip.antiAlias,
          child: cardContent,
        ),
      );
    }

    // Standard card
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: effectiveShadowColor,
              blurRadius: elevation * 4,
              offset: Offset(0, elevation),
            ),
          // Subtle ambient shadow always present
          BoxShadow(
            color: effectiveShadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: cardContent,
    );
  }
}
