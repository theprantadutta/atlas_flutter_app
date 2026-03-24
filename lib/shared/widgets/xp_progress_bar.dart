import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../themes/app_colors.dart';

/// An animated XP progress bar with gradient fill and glow effect.
///
/// Features:
/// - Gradient fill using AppColors.xpGradient
/// - Animated fill on value change
/// - Level labels on left and right
/// - Percentage / XP text overlay
/// - Customizable height
/// - Glow effect on the fill edge
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.requiredXp,
    this.currentLevel = 1,
    this.height = 20,
    this.showLabels = true,
    this.showXpText = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.backgroundColor,
    this.borderRadius,
    this.labelColor,
  });

  /// Current XP earned in this level.
  final int currentXp;

  /// Total XP required to reach the next level.
  final int requiredXp;

  /// The user's current level.
  final int currentLevel;

  /// Height of the progress bar.
  final double height;

  /// Whether to show level labels on left and right.
  final bool showLabels;

  /// Whether to show XP text overlay on the bar.
  final bool showXpText;

  /// Duration of the fill animation.
  final Duration animationDuration;

  /// Background color of the track.
  final Color? backgroundColor;

  /// Border radius override.
  final double? borderRadius;

  /// Override color for level labels (useful when placed on a gradient card).
  final Color? labelColor;

  double get _progress =>
      requiredXp > 0 ? (currentXp / requiredXp).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? (height / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level labels
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lv. $currentLevel',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: labelColor ?? AppColors.xpPrimary,
                ),
              ),
              Text(
                'Lv. ${currentLevel + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: labelColor?.withValues(alpha: 0.7) ??
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Progress bar
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final trackBg = backgroundColor ??
                  (isDark
                      ? AppColors.cardBorderDark
                      : AppColors.xpBackground);

              return Stack(
                children: [
                  // ─── Track Background ───
                  Container(
                    width: maxWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: trackBg,
                      borderRadius: BorderRadius.circular(effectiveRadius),
                    ),
                  ),

                  // ─── Animated Fill ───
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final fillWidth =
                          (maxWidth * value).clamp(0.0, maxWidth);

                      if (fillWidth <= 0) return const SizedBox.shrink();

                      return SizedBox(
                        width: fillWidth,
                        height: height,
                        child: Stack(
                          children: [
                            // Gradient fill
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.xpGradient,
                                borderRadius:
                                    BorderRadius.circular(effectiveRadius),
                              ),
                            ),

                            // Glow effect on the leading edge
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: height * 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.35),
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(effectiveRadius),
                                ),
                              ),
                            ),

                            // Shimmer / shine sweep
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(effectiveRadius),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ─── XP Text Overlay ───
                  if (showXpText)
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          '$currentXp / $requiredXp XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _progress > 0.45
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: height > 16 ? 11 : 9,
                            shadows: _progress > 0.45
                                ? [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
            .slideX(begin: -0.02, end: 0, duration: 400.ms),
      ],
    );
  }
}
