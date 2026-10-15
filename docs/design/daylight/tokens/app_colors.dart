import 'package:flutter/material.dart';

/// Atlas "Daylight" palette.
///
/// Light-first. Warm canvas + ink do the heavy lifting; the sunrise gradient
/// (amber → coral → violet) is reserved for things that are alive: done
/// checks, completed progress, the FAB, Aurora's spark, best-day highlights.
///
/// Legacy token NAMES are kept (mapped to new values) so existing widgets
/// compile during migration. Remove the legacy block once every screen is on
/// the new names.
class AppColors {
  AppColors._();

  // ─── Core ───
  static const canvas = Color(0xFFF4F1EA);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF16140F);
  static const inkSoft = Color(0xFF4A453E);
  static const textSecondary = Color(0xFF5E5A53);
  static const textMuted = Color(0xFF6E695F); // mock used #77726A; darkened for 4.5:1 on canvas
  static const textFaint = Color(0xFFA39E95);
  static const iconInactive = Color(0xFF8C877E);
  static const chevron = Color(0xFFB3ADA2);
  static const track = Color(0xFFECE7DD);
  static const hairline = Color(0xFFE7E2D8);
  static const outline = Color(0xFFDDD6C9);

  // ─── Sunrise signature ───
  static const sunriseA = Color(0xFFFFB36B);
  static const sunriseB = Color(0xFFFF5E62);
  static const sunriseC = Color(0xFF8E6CFF);

  // ─── Soft letter tints ───
  static const letterA = Color(0xFFFFE7D6);
  static const letterB = Color(0xFFFFDDE3);
  static const letterC = Color(0xFFE9E2FF);

  // ─── Category (fg / tint) ───
  static const coral = Color(0xFFFF6A4D), coralTint = Color(0xFFFFE9E3);
  static const sky = Color(0xFF3FA7F5), skyTint = Color(0xFFE3F1FD);
  static const leaf = Color(0xFF2FBF71), leafTint = Color(0xFFE2F6EA);
  static const pine = Color(0xFF1E9A58), pineTint = Color(0xFFDDF2E6);
  static const violet = Color(0xFF8E6CFF), violetTint = Color(0xFFEEE8FF);
  static const amber = Color(0xFFF5A524), amberTint = Color(0xFFFDF2DC);

  static const categoryHealth = coral;
  static const categoryFitness = coral;
  static const categoryMindfulness = violet;
  static const categoryFinance = pine;
  static const categoryWork = sky;
  static const categoryLearning = sky;
  static const categorySocial = sunriseB;
  static const categoryCreative = amber;

  /// Tint background for a category foreground color.
  static Color tintFor(Color c) => switch (c.toARGB32()) {
        0xFFFF6A4D => coralTint,
        0xFF3FA7F5 => skyTint,
        0xFF2FBF71 => leafTint,
        0xFF1E9A58 => pineTint,
        0xFF8E6CFF => violetTint,
        0xFFF5A524 => amberTint,
        _ => track,
      };

  // ─── Status ───
  static const success = pine;
  static const successTint = leafTint;
  static const warning = amber;
  static const error = coral;
  static const info = sky;

  // ─── Dark theme ("after dark") — see DARK_THEME.md; widgets should use
  // context.palette (tokens/app_palette.dart) rather than these directly ───
  static const canvasDark = Color(0xFF0F0E0B);
  static const paperDark = Color(0xFF1C1A16);
  static const heroDark = Color(0xFF26231D); // raised ink containers
  static const borderDark = Color(0xFF34302A); // raised border, empty sparkline
  static const trackDark = Color(0xFF2A2722); // tracks, dividers
  static const actionDark = Color(0xFFF4F1EA); // primary fills flip to cream
  static const chartBarDark = Color(0xFF4A453E);
  static const outlineDark = Color(0xFF4A453E);
  static const textPrimaryDark = Color(0xFFF4F1EA);
  static const textBodyDark = Color(0xFFD9D2C5);
  static const textSecondaryDark2 = Color(0xFFA8A296);
  static const textMutedDark = Color(0xFF9C968B);
  static const textFaintDark = Color(0xFF6E695F);
  static const chevronDark = Color(0xFF5E5A53);
  static const successDark = Color(0xFF4FD08A);
  static const letterDarkA = Color(0xFF3A2418);
  static const letterDarkB = Color(0xFF3A1C26);
  static const letterDarkC = Color(0xFF241C45);
  static const letterDark = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [letterDarkA, letterDarkB, letterDarkC],
    stops: [0, .5, 1],
  );

  // ─── Gradients ───
  static const sunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunriseA, sunriseB, sunriseC],
    stops: [0, .55, 1],
  );

  static const sunriseBar = LinearGradient(
    colors: [sunriseA, sunriseB, sunriseC],
    stops: [0, .55, 1],
  );

  static const sunriseVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sunriseA, sunriseB, sunriseC],
    stops: [0, .55, 1],
  );

  static const letter = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [letterA, letterB, letterC],
    stops: [0, .5, 1],
  );

  static const heroGlow = RadialGradient(
    center: Alignment(-0.2, -0.1),
    colors: [sunriseA, sunriseB, sunriseC, Color(0x008E6CFF)],
    stops: [0, .38, .62, .72],
  );

  static const globe = RadialGradient(
    center: Alignment(-0.32, -0.44),
    radius: 0.9,
    colors: [Color(0xFFFFF4E8), Color(0xFFFFC79A), Color(0xFFFF7F6A), Color(0xFFB565D8), Color(0xFF5B3CC4)],
    stops: [0, .22, .48, .72, 1],
  );

  static const fabShadow = [BoxShadow(color: Color(0x66FF5E62), blurRadius: 26, offset: Offset(0, 12))];
  static const globeShadow = [BoxShadow(color: Color(0x595B3CC4), blurRadius: 80, offset: Offset(0, 40))];

  // ─── Legacy names (temporary; mapped to Daylight) ───
  static const primary = ink;
  static const primaryLight = sunriseC;
  static const secondary = sunriseB;
  static const tertiary = amber;
  static const tertiaryLight = sunriseA;
  static const xpPrimary = sunriseB;
  static const streakFlame = sunriseA;
  static const surfaceLight = canvas;
  static const cardLight = paper;
  static const cardBorderLight = hairline;
  static const surfaceDark = canvasDark;
  static const cardDark = paperDark;
  static const cardBorderDark = borderDark;
  static const textPrimaryLight = ink;
  static const textSecondaryLight = textMuted;
  static const textSecondaryDark = textMutedDark;
  static const auroraGradient = sunrise;
}
