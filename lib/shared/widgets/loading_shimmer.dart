import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../themes/app_colors.dart';

/// Shimmer placeholder widget with convenient factory presets.
///
/// Provides a loading skeleton effect for various UI components.
/// All presets are theme-aware (light/dark mode).
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  /// The shimmer shape content (typically colored containers).
  final Widget child;

  /// Base color of the shimmer. Defaults to theme-aware gray.
  final Color? baseColor;

  /// Highlight color of the shimmer sweep. Defaults to theme-aware light gray.
  final Color? highlightColor;

  /// Whether the shimmer animation is active.
  final bool enabled;

  // ─────────────────────────────────────────────────────────
  //  Factory: Full Card Shape
  // ─────────────────────────────────────────────────────────
  factory LoadingShimmer.card({
    Key? key,
    double height = 160,
    double borderRadius = 20,
  }) {
    return LoadingShimmer(
      key: key,
      child: _ShimmerCard(height: height, borderRadius: borderRadius),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Factory: Single List Item
  // ─────────────────────────────────────────────────────────
  factory LoadingShimmer.listItem({
    Key? key,
    double height = 72,
  }) {
    return LoadingShimmer(
      key: key,
      child: _ShimmerListItem(height: height),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Factory: Circular Avatar
  // ─────────────────────────────────────────────────────────
  factory LoadingShimmer.avatar({
    Key? key,
    double size = 48,
  }) {
    return LoadingShimmer(
      key: key,
      child: _ShimmerAvatar(size: size),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Factory: Text Line Placeholders
  // ─────────────────────────────────────────────────────────
  factory LoadingShimmer.text({
    Key? key,
    int lines = 3,
    double lineHeight = 14,
    double spacing = 10,
  }) {
    return LoadingShimmer(
      key: key,
      child: _ShimmerTextLines(
        lines: lines,
        lineHeight: lineHeight,
        spacing: spacing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = baseColor ??
        (isDark
            ? AppColors.cardBorderDark.withValues(alpha: 0.5)
            : AppColors.cardBorderLight.withValues(alpha: 0.6));

    final highlight = highlightColor ??
        (isDark
            ? AppColors.cardDark.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8));

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      enabled: enabled,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Internal Shape Widgets
// ═══════════════════════════════════════════════════════════

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.height, required this.borderRadius});

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  const _ShimmerListItem({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Leading circle
          Container(
            width: height * 0.65,
            height: height * 0.65,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerAvatar extends StatelessWidget {
  const _ShimmerAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ShimmerTextLines extends StatelessWidget {
  const _ShimmerTextLines({
    required this.lines,
    required this.lineHeight,
    required this.spacing,
  });

  final int lines;
  final double lineHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (index) {
        // Vary the width of each line for a natural look
        final widthFactor = index == lines - 1 ? 0.5 : (0.85 + (index % 2) * 0.15);

        return Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? spacing : 0),
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              height: lineHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(lineHeight / 2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
