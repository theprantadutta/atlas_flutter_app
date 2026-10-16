import 'package:flutter/material.dart';

/// Semantic, theme-aware palette for Atlas Daylight.
///
/// Widgets read colors ONLY via `context.palette.x`. Never branch on
/// brightness inside widgets; register both instances in app_theme.dart:
///   ThemeData(extensions: [AtlasPalette.light]) / [AtlasPalette.dark]
@immutable
class AtlasPalette extends ThemeExtension<AtlasPalette> {
  const AtlasPalette({
    required this.canvas,
    required this.paper,
    required this.raised,
    required this.raisedBorder,
    required this.action,
    required this.onAction,
    required this.progressFill,
    required this.chartBar,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.chevron,
    required this.iconInactive,
    required this.track,
    required this.hairline,
    required this.sparkEmpty,
    required this.outline,
    required this.letter,
    required this.letterSecondaryButton,
    required this.recommendedBorder,
    required this.success,
    required this.successBg,
    required this.scrim,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.tintAlpha,
    required this.pine,
  });

  final Color canvas, paper, raised, raisedBorder, action, onAction, progressFill, chartBar;
  final Color textPrimary, textBody, textSecondary, textMuted, textFaint, chevron, iconInactive;
  final Color track, hairline, sparkEmpty, outline;
  final LinearGradient letter;
  final Color letterSecondaryButton, recommendedBorder, success, successBg, scrim, skeleton, skeletonHighlight;

  /// Light uses solid pastel tints; dark uses the category fg at this alpha.
  final double? tintAlpha;
  final Color pine;

  /// Hero/Next/Best-day container color.
  /// Light: ink, no border. Dark: raised charcoal with 1px border.
  Border? get raisedBorderSide => raisedBorder.a == 0 ? null : Border.all(color: raisedBorder);

  /// Category tint background for an icon tile.
  Color tint(Color fg, Color lightTint) =>
      tintAlpha == null ? lightTint : fg.withValues(alpha: fg == pine ? .24 : (fg.toARGB32() == 0xFF8E6CFF ? .2 : tintAlpha!));

  static const _sunriseA = Color(0xFFFFB36B);
  static const _sunriseB = Color(0xFFFF5E62);

  static const light = AtlasPalette(
    canvas: Color(0xFFF4F1EA),
    paper: Color(0xFFFFFFFF),
    raised: Color(0xFF16140F),
    raisedBorder: Color(0x00000000),
    action: Color(0xFF16140F),
    onAction: Color(0xFFFFFFFF),
    progressFill: Color(0xFF16140F),
    chartBar: Color(0xFF16140F),
    textPrimary: Color(0xFF16140F),
    textBody: Color(0xFF4A453E),
    textSecondary: Color(0xFF5E5A53),
    textMuted: Color(0xFF6E695F),
    textFaint: Color(0xFFA39E95),
    chevron: Color(0xFFB3ADA2),
    iconInactive: Color(0xFF8C877E),
    track: Color(0xFFECE7DD),
    hairline: Color(0xFFE7E2D8),
    sparkEmpty: Color(0xFFE7E2D8),
    outline: Color(0xFFDDD6C9),
    letter: LinearGradient(
      begin: Alignment(-0.6, -1), end: Alignment(0.6, 1),
      colors: [Color(0xFFFFE7D6), Color(0xFFFFDDE3), Color(0xFFE9E2FF)], stops: [0, .5, 1]),
    letterSecondaryButton: Color(0xB3FFFFFF),
    recommendedBorder: Color(0xFFFFB8A8),
    success: Color(0xFF1E9A58),
    successBg: Color(0xFFE2F6EA),
    scrim: Color(0x5916140F),
    skeleton: Color(0xFFECE7DD),
    skeletonHighlight: Color(0xFFF7F4EE),
    tintAlpha: null,
    pine: Color(0xFF1E9A58),
  );

  static const dark = AtlasPalette(
    canvas: Color(0xFF0F0E0B),
    paper: Color(0xFF1C1A16),
    raised: Color(0xFF26231D),
    raisedBorder: Color(0xFF34302A),
    action: Color(0xFFF4F1EA),
    onAction: Color(0xFF16140F),
    progressFill: Color(0xFFF4F1EA),
    chartBar: Color(0xFF4A453E),
    textPrimary: Color(0xFFF4F1EA),
    textBody: Color(0xFFD9D2C5),
    textSecondary: Color(0xFFA8A296),
    textMuted: Color(0xFF9C968B),
    textFaint: Color(0xFF6E695F),
    chevron: Color(0xFF5E5A53),
    iconInactive: Color(0xFF8C877E),
    track: Color(0xFF2A2722),
    hairline: Color(0xFF2A2722),
    sparkEmpty: Color(0xFF34302A),
    outline: Color(0xFF4A453E),
    letter: LinearGradient(
      begin: Alignment(-0.6, -1), end: Alignment(0.6, 1),
      colors: [Color(0xFF3A2418), Color(0xFF3A1C26), Color(0xFF241C45)], stops: [0, .5, 1]),
    letterSecondaryButton: Color(0x1AFFFFFF),
    recommendedBorder: Color(0x99FF5E62),
    success: Color(0xFF4FD08A),
    successBg: Color(0x2E2FBF71),
    scrim: Color(0x8C000000),
    skeleton: Color(0xFF2A2722),
    skeletonHighlight: Color(0xFF34302A),
    tintAlpha: .18,
    pine: Color(0xFF4FD08A),
  );

  // Gradient-related colors are theme-independent; see AppColors.sunrise etc.
  static const linkColor = _sunriseB;
  static const streakFlame = _sunriseA;

  @override
  AtlasPalette copyWith() => this;

  @override
  AtlasPalette lerp(ThemeExtension<AtlasPalette>? other, double t) {
    if (other is! AtlasPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AtlasPalette(
      canvas: c(canvas, other.canvas), paper: c(paper, other.paper), raised: c(raised, other.raised),
      raisedBorder: c(raisedBorder, other.raisedBorder), action: c(action, other.action), onAction: c(onAction, other.onAction),
      progressFill: c(progressFill, other.progressFill), chartBar: c(chartBar, other.chartBar),
      textPrimary: c(textPrimary, other.textPrimary), textBody: c(textBody, other.textBody),
      textSecondary: c(textSecondary, other.textSecondary), textMuted: c(textMuted, other.textMuted),
      textFaint: c(textFaint, other.textFaint), chevron: c(chevron, other.chevron), iconInactive: c(iconInactive, other.iconInactive),
      track: c(track, other.track), hairline: c(hairline, other.hairline), sparkEmpty: c(sparkEmpty, other.sparkEmpty),
      outline: c(outline, other.outline), letter: LinearGradient.lerp(letter, other.letter, t)!,
      letterSecondaryButton: c(letterSecondaryButton, other.letterSecondaryButton),
      recommendedBorder: c(recommendedBorder, other.recommendedBorder), success: c(success, other.success),
      successBg: c(successBg, other.successBg), scrim: c(scrim, other.scrim), skeleton: c(skeleton, other.skeleton),
      skeletonHighlight: c(skeletonHighlight, other.skeletonHighlight),
      tintAlpha: t < .5 ? tintAlpha : other.tintAlpha, pine: c(pine, other.pine),
    );
  }
}

extension AtlasPaletteX on BuildContext {
  AtlasPalette get palette => Theme.of(this).extension<AtlasPalette>() ?? AtlasPalette.light;
}
