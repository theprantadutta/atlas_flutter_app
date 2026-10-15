import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// First impression: the white spark on the coral launch ground, then the
/// name. The native splash shows the same spark at the same size in the same
/// spot, so the handoff is invisible and only the words arrive.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _sparkSize = 96.0; // matches assets/brand/splash_spark*.png

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    final onSplash = AppColors.white;

    Widget name = Text('Atlas', style: AppTypography.display(size: 44, color: onSplash));
    Widget line = Text('Every day, a small sunrise.',
        style: AppTypography.sans(
            size: 16, weight: FontWeight.w500, color: onSplash.withValues(alpha: .82)));

    if (!reduce) {
      name = name.animate().fadeIn(delay: 150.ms, duration: AppMotion.medium).slideY(
            begin: 0.25,
            end: 0,
            delay: 150.ms,
            duration: AppMotion.medium,
            curve: AppMotion.standard,
          );
      line = line.animate().fadeIn(delay: 400.ms, duration: AppMotion.medium);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.splash,
      ),
      child: Scaffold(
        backgroundColor: AppColors.splash,
        // Equal halves around the spark keep it at the exact center, where
        // the native splash left it; the words hang below.
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const AtlasSpark(
              size: _sparkSize,
              variant: SparkVariant.white,
              semanticLabel: 'Atlas',
            ),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  name,
                  const SizedBox(height: AppSpacing.xs),
                  line,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
