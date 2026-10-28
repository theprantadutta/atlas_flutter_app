import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Semantic, theme-aware palette for Atlas Daylight.
///
/// Widgets read surface and text colors ONLY via `context.palette.x`. Never
/// branch on brightness inside widgets: [AtlasPalette.light] and
/// [AtlasPalette.dark] are registered as theme extensions in `app_theme.dart`
/// and are the single switch. Gradients don't change between themes; they
/// live on [AppColors].
@immutable
class AtlasPalette extends ThemeExtension<AtlasPalette> {
  const AtlasPalette({
    required this.canvas,
    required this.paper,
    required this.raised,
    required this.raisedBorder,
    required this.onRaised,
    required this.action,
    required this.onAction,
    required this.navPill,
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
    required this.pine,
    required this.moodHeavy,
    required this.moodLow,
    required this.moodOkay,
    required this.moodGood,
    required this.moodBright,
    required this.tintAlpha,
    required this.isDark,
  });

  /// Screen background, sheets, chat composer.
  final Color canvas;

  /// Rows, tiles, inputs, icon buttons, Aurora's bubble.
  final Color paper;

  /// The "heavy" containers: hero card, nav pill, Next card, Best day tile.
  /// Ink in light; raised charcoal with a 1px [raisedBorder] in dark.
  final Color raised;
  final Color raisedBorder;

  /// Text on [raised].
  final Color onRaised;

  /// Primary actions: Tend, Listen, segmented pill, user bubble, ink Add.
  /// Ink in light; flips to cream in dark so it stays the brightest thing.
  final Color action;
  final Color onAction;

  /// The active pill inside the nav bar (white in light, cream in dark).
  final Color navPill;

  final Color progressFill, chartBar;
  final Color textPrimary, textBody, textSecondary, textMuted, textFaint;
  final Color chevron, iconInactive, track, hairline, sparkEmpty, outline;
  final LinearGradient letter;
  final Color letterSecondaryButton, recommendedBorder, success, successBg;
  final Color scrim, skeleton, skeletonHighlight;

  /// The deep-green category color, lifted in dark for contrast.
  final Color pine;

  /// Check-in moods, 1 (heavy) to 5 (bright). Calm and ungraded.
  final Color moodHeavy, moodLow, moodOkay, moodGood, moodBright;

  /// The colour for check-in [mood] (1 to 5).
  Color mood(int mood) => switch (mood) {
        <= 1 => moodHeavy,
        2 => moodLow,
        3 => moodOkay,
        4 => moodGood,
        _ => moodBright,
      };

  /// Light uses solid pastel tints; dark uses the category fg at this alpha.
  final double? tintAlpha;

  /// Only for things that genuinely need it (system overlay style); widgets
  /// should never branch on this.
  final bool isDark;

  /// 1px border for raised containers in dark; none in light.
  Border? get raisedBorderSide =>
      raisedBorder.a == 0 ? null : Border.all(color: raisedBorder);

  /// The category foreground for this theme (pine is lifted in dark).
  Color category(Color fg) =>
      fg.toARGB32() == AppColors.pine.toARGB32() ? pine : fg;

  /// Category tint background for an icon tile.
  Color tint(Color fg) {
    final alpha = tintAlpha;
    if (alpha == null) return AppColors.tintFor(fg);
    final c = category(fg);
    if (c == pine) return c.withValues(alpha: .24);
    if (fg.toARGB32() == AppColors.violet.toARGB32()) {
      return c.withValues(alpha: .2);
    }
    return c.withValues(alpha: alpha);
  }

  static const light = AtlasPalette(
    canvas: AppColors.canvas,
    paper: AppColors.paper,
    raised: AppColors.ink,
    raisedBorder: Color(0x00000000),
    onRaised: AppColors.white,
    action: AppColors.ink,
    onAction: AppColors.white,
    navPill: AppColors.white,
    progressFill: AppColors.ink,
    chartBar: AppColors.ink,
    textPrimary: AppColors.ink,
    textBody: AppColors.inkSoft,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    textFaint: AppColors.textFaint,
    chevron: AppColors.chevron,
    iconInactive: AppColors.iconInactive,
    track: AppColors.track,
    hairline: AppColors.hairline,
    sparkEmpty: AppColors.hairline,
    outline: AppColors.outline,
    letter: LinearGradient(
      begin: Alignment(-0.6, -1),
      end: Alignment(0.6, 1),
      colors: [AppColors.letterA, AppColors.letterB, AppColors.letterC],
      stops: [0, .5, 1],
    ),
    letterSecondaryButton: Color(0xB3FFFFFF),
    recommendedBorder: Color(0xFFFFB8A8),
    success: AppColors.pine,
    successBg: AppColors.leafTint,
    scrim: Color(0x5916140F),
    skeleton: AppColors.track,
    skeletonHighlight: Color(0xFFF7F4EE),
    pine: AppColors.pine,
    moodHeavy: AppColors.moodHeavy,
    moodLow: AppColors.moodLow,
    moodOkay: AppColors.moodOkay,
    moodGood: AppColors.moodGood,
    moodBright: AppColors.moodBright,
    tintAlpha: null,
    isDark: false,
  );

  static const dark = AtlasPalette(
    canvas: AppColors.canvasDark,
    paper: AppColors.paperDark,
    raised: AppColors.raisedDark,
    raisedBorder: AppColors.borderDark,
    onRaised: AppColors.cream,
    action: AppColors.cream,
    onAction: AppColors.ink,
    navPill: AppColors.cream,
    progressFill: AppColors.cream,
    chartBar: AppColors.chartBarDark,
    textPrimary: AppColors.cream,
    textBody: AppColors.textBodyDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    textFaint: AppColors.textFaintDark,
    chevron: AppColors.chevronDark,
    iconInactive: AppColors.iconInactive,
    track: AppColors.trackDark,
    hairline: AppColors.trackDark,
    sparkEmpty: AppColors.borderDark,
    outline: AppColors.chartBarDark,
    letter: LinearGradient(
      begin: Alignment(-0.6, -1),
      end: Alignment(0.6, 1),
      colors: [
        AppColors.letterDarkA,
        AppColors.letterDarkB,
        AppColors.letterDarkC,
      ],
      stops: [0, .5, 1],
    ),
    letterSecondaryButton: Color(0x1AFFFFFF),
    recommendedBorder: Color(0x99FF5E62),
    success: AppColors.successDark,
    successBg: Color(0x2E2FBF71),
    scrim: Color(0x8C000000),
    skeleton: AppColors.trackDark,
    skeletonHighlight: AppColors.borderDark,
    pine: AppColors.successDark,
    moodHeavy: AppColors.moodHeavyDark,
    moodLow: AppColors.moodLowDark,
    moodOkay: AppColors.moodOkayDark,
    moodGood: AppColors.moodGoodDark,
    moodBright: AppColors.moodBrightDark,
    tintAlpha: .18,
    isDark: true,
  );

  /// Links in markdown, the today label, the unread dot.
  static const accent = AppColors.sunriseB;

  @override
  AtlasPalette copyWith() => this;

  @override
  AtlasPalette lerp(ThemeExtension<AtlasPalette>? other, double t) {
    if (other is! AtlasPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AtlasPalette(
      canvas: c(canvas, other.canvas),
      paper: c(paper, other.paper),
      raised: c(raised, other.raised),
      raisedBorder: c(raisedBorder, other.raisedBorder),
      onRaised: c(onRaised, other.onRaised),
      action: c(action, other.action),
      onAction: c(onAction, other.onAction),
      navPill: c(navPill, other.navPill),
      progressFill: c(progressFill, other.progressFill),
      chartBar: c(chartBar, other.chartBar),
      textPrimary: c(textPrimary, other.textPrimary),
      textBody: c(textBody, other.textBody),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      textFaint: c(textFaint, other.textFaint),
      chevron: c(chevron, other.chevron),
      iconInactive: c(iconInactive, other.iconInactive),
      track: c(track, other.track),
      hairline: c(hairline, other.hairline),
      sparkEmpty: c(sparkEmpty, other.sparkEmpty),
      outline: c(outline, other.outline),
      letter: LinearGradient.lerp(letter, other.letter, t)!,
      letterSecondaryButton:
          c(letterSecondaryButton, other.letterSecondaryButton),
      recommendedBorder: c(recommendedBorder, other.recommendedBorder),
      success: c(success, other.success),
      successBg: c(successBg, other.successBg),
      scrim: c(scrim, other.scrim),
      skeleton: c(skeleton, other.skeleton),
      skeletonHighlight: c(skeletonHighlight, other.skeletonHighlight),
      pine: c(pine, other.pine),
      moodHeavy: c(moodHeavy, other.moodHeavy),
      moodLow: c(moodLow, other.moodLow),
      moodOkay: c(moodOkay, other.moodOkay),
      moodGood: c(moodGood, other.moodGood),
      moodBright: c(moodBright, other.moodBright),
      tintAlpha: t < .5 ? tintAlpha : other.tintAlpha,
      isDark: t < .5 ? isDark : other.isDark,
    );
  }
}

extension AtlasPaletteX on BuildContext {
  AtlasPalette get palette =>
      Theme.of(this).extension<AtlasPalette>() ?? AtlasPalette.light;
}
