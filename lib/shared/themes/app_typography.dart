import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      );
}
