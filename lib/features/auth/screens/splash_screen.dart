import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/atlas_logo.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/living_horizon.dart';

/// First impression: the living world wakes up, the mark rises, the name fades
/// in. Calm and unhurried.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The world as the backdrop.
          LivingHorizon(
            height: size.height,
            progress: 0.7,
            borderRadius: BorderRadius.zero,
            brightness: Brightness.dark,
          ),
          // Gentle scrim so the mark reads clearly.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surfaceDark.withValues(alpha: 0.35),
                  Colors.transparent,
                  AppColors.surfaceDark.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AtlasLogoBadge(size: 116)
                    .animate()
                    .fadeIn(duration: AppMotion.slow)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                      duration: AppMotion.slow,
                      curve: AppMotion.emphasized,
                    ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Atlas',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                ).animate().fadeIn(delay: 250.ms, duration: AppMotion.medium).slideY(
                      begin: 0.25,
                      end: 0,
                      delay: 250.ms,
                      duration: AppMotion.medium,
                      curve: AppMotion.standard,
                    ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Grow a little, every day.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                ).animate().fadeIn(delay: 500.ms, duration: AppMotion.medium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
