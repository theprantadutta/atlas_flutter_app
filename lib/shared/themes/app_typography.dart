import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Atlas type system.
///
/// Fraunces (a soft, warm serif) carries personality in display + headlines,
/// used with restraint. Hanken Grotesk handles titles, body and labels — calm,
/// modern, highly readable. Numbers lean on Hanken's tabular figures.
class AppTypography {
  AppTypography._();

  /// Warm soft-serif for expressive moments (greetings, big numbers, titles).
  static TextStyle display(
          {double size = 32,
          FontWeight weight = FontWeight.w600,
          double spacing = -0.5,
          Color? color,
          double? height}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
        color: color,
      );

  static TextTheme get textTheme => TextTheme(
        // ─── Display & headlines: Fraunces ───
        displayLarge: GoogleFonts.fraunces(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.05,
        ),
        displayMedium: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.08,
        ),
        displaySmall: GoogleFonts.fraunces(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        headlineLarge: GoogleFonts.fraunces(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: GoogleFonts.fraunces(
          fontSize: 19,
          fontWeight: FontWeight.w500,
        ),
        // ─── Titles, body & labels: Hanken Grotesk ───
        titleLarge: GoogleFonts.hankenGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: GoogleFonts.hankenGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.hankenGrotesk(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.hankenGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
}
