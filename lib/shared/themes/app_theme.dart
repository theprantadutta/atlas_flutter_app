import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';

/// Atlas "Daylight" theme, light and dark ("after dark").
///
/// Flat surfaces, no ripples, pills everywhere you can press. Both themes are
/// built from one [AtlasPalette], registered as a theme extension so widgets
/// read `context.palette` and never branch on brightness.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AtlasPalette.light);
  static ThemeData get dark => _build(AtlasPalette.dark);

  /// Status and navigation bar style for a palette.
  static SystemUiOverlayStyle overlayFor(AtlasPalette p) =>
      (p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: p.canvas,
        systemNavigationBarDividerColor: p.canvas,
        systemNavigationBarIconBrightness:
            p.isDark ? Brightness.light : Brightness.dark,
      );

  static ThemeData _build(AtlasPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.action,
      onPrimary: p.onAction,
      primaryContainer: p.track,
      onPrimaryContainer: p.textPrimary,
      secondary: AppColors.sunriseB,
      onSecondary: AppColors.white,
      secondaryContainer: p.tint(AppColors.sunriseB),
      onSecondaryContainer: p.textPrimary,
      tertiary: AppColors.amber,
      onTertiary: AppColors.ink,
      tertiaryContainer: p.tint(AppColors.amber),
      onTertiaryContainer: p.textPrimary,
      error: AppColors.coral,
      onError: AppColors.white,
      errorContainer: p.tint(AppColors.coral),
      onErrorContainer: p.textPrimary,
      surface: p.canvas,
      onSurface: p.textPrimary,
      surfaceContainerLowest: p.paper,
      surfaceContainerLow: p.paper,
      surfaceContainer: p.paper,
      surfaceContainerHigh: p.paper,
      surfaceContainerHighest: p.paper,
      onSurfaceVariant: p.textMuted,
      outline: p.hairline,
      outlineVariant: p.hairline,
      shadow: Colors.transparent,
      scrim: p.scrim,
      inverseSurface: p.raised,
      onInverseSurface: p.onRaised,
      inversePrimary: AppColors.sunriseA,
      surfaceTint: Colors.transparent,
    );

    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    );
    final buttonText = AppTypography.sans(size: 15, weight: FontWeight.w700);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      fontFamily: AppTypography.sansFamily,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.canvas,
      dividerColor: p.hairline,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: p.track,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [p],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayFor(p),
        titleTextStyle: AppTypography.section.copyWith(color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      iconTheme: IconThemeData(color: p.textPrimary, size: 22),
      cardTheme: CardThemeData(
        color: p.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.action,
          foregroundColor: p.onAction,
          disabledBackgroundColor: p.track,
          disabledForegroundColor: p.textFaint,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.action,
          foregroundColor: p.onAction,
          disabledBackgroundColor: p.track,
          disabledForegroundColor: p.textFaint,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          backgroundColor: p.track,
          side: BorderSide.none,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.textPrimary,
          shape: pill,
          textStyle: AppTypography.sans(size: 14, weight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.paper,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg - 4,
          vertical: AppSpacing.md + 1,
        ),
        hintStyle: AppTypography.sans(size: 15, color: p.textFaint),
        labelStyle:
            AppTypography.sans(size: 14, weight: FontWeight.w600, color: p.textMuted),
        floatingLabelStyle:
            AppTypography.sans(size: 14, weight: FontWeight.w700, color: p.textPrimary),
        helperStyle: AppTypography.meta.copyWith(color: p.textMuted),
        errorStyle: AppTypography.meta.copyWith(color: AppColors.coral),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        disabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(p.textPrimary, width: 1.5),
        errorBorder: _inputBorder(AppColors.coral),
        focusedErrorBorder: _inputBorder(AppColors.coral, width: 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.sunriseB,
        selectionColor: AppColors.sunriseB.withValues(alpha: .25),
        selectionHandleColor: AppColors.sunriseB,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAction : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.action : p.outline,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        thumbIcon: WidgetStateProperty.all(null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.action : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(p.onAction),
        side: BorderSide(color: p.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.action : p.outline,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.action,
        inactiveTrackColor: p.track,
        thumbColor: p.action,
        overlayColor: Colors.transparent,
        trackHeight: 6,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.action,
        linearTrackColor: p.track,
        circularTrackColor: p.track,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.paper,
        selectedColor: p.action,
        disabledColor: p.track,
        labelStyle: AppTypography.chip.copyWith(color: p.textPrimary),
        secondaryLabelStyle: AppTypography.chip.copyWith(color: p.onAction),
        side: BorderSide.none,
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        showCheckmark: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.canvas,
        modalBackgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: p.scrim,
        showDragHandle: true,
        dragHandleColor: p.outline,
        dragHandleSize: const Size(40, 5),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: p.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: AppTypography.section.copyWith(color: p.textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: p.textBody),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.raised,
        contentTextStyle:
            AppTypography.sans(size: 14, weight: FontWeight.w600, color: p.onRaised),
        actionTextColor: AppColors.sunriseA,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: StadiumBorder(
          side: p.raisedBorder.a == 0
              ? BorderSide.none
              : BorderSide(color: p.raisedBorder),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: AppTypography.sans(size: 14, weight: FontWeight.w600, color: p.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          side: BorderSide(color: p.hairline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textPrimary,
        textColor: p.textPrimary,
        titleTextStyle: AppTypography.rowTitle.copyWith(color: p.textPrimary),
        subtitleTextStyle: AppTypography.meta.copyWith(color: p.textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.raised,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        textStyle: AppTypography.metaStrong.copyWith(color: p.onRaised),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        headerBackgroundColor: p.canvas,
        headerForegroundColor: p.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAction : p.textPrimary,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.action : Colors.transparent,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAction : AppColors.sunriseB,
        ),
        todayBorder: const BorderSide(color: AppColors.sunriseB),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        dialBackgroundColor: p.paper,
        hourMinuteColor: p.paper,
        dayPeriodColor: p.track,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        borderSide: color == Colors.transparent
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
}
