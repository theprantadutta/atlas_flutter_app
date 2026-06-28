import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Atlas "Living World / Aurora" theme.
///
/// Soft, organic radii; calm surfaces (twilight ink in dark, dawn paper in
/// light); the aurora accent reserved for highlights. Component shadows are
/// applied by the shared widgets (e.g. AppCard) for finer control, so the
/// theme keeps surfaces clean.
class AppTheme {
  AppTheme._();

  static const double _cardRadius = AppSpacing.radiusLg; // 24
  static const double _buttonRadius = AppSpacing.radiusPill; // pill
  static const double _inputRadius = AppSpacing.radiusMd; // 18
  static const double _chipRadius = AppSpacing.radiusPill; // pill
  static const double _sheetRadius = AppSpacing.radiusXl; // 32

  // ═══════════════════════════════════════════════════════════════
  //  LIGHT THEME — "dawn paper"
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get light {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: AppColors.textPrimaryLight,
      displayColor: AppColors.textPrimaryLight,
    );

    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight.withValues(alpha: 0.14),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryLight.withValues(alpha: 0.16),
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiaryLight.withValues(alpha: 0.18),
      onTertiaryContainer: AppColors.tertiaryDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.10),
      onErrorContainer: AppColors.error,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.cardLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.cardBorderLight,
      outlineVariant: AppColors.cardBorderLight.withValues(alpha: 0.6),
      shadow: const Color(0xFF1A1F2E).withValues(alpha: 0.10),
    );

    return _base(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffold: AppColors.surfaceLight,
      card: AppColors.cardLight,
      cardBorder: AppColors.cardBorderLight,
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      action: AppColors.primary,
      onAction: Colors.white,
      overlayStyle: SystemUiOverlayStyle.dark,
      snackBg: AppColors.textPrimaryLight,
      snackFg: AppColors.surfaceLight,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DARK THEME — "twilight ink" (the hero)
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get dark {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: AppColors.textPrimaryDark,
      displayColor: AppColors.textPrimaryDark,
    );

    final colorScheme = ColorScheme.dark(
      primary: AppColors.secondaryLight,
      onPrimary: AppColors.surfaceDark,
      primaryContainer: AppColors.secondaryLight.withValues(alpha: 0.18),
      onPrimaryContainer: AppColors.secondaryLight,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.surfaceDark,
      secondaryContainer: AppColors.primaryLight.withValues(alpha: 0.18),
      onSecondaryContainer: AppColors.primaryLight,
      tertiary: AppColors.tertiaryLight,
      onTertiary: AppColors.surfaceDark,
      tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.18),
      onTertiaryContainer: AppColors.tertiaryLight,
      error: AppColors.error,
      onError: AppColors.surfaceDark,
      errorContainer: AppColors.error.withValues(alpha: 0.20),
      onErrorContainer: AppColors.streakGlow,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceHighDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.cardBorderDark,
      outlineVariant: AppColors.cardBorderDark.withValues(alpha: 0.6),
      shadow: Colors.black.withValues(alpha: 0.45),
    );

    return _base(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffold: AppColors.surfaceDark,
      card: AppColors.cardDark,
      cardBorder: AppColors.cardBorderDark,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      action: AppColors.secondaryLight,
      onAction: AppColors.surfaceDark,
      overlayStyle: SystemUiOverlayStyle.light,
      snackBg: AppColors.surfaceHighDark,
      snackFg: AppColors.textPrimaryDark,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Shared builder
  // ═══════════════════════════════════════════════════════════════
  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required Color scaffold,
    required Color card,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color action,
    required Color onAction,
    required SystemUiOverlayStyle overlayStyle,
    required Color snackBg,
    required Color snackFg,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: textPrimary),
        systemOverlayStyle: overlayStyle,
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),

      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: action,
          foregroundColor: onAction,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          side: BorderSide(color: cardBorder, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: action,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: action, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: action.withValues(alpha: 0.16),
        side: BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
        ),
        dragHandleColor: cardBorder,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_sheetRadius),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: textPrimary),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: action,
        foregroundColor: onAction,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: action.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(color: textSecondary),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? action : textSecondary,
            size: 24,
          );
        }),
        height: 76,
      ),

      dividerTheme: DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBg,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: snackFg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: action,
        unselectedLabelColor: textSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: action, width: 3),
          borderRadius: BorderRadius.circular(3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: action,
        linearTrackColor: cardBorder,
        circularTrackColor: cardBorder,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onAction;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return action;
          return cardBorder;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: snackBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: snackFg),
      ),
    );
  }
}
