import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // ─── Common Constants ───
  static const double _borderRadius = 16.0;
  static const double _buttonRadius = 28.0;
  static const double _inputRadius = 14.0;
  static const double _cardRadius = 20.0;
  static const double _chipRadius = 12.0;
  static const double _dialogRadius = 24.0;
  static const double _bottomSheetRadius = 24.0;

  // ═══════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get light {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: AppColors.textPrimaryLight,
      displayColor: AppColors.textPrimaryLight,
    );

    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight.withValues(alpha: 0.12),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryLight.withValues(alpha: 0.12),
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiaryLight.withValues(alpha: 0.12),
      onTertiaryContainer: AppColors.tertiaryDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.08),
      onErrorContainer: AppColors.error,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.cardBorderLight,
      outlineVariant: AppColors.cardBorderLight.withValues(alpha: 0.5),
      shadow: Colors.black.withValues(alpha: 0.08),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surfaceLight,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
          size: 24,
        ),
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: const BorderSide(
            color: AppColors.cardBorderLight,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Input Decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.cardBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.cardBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.textSecondaryLight,
        suffixIconColor: AppColors.textSecondaryLight,
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.cardBorderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_bottomSheetRadius),
          ),
        ),
        dragHandleColor: AppColors.cardBorderLight,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),

      // ─── Floating Action Button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),

      // ─── Navigation Bar (Bottom) ───
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textSecondaryLight,
            size: 24,
          );
        }),
        height: 72,
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorderLight,
        thickness: 1,
        space: 1,
      ),

      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondaryLight,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.cardBorderLight,
        circularTrackColor: AppColors.cardBorderLight,
      ),

      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textSecondaryLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.cardBorderLight;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // ─── Tooltip ───
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get dark {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: AppColors.textPrimaryDark,
      displayColor: AppColors.textPrimaryDark,
    );

    final colorScheme = ColorScheme.dark(
      primary: AppColors.secondaryLight,
      onPrimary: AppColors.primaryDark,
      primaryContainer: AppColors.primaryLight.withValues(alpha: 0.16),
      onPrimaryContainer: AppColors.secondaryLight,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.16),
      onSecondaryContainer: AppColors.secondaryLight,
      tertiary: AppColors.tertiaryLight,
      onTertiary: AppColors.primaryDark,
      tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.16),
      onTertiaryContainer: AppColors.tertiaryLight,
      error: AppColors.streakGlow,
      onError: AppColors.primaryDark,
      errorContainer: AppColors.error.withValues(alpha: 0.16),
      onErrorContainer: AppColors.streakGlow,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.cardBorderDark,
      outlineVariant: AppColors.cardBorderDark.withValues(alpha: 0.5),
      shadow: Colors.black.withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surfaceDark,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 24,
        ),
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: const BorderSide(
            color: AppColors.cardBorderDark,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryLight,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          side: const BorderSide(
            color: AppColors.secondaryLight,
            width: 1.5,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Input Decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.cardBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.cardBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(
            color: AppColors.secondaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: AppColors.streakGlow),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(
            color: AppColors.streakGlow,
            width: 2,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.streakGlow,
        ),
        prefixIconColor: AppColors.textSecondaryDark,
        suffixIconColor: AppColors.textSecondaryDark,
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardDark,
        selectedColor: AppColors.secondaryLight.withValues(alpha: 0.16),
        side: const BorderSide(color: AppColors.cardBorderDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_bottomSheetRadius),
          ),
        ),
        dragHandleColor: AppColors.cardBorderDark,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),

      // ─── Floating Action Button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondaryLight,
        foregroundColor: AppColors.primaryDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),

      // ─── Navigation Bar (Bottom) ───
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.secondaryLight.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.secondaryLight,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textSecondaryDark,
            size: 24,
          );
        }),
        height: 72,
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorderDark,
        thickness: 1,
        space: 1,
      ),

      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.secondaryLight,
        unselectedLabelColor: AppColors.textSecondaryDark,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(
            color: AppColors.secondaryLight,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondaryLight,
        linearTrackColor: AppColors.cardBorderDark,
        circularTrackColor: AppColors.cardBorderDark,
      ),

      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return AppColors.textSecondaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryLight;
          }
          return AppColors.cardBorderDark;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // ─── Tooltip ───
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }
}
