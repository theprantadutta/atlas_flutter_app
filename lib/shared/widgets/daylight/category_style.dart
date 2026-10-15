import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';

/// The look of one tracked thing: a filled Material Symbol and a category
/// color. The icon prefers what the title says ("Read 20 pages" gets a book)
/// and falls back to the category, so rows feel specific rather than generic.
@immutable
class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;

  /// Light-theme category foreground. Read it through [fg] so pine is lifted
  /// in dark.
  final Color color;

  Color fg(BuildContext context) => context.palette.category(color);
  Color tint(BuildContext context) => context.palette.tint(color);

  /// Style for a category id (task, habit or goal category).
  static CategoryStyle forCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'health':
        return const CategoryStyle(Symbols.favorite_rounded, AppColors.coral);
      case 'fitness':
        return const CategoryStyle(
            Symbols.directions_run_rounded, AppColors.coral);
      case 'mindfulness':
        return const CategoryStyle(
            Symbols.self_improvement_rounded, AppColors.violet);
      case 'learning':
        return const CategoryStyle(Symbols.menu_book_rounded, AppColors.sky);
      case 'creative':
        return const CategoryStyle(Symbols.palette_rounded, AppColors.amber);
      case 'social':
      case 'relationships':
        return const CategoryStyle(Symbols.groups_rounded, AppColors.rose);
      case 'finance':
      case 'financial':
        return const CategoryStyle(Symbols.savings_rounded, AppColors.pine);
      case 'work':
      case 'career':
        return const CategoryStyle(Symbols.work_rounded, AppColors.sky);
      case 'productivity':
        return const CategoryStyle(Symbols.bolt_rounded, AppColors.amber);
      case 'personal':
        return const CategoryStyle(Symbols.spa_rounded, AppColors.leaf);
      default:
        return const CategoryStyle(Symbols.eco_rounded, AppColors.leaf);
    }
  }

  /// Style for an item, inferring the icon from its title first.
  static CategoryStyle forItem({required String title, String? category}) {
    final base = forCategory(category);
    final icon = _iconFromTitle(title.toLowerCase());
    if (icon == null) return base;
    return CategoryStyle(icon, _iconColors[icon] ?? base.color);
  }

  /// Human label for a category id ("mindfulness" → "Mind").
  static String label(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'mindfulness':
        return 'Mind';
      case 'financial':
      case 'finance':
        return 'Money';
      case 'relationships':
        return 'People';
      case 'custom':
      case '':
        return 'Other';
      default:
        final c = category!;
        return c[0].toUpperCase() + c.substring(1).toLowerCase();
    }
  }

  /// Some icons have a natural color regardless of category (water is
  /// blue, sleep is violet), which keeps a list of rows from going monotone.
  static final Map<IconData, Color> _iconColors = {
    Symbols.water_drop_rounded: AppColors.sky,
    Symbols.bedtime_rounded: AppColors.violet,
    Symbols.self_improvement_rounded: AppColors.violet,
    Symbols.menu_book_rounded: AppColors.violet,
    Symbols.hotel_rounded: AppColors.amber,
    Symbols.accessibility_new_rounded: AppColors.leaf,
    Symbols.directions_walk_rounded: AppColors.leaf,
    Symbols.directions_run_rounded: AppColors.coral,
    Symbols.fitness_center_rounded: AppColors.coral,
    Symbols.edit_note_rounded: AppColors.coral,
    Symbols.calendar_month_rounded: AppColors.violet,
    Symbols.coffee_rounded: AppColors.amber,
    Symbols.restaurant_rounded: AppColors.amber,
    Symbols.savings_rounded: AppColors.pine,
    Symbols.mail_rounded: AppColors.sky,
    Symbols.code_rounded: AppColors.sky,
  };

  static IconData? _iconFromTitle(String t) {
    bool has(List<String> words) => words.any(t.contains);
    if (has(['water', 'hydrat', 'drink'])) return Symbols.water_drop_rounded;
    if (has(['read', 'book', 'pages', 'study'])) return Symbols.menu_book_rounded;
    if (has(['meditat', 'breath', 'calm', 'mindful'])) {
      return Symbols.self_improvement_rounded;
    }
    if (has(['wind down', 'sleep', 'bed', 'night'])) return Symbols.bedtime_rounded;
    if (has(['rest', 'nap'])) return Symbols.hotel_rounded;
    if (has(['stretch', 'yoga', 'mobility'])) {
      return Symbols.accessibility_new_rounded;
    }
    if (has(['walk', 'steps', 'outside'])) return Symbols.directions_walk_rounded;
    if (has(['run', 'jog', 'move', 'cardio'])) return Symbols.directions_run_rounded;
    if (has(['gym', 'lift', 'workout', 'push-up', 'pushup', 'squat'])) {
      return Symbols.fitness_center_rounded;
    }
    if (has(['bike', 'cycl'])) return Symbols.directions_bike_rounded;
    if (has(['swim'])) return Symbols.pool_rounded;
    if (has(['journal', 'write', 'diary', 'note'])) return Symbols.edit_note_rounded;
    if (has(['plan', 'schedule', 'week', 'calendar'])) {
      return Symbols.calendar_month_rounded;
    }
    if (has(['call', 'phone'])) return Symbols.call_rounded;
    if (has(['friend', 'family', 'mom', 'dad', 'partner'])) {
      return Symbols.favorite_rounded;
    }
    if (has(['reply', 'email', 'inbox', 'message'])) return Symbols.mail_rounded;
    if (has(['code', 'program', 'build'])) return Symbols.code_rounded;
    if (has(['cook', 'meal', 'eat', 'breakfast', 'lunch', 'dinner', 'veg'])) {
      return Symbols.restaurant_rounded;
    }
    if (has(['coffee', 'tea'])) return Symbols.coffee_rounded;
    if (has(['clean', 'tidy', 'laundry'])) return Symbols.cleaning_services_rounded;
    if (has(['budget', 'save', 'money', 'pay', 'bill'])) return Symbols.savings_rounded;
    if (has(['music', 'guitar', 'piano', 'practice'])) return Symbols.music_note_rounded;
    if (has(['draw', 'paint', 'sketch'])) return Symbols.brush_rounded;
    if (has(['language', 'spanish', 'french', 'learn'])) return Symbols.translate_rounded;
    if (has(['vitamin', 'pill', 'medic'])) return Symbols.medication_rounded;
    if (has(['screen', 'phone-free', 'detox'])) return Symbols.phonelink_off_rounded;
    if (has(['gratitude', 'grateful', 'thank'])) return Symbols.volunteer_activism_rounded;
    return null;
  }
}

/// A Material Symbols Rounded icon, filled or outlined.
class AtlasIcon extends StatelessWidget {
  const AtlasIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.filled = false,
    this.weight = 400,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final bool filled;
  final double weight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Icon(
        icon,
        size: size,
        color: color ?? context.palette.textPrimary,
        fill: filled ? 1 : 0,
        weight: weight,
        opticalSize: size.clamp(20, 48),
        grade: 0,
        semanticLabel: semanticLabel,
      );
}
