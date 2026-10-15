import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// First impression: the spark rises on the warm canvas, then the name. It
/// picks up exactly where the native splash (the same spark, same canvas)
/// leaves off, so there is no jump.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = AppMotion.reduceMotion(context);

    Widget spark = const AtlasSpark(size: 96, animated: true, semanticLabel: 'Atlas');
    Widget name = Text('Atlas', style: AppTypography.display(size: 44, color: p.textPrimary));
    Widget line = Text('Every day, a small sunrise.',
        style: AppTypography.sans(size: 16, weight: FontWeight.w500, color: p.textMuted));

    if (!reduce) {
      spark = spark
          .animate()
          .fadeIn(duration: AppMotion.slow)
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: AppMotion.slow,
            curve: AppMotion.emphasized,
          );
      name = name.animate().fadeIn(delay: 250.ms, duration: AppMotion.medium).slideY(
            begin: 0.25,
            end: 0,
            delay: 250.ms,
            duration: AppMotion.medium,
            curve: AppMotion.standard,
          );
      line = line.animate().fadeIn(delay: 500.ms, duration: AppMotion.medium);
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            spark,
            const SizedBox(height: AppSpacing.lg),
            name,
            const SizedBox(height: AppSpacing.xs),
            line,
          ],
        ),
      ),
    );
  }
}
