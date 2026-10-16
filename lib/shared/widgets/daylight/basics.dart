import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/category_style.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/pressable.dart';

// ─── Icon tile ─────────────────────────────────────────────────────

/// A rounded square in a category tint holding the filled category icon.
/// 42 on Home rows, 44 on Grow rows, 38 in suggestion cards, 34 in tiles.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.style,
    this.size = 42,
    this.radius,
    this.iconSize,
  });

  final CategoryStyle style;
  final double size;
  final double? radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final r = radius ??
        (size >= 48
            ? 16.0
            : size >= 44
                ? 15.0
                : size >= 42
                    ? AppSpacing.radiusIcon
                    : size >= 38
                        ? 12.0
                        : 11.0);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.tint(context),
        borderRadius: BorderRadius.circular(r),
      ),
      child: AtlasIcon(
        style.icon,
        filled: true,
        size: iconSize ?? (size * .53).roundToDouble(),
        color: style.fg(context),
      ),
    );
  }
}

/// A 48 tile filled with the sunrise gradient (Next place, paywall).
class GradientIconTile extends StatelessWidget {
  const GradientIconTile({super.key, required this.icon, this.size = 48});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.sunrise,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AtlasIcon(icon, filled: true, size: size / 2, color: AppColors.white),
      );
}

// ─── Buttons ───────────────────────────────────────────────────────

enum PillVariant {
  /// Ink in light, cream in dark. The primary action.
  action,

  /// Track color with primary text. Later, Remind me, secondary.
  track,

  /// The sunrise gradient with white text. Only for the recommended action.
  gradient,

  /// Paper with primary text (chips, week chip).
  paper,

  /// Translucent white over the letter gradient ("Read all").
  letter,

  /// Translucent white over a raised container.
  onRaised,
}

/// The one button shape in Atlas: a full-radius pill.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = PillVariant.action,
    this.icon,
    this.height = 40,
    this.horizontalPadding,
    this.expand = false,
    this.haptic = PressHaptic.light,
    this.busy = false,
    this.textStyle,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final PillVariant variant;
  final IconData? icon;
  final double height;
  final double? horizontalPadding;
  final bool expand;
  final PressHaptic haptic;
  final bool busy;
  final TextStyle? textStyle;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null && !busy;
    final (Color? bg, Gradient? gradient, Color fg) = switch (variant) {
      PillVariant.action => (p.action, null, p.onAction),
      PillVariant.track => (p.track, null, p.textPrimary),
      PillVariant.gradient => (null, AppColors.sunrise, AppColors.white),
      PillVariant.paper => (p.paper, null, p.textPrimary),
      PillVariant.letter => (p.letterSecondaryButton, null, p.textPrimary),
      PillVariant.onRaised => (
          p.onRaised.withValues(alpha: .12),
          null,
          p.onRaised
        ),
    };
    final style = (textStyle ??
            (height >= 52
                ? AppTypography.sans(size: 15, weight: FontWeight.w700, height: 1)
                : height <= 34
                    ? AppTypography.sans(size: 12, weight: FontWeight.w800, height: 1)
                    : height >= 46
                        ? AppTypography.button
                        : AppTypography.chip))
        .copyWith(color: fg);
    final pad = horizontalPadding ??
        (height >= 52
            ? AppSpacing.lg
            : height >= 46
                ? 18.0
                : height <= 34
                    ? 13.0
                    : 14.0);

    final content = busy
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                AtlasIcon(icon!, filled: true, size: height >= 46 ? 20 : 18, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label,
                    style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    final pill = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: onTap == null ? .45 : 1,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: pad),
        // Only center (and so fill the width) when asked to expand; a plain
        // pill hugs its label.
        alignment: expand ? Alignment.center : null,
        decoration: BoxDecoration(
          color: bg,
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: content,
      ),
    );

    return Pressable(
      onTap: enabled ? onTap : null,
      haptic: haptic,
      semanticLabel: semanticLabel ?? label,
      child: ExcludeSemantics(child: pill),
    );
  }
}

/// A round paper button with a single icon (search, tune, back, bell).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = AppSpacing.iconButton,
    this.iconSize = 22,
    this.badge = false,
    this.iconColor,
    this.filled = false,
    this.background,
  });

  /// The 42 back button used on pushed screens.
  const CircleIconButton.back({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Back',
  })  : icon = Symbols.arrow_back_rounded,
        size = AppSpacing.backButton,
        iconSize = 22,
        badge = false,
        iconColor = null,
        filled = false,
        background = null;

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final bool badge;
  final Color? iconColor;
  final bool filled;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      circle: true,
      haptic: PressHaptic.selection,
      semanticLabel: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background ?? p.paper,
                shape: BoxShape.circle,
              ),
              child: AtlasIcon(icon,
                  size: iconSize, color: iconColor ?? p.textPrimary, filled: filled),
            ),
            if (badge)
              Positioned(
                top: size * .23,
                right: size * .25,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AtlasPalette.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar ────────────────────────────────────────────────────────

/// The user's avatar: an ink circle with their initial inside a 2px sunrise
/// ring.
class AvatarRing extends StatelessWidget {
  const AvatarRing({
    super.key,
    required this.name,
    this.size = 44,
    this.onTap,
    this.ring = 2,
  });

  final String name;
  final double size;
  final double ring;
  final VoidCallback? onTap;

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? 'A' : t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final avatar = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: const BoxDecoration(
        gradient: AppColors.sunrise,
        shape: BoxShape.circle,
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.raised,
          shape: BoxShape.circle,
          border: p.raisedBorderSide,
        ),
        child: Text(
          _initial,
          style: AppTypography.sans(
            size: size * .32,
            weight: FontWeight.w800,
            height: 1,
            color: p.onRaised,
          ),
        ),
      ),
    );
    if (onTap == null) return avatar;
    return Pressable(
      onTap: onTap,
      circle: true,
      haptic: PressHaptic.selection,
      semanticLabel: 'Your profile',
      child: avatar,
    );
  }
}

// ─── Surfaces ──────────────────────────────────────────────────────

/// A flat paper tile (radius 26, padding 16). The default card.
class AtlasTile extends StatelessWidget {
  const AtlasTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusTile,
    this.color,
    this.gradient,
    this.border,
    this.onTap,
    this.semanticLabel,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double? height;

  /// The ink (raised) variant: hero, Next card, Best day.
  static AtlasTile raised(
    BuildContext context, {
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    double radius = AppSpacing.radiusTile,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    final p = context.palette;
    return AtlasTile(
      key: key,
      padding: padding,
      radius: radius,
      color: p.raised,
      border: p.raisedBorderSide,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? context.palette.paper) : null,
        gradient: gradient,
        border: border,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, semanticLabel: semanticLabel, child: box);
  }
}

// ─── Headers ───────────────────────────────────────────────────────

/// The top of a screen. Tab roots use a 40 title; pushed screens pass
/// [onBack] and get a 30 title beside the 42 back button.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onBack,
    this.titleKey,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pushed = onBack != null;
    final titleStyle =
        (pushed ? AppTypography.subScreenTitle : AppTypography.screenTitle)
            .copyWith(color: p.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
      child: Row(
        crossAxisAlignment:
            subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (pushed) ...[
            CircleIconButton.back(onTap: onBack),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, key: titleKey, style: titleStyle),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: AppTypography.subtitle.copyWith(color: p.textMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A 21 display section title with an optional muted action on the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(4, 4, 4, 0),
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title,
                  style: AppTypography.section.copyWith(color: p.textPrimary)),
            ),
          ),
          if (action != null)
            Pressable(
              onTap: onAction,
              haptic: PressHaptic.selection,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(action!,
                    style: AppTypography.chip.copyWith(color: p.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Chips ─────────────────────────────────────────────────────────

/// A small full-radius chip (streak, trend, status, week).
class AtlasChip extends StatelessWidget {
  const AtlasChip({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.background,
    this.foreground,
    this.onTap,
    this.dense = false,
  });

  /// The positive trend / synced chip (green). Never use red.
  factory AtlasChip.success(BuildContext context, String label,
          {IconData? icon}) =>
      AtlasChip(
        label: label,
        icon: icon,
        background: context.palette.successBg,
        foreground: context.palette.success,
      );

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? background;
  final Color? foreground;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = foreground ?? p.textPrimary;
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 6 : 7),
      decoration: BoxDecoration(
        color: background ?? p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AtlasIcon(icon!, size: 15, filled: true, color: iconColor ?? fg),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTypography.sans(
                size: 12,
                weight: FontWeight.w800,
                height: 1,
                color: fg,
                tabular: true,
              )),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Pressable(onTap: onTap, haptic: PressHaptic.selection, child: chip);
  }
}

/// A quick-reply / filter chip (paper, 13/700). Selected flips to action.
class ChoiceChipPill extends StatelessWidget {
  const ChoiceChipPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onAction : p.textPrimary;
    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.action : p.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AtlasIcon(icon!, size: 16, filled: true, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label, style: AppTypography.chip.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// A colored dot plus a label ("Health 380").
class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.metaStrong
                  .copyWith(color: context.palette.textPrimary)),
        ],
      );
}
