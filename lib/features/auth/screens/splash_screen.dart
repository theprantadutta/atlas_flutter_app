import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.primaryDark, AppColors.surfaceDark]
                : [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 56,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // App name
            Text(
              'Atlas',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Level Up Your Life',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms),

            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
