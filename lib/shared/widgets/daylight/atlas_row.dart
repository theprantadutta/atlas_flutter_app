import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/category_style.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/pressable.dart';

/// The row anatomy used everywhere: paper, radius 22, a leading icon tile,
/// a 15/700 title over a 12/600 meta line, and an optional trailing widget.
///
/// Swipe right past 30% of the width to [onSwipeRight] (tend: a sunrise
/// check grows behind the row); swipe left to [onSwipeLeft] (later / skip
/// today, on the track color). Heights are minimums, so rows grow with
/// large text instead of clipping.
class AtlasRow extends StatefulWidget {
  const AtlasRow({
    super.key,
    required this.leading,
    required this.title,
    this.meta,
    this.trailing,
    this.minHeight = AppSpacing.rowHeight,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 10, 10),
    this.gap = AppSpacing.sm,
    this.onTap,
    this.onLongPress,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.swipeLeftLabel = 'Later',
    this.semanticsValue,
    this.color,
    this.border,
    this.radius = AppSpacing.radiusRow,
    this.titleStyle,
    this.metaWidget,
    this.titleMaxLines = 2,
  });

  final Widget leading;
  final String title;
  final String? meta;
  final Widget? metaWidget;
  final Widget? trailing;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final double gap;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final String swipeLeftLabel;

  /// Spoken after title and meta, e.g. "done" / "not done".
  final String? semanticsValue;
  final Color? color;
  final BoxBorder? border;
  final double radius;
  final TextStyle? titleStyle;
  final int titleMaxLines;

  @override
  State<AtlasRow> createState() => _AtlasRowState();
}

class _AtlasRowState extends State<AtlasRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController.unbounded(vsync: this);
  double _width = 1;
  bool _passed = false;

  bool get _swipeable => widget.onSwipeRight != null || widget.onSwipeLeft != null;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    var next = _slide.value + d.delta.dx;
    if (widget.onSwipeRight == null && next > 0) next = 0;
    if (widget.onSwipeLeft == null && next < 0) next = 0;
    // Resist past the commit point so it feels like a detent.
    final limit = _width * .45;
    if (next.abs() > limit) next = next.sign * (limit + (next.abs() - limit) * .3);
    _slide.value = next;
    final passed = next.abs() > _width * .3;
    if (passed != _passed) {
      _passed = passed;
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _end(DragEndDetails d) async {
    final v = _slide.value;
    final committed = v.abs() > _width * .3 ||
        (v.abs() > _width * .15 && (d.primaryVelocity ?? 0).abs() > 900 &&
            (d.primaryVelocity!.sign == v.sign));
    _passed = false;
    if (!committed) {
      await _slide.animateTo(0, duration: AppMotion.fast, curve: AppMotion.emphasized);
      return;
    }
    if (v > 0) {
      HapticFeedback.lightImpact();
      await _slide.animateTo(0, duration: AppMotion.fast, curve: AppMotion.standard);
      widget.onSwipeRight?.call();
    } else {
      HapticFeedback.selectionClick();
      await _slide.animateTo(-_width, duration: AppMotion.fast, curve: AppMotion.standard);
      widget.onSwipeLeft?.call();
      if (mounted) _slide.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color ?? p.paper,
          borderRadius: BorderRadius.circular(widget.radius),
          border: widget.border,
        ),
        child: Row(
          children: [
            widget.leading,
            SizedBox(width: widget.gap),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: widget.titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: (widget.titleStyle ?? AppTypography.rowTitle)
                        .copyWith(color: p.textPrimary),
                  ),
                  if (widget.metaWidget != null) ...[
                    const SizedBox(height: 2),
                    widget.metaWidget!,
                  ] else if (widget.meta != null && widget.meta!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.meta!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.meta.copyWith(color: p.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              SizedBox(width: widget.gap - 4),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    final label = [
      widget.title,
      if (widget.meta != null && widget.meta!.isNotEmpty) widget.meta!,
      if (widget.semanticsValue != null) widget.semanticsValue!,
    ].join(', ');

    final tappable = Pressable(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      isButton: widget.onTap != null,
      semanticLabel: label,
      child: row,
    );

    final semantic = Semantics(
      customSemanticsActions: {
        if (widget.onSwipeRight != null)
          const CustomSemanticsAction(label: 'Tend'): widget.onSwipeRight!,
        if (widget.onSwipeLeft != null)
          CustomSemanticsAction(label: widget.swipeLeftLabel): widget.onSwipeLeft!,
      },
      child: tappable,
    );

    if (!_swipeable) return semantic;

    return LayoutBuilder(builder: (context, c) {
      _width = c.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: _update,
        onHorizontalDragEnd: _end,
        onHorizontalDragCancel: () => _slide.animateTo(0, duration: AppMotion.fast),
        child: AnimatedBuilder(
          animation: _slide,
          child: semantic,
          builder: (context, child) {
            final dx = _slide.value;
            final progress = (dx.abs() / (_width * .3)).clamp(0.0, 1.0);
            return Stack(
              children: [
                if (dx != 0)
                  Positioned.fill(
                    child: _SwipeBackground(
                      right: dx > 0,
                      progress: progress,
                      label: widget.swipeLeftLabel,
                      radius: widget.radius,
                    ),
                  ),
                Transform.translate(offset: Offset(dx, 0), child: child),
              ],
            );
          },
        ),
      );
    });
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.right,
    required this.progress,
    required this.label,
    required this.radius,
  });

  final bool right;
  final double progress;
  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: right ? Alignment.centerLeft : Alignment.centerRight,
      decoration: BoxDecoration(
        color: right ? p.paper.withValues(alpha: .5) : p.track,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: right
          ? Transform.scale(
              scale: .5 + .5 * progress,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.sunrise,
                ),
                child: const AtlasIcon(Symbols.check_rounded,
                    color: AppColors.white, size: 24, weight: 600),
              ),
            )
          : Opacity(
              opacity: progress,
              child: Text(label, style: AppTypography.chip.copyWith(color: p.textPrimary)),
            ),
    );
  }
}

/// A list row that opens something: icon, label, trailing arrow (Aurora
/// starters, settings).
class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.detail,
    this.trailing,
    this.height = 58,
    this.radius = AppSpacing.radiusButton,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final String? detail;
  final Widget? trailing;
  final double height;
  final double radius;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = destructive ? AppColors.coral : p.textPrimary;
    return Pressable(
      onTap: onTap,
      semanticLabel: detail == null ? label : '$label, $detail',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            children: [
              AtlasIcon(icon,
                  filled: true,
                  size: 22,
                  color: destructive
                      ? AppColors.coral
                      : (iconColor == null ? p.textPrimary : p.category(iconColor!))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label, style: AppTypography.rowTitle.copyWith(color: fg)),
              ),
              if (detail != null) ...[
                Text(detail!, style: AppTypography.meta.copyWith(color: p.textMuted)),
                const SizedBox(width: 6),
              ],
              trailing ??
                  AtlasIcon(Symbols.arrow_forward_rounded, size: 20, color: p.chevron),
            ],
          ),
        ),
      ),
    );
  }
}

/// A group of settings rows inside one paper card, separated by hairlines.
class RowGroup extends StatelessWidget {
  const RowGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.xs),
            child: Text(title!.toUpperCase(),
                style: AppTypography.kicker.copyWith(color: p.textMuted)),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Divider(height: 1, color: p.hairline),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row inside a [RowGroup]: icon, title, optional subtitle, trailing.
class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.destructive = false,
    this.showChevron,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool destructive;
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = destructive ? AppColors.coral : (iconColor ?? p.textPrimary);
    final chevron = showChevron ?? (onTap != null && trailing == null);
    return Pressable(
      onTap: onTap,
      scale: .98,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AtlasIcon(icon, filled: true, size: 22,
                  color: iconColor == null || destructive ? color : p.category(iconColor!)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: AppTypography.rowTitle.copyWith(
                            color: destructive ? AppColors.coral : p.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: AppTypography.meta.copyWith(color: p.textMuted)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (chevron)
                AtlasIcon(Symbols.chevron_right_rounded, size: 22, color: p.chevron),
            ],
          ),
        ),
      ),
    );
  }
}
