import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/atlas_logo.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/basics.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/category_style.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/pressable.dart';

/// Empty: a large spark at 30% opacity, one line in 21 display, an optional
/// body line and one ink pill.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.sparkOpacity = .3,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double sparkOpacity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: sparkOpacity, child: const AtlasSpark(size: 64)),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTypography.section.copyWith(color: p.textPrimary)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: p.textMuted)),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: actionLabel!,
              onTap: onAction,
              height: 46,
            ),
          ],
        ],
      ),
    );
  }
}

/// Errors are an inline paper row with a coral icon and "Try again". Never
/// used for offline: local features always work.
class ErrorRow extends StatelessWidget {
  const ErrorRow({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
      ),
      child: Row(
        children: [
          const AtlasIcon(Symbols.error_rounded,
              filled: true, color: AppColors.coral, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTypography.sans(size: 14, weight: FontWeight.w600, color: p.textPrimary)),
          ),
          if (onRetry != null)
            Pressable(
              onTap: onRetry,
              haptic: PressHaptic.selection,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text('Try again',
                    style: AppTypography.chip.copyWith(color: p.textPrimary)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A skeleton block in the track color with a slow 1.4s shimmer.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = AppSpacing.rowHeight,
    this.width,
    this.radius = AppSpacing.radiusRow,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 - .5;
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 2, 0),
                end: Alignment(t * 2, 0),
                colors: [p.skeleton, p.skeletonHighlight, p.skeleton],
                stops: const [0, .5, 1],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A column of skeleton rows.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.height = AppSpacing.rowHeight});
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            Skeleton(height: height),
          ],
        ],
      );
}

/// Show a Daylight bottom sheet: canvas, 32 top radius, a 40×5 grabber, ink
/// scrim. Content gets the safe-area bottom inset.
Future<T?> showAtlasSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: builder(context),
      ),
    ),
  );
}

/// One option in an [showActionSheet] menu.
class SheetAction<T> {
  const SheetAction({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
    this.iconColor,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
  final Color? iconColor;
}

/// A context menu as a sheet: an optional title, then paper rows.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  String? subtitle,
  required List<SheetAction<T>> actions,
}) {
  return showAtlasSheet<T>(
    context,
    builder: (context) {
      final p = context.palette;
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.section.copyWith(color: p.textPrimary)),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Text(subtitle,
                      style: AppTypography.meta.copyWith(color: p.textMuted)),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (final a in actions) ...[
              Pressable(
                onTap: () => Navigator.of(context).pop(a.value),
                haptic: PressHaptic.selection,
                semanticLabel: a.label,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: p.paper,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                  child: Row(children: [
                    AtlasIcon(a.icon,
                        filled: true,
                        size: 22,
                        color: a.destructive
                            ? AppColors.coral
                            : (a.iconColor ?? p.textPrimary)),
                    const SizedBox(width: 14),
                    Text(a.label,
                        style: AppTypography.rowTitle.copyWith(
                            color: a.destructive ? AppColors.coral : p.textPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      );
    },
  );
}

/// A calm confirm dialog as a sheet. Returns true when confirmed.
///
/// With [onConfirm], confirming runs it while the sheet stays up with the
/// button spinning (and can't be dismissed), so slow work such as signing out
/// shows progress instead of a frozen screen.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  String cancelLabel = 'Not now',
  bool destructive = false,
  Future<void> Function()? onConfirm,
}) async {
  var working = false;
  final result = await showAtlasSheet<bool>(
    context,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      final p = context.palette;
      Future<void> confirm() async {
        if (onConfirm == null) return Navigator.of(context).pop(true);
        setState(() => working = true);
        try {
          await onConfirm();
        } finally {
          if (context.mounted) Navigator.of(context).pop(true);
        }
      }

      return PopScope(
        canPop: !working,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: AppTypography.body.copyWith(color: p.textBody)),
              ],
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: confirmLabel,
                height: 56,
                expand: true,
                haptic: PressHaptic.medium,
                busy: working,
                onTap: working ? null : confirm,
                textStyle: destructive
                    ? AppTypography.sans(size: 15, weight: FontWeight.w700, height: 1)
                    : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              PillButton(
                label: cancelLabel,
                height: 56,
                expand: true,
                variant: PillVariant.track,
                haptic: PressHaptic.selection,
                onTap: working ? null : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      );
    }),
  );
  return result ?? false;
}

/// A quiet, dismissible note (an update is ready, a nudge from Aurora):
/// a paper row with a spark or icon, one or two lines, an optional action.
class NoticeRow extends StatelessWidget {
  const NoticeRow({
    super.key,
    required this.title,
    this.body,
    this.icon,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.busy = false,
  });

  final String title;
  final String? body;

  /// Defaults to the Aurora spark.
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 34,
            child: Center(
              child: icon == null
                  ? const AtlasSpark(size: 26, animated: true)
                  : AtlasIcon(icon!, filled: true, size: 22, color: iconColor ?? p.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: AppTypography.sans(
                        size: 14, weight: FontWeight.w700, height: 1.35, color: p.textPrimary)),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(body!, style: AppTypography.meta.copyWith(color: p.textMuted)),
                ],
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: AppSpacing.xs),
            PillButton(label: actionLabel!, height: 36, onTap: onAction, busy: busy),
          ],
          if (onDismiss != null)
            Pressable(
              onTap: onDismiss,
              circle: true,
              haptic: PressHaptic.selection,
              semanticLabel: 'Dismiss',
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AtlasIcon(Symbols.close_rounded, size: 18, color: p.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
