import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// The one heavy element on a screen: an ink card (raised charcoal with a
/// border in dark), radius 32, clipping a drifting sunrise glow.
///
/// [glowLevel] (0..1) maps to the glow's opacity, 0.6 → 1.0, so the glow
/// brightens as the day fills. [celebrate] swells it to 1.6x for the
/// day-complete moment.
class InkHeroCard extends StatelessWidget {
  const InkHeroCard({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(22),
    this.glow = true,
    this.glowLevel = 0,
    this.celebrate = false,
    this.radius = AppSpacing.radiusXl,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final double glowLevel;
  final bool celebrate;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(radius),
        border: p.raisedBorderSide,
      ),
      child: Stack(
        children: [
          if (glow)
            Positioned(
              right: -70,
              top: -80,
              width: 260,
              height: 260,
              child: HeroGlow(level: glowLevel, celebrate: celebrate),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// The blurred sunrise blob. Drifts (-18, 14) and breathes 1 → 1.12 on a
/// 9s mirror loop; static under reduced motion. Its controller lives here,
/// below the theme, but the theme lerps colors only, so a theme change
/// never restarts the loop.
class HeroGlow extends StatefulWidget {
  const HeroGlow({super.key, this.level = 0, this.celebrate = false});

  final double level;
  final bool celebrate;

  @override
  State<HeroGlow> createState() => _HeroGlowState();
}

class _HeroGlowState extends State<HeroGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: AppMotion.ambientGlow ~/ 2,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = .6 + .4 * widget.level.clamp(0.0, 1.0);
    final blob = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.heroGlow,
        ),
      ),
    );
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.celebrate ? 1 : 0),
        duration: AppMotion.deliberate,
        curve: AppMotion.emphasized,
        builder: (context, boost, child) => AnimatedOpacity(
          duration: AppMotion.slow,
          opacity: (opacity + .2 * boost).clamp(0.0, 1.0) * .9,
          child: AnimatedBuilder(
            animation: _drift,
            child: child,
            builder: (context, child) {
              final t = AppMotion.gentle.transform(_drift.value);
              return Transform.translate(
                offset: Offset(-18 * t, 14 * t),
                child: Transform.scale(
                  scale: (1 + .12 * t) * (1 + .6 * boost),
                  child: child,
                ),
              );
            },
          ),
        ),
        child: blob,
      ),
    );
  }
}
