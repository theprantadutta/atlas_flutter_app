import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';

/// Atlas's feedback toast: an ink pill that lands just above the nav bar.
///
/// ```dart
/// AtlasToast.success(context, 'Added to Grow');
/// AtlasToast.error(context, AppErrors.message(e));
/// AtlasToast.undo(context, 'Tended · +20 XP', onUndo: () => ...);
/// ```
///
/// It sits above the floating nav (which never moves), so it can't collide
/// with it, and on pushed screens it simply floats a little higher. One toast
/// is visible at a time; a new one replaces the old.
enum ToastVariant { success, error, warning, info }

class AtlasToast {
  AtlasToast._();

  static OverlayEntry? _entry;

  static void success(BuildContext context, String message) =>
      _show(context, ToastVariant.success, message);

  static void error(BuildContext context, String message) =>
      _show(context, ToastVariant.error, message);

  static void warning(BuildContext context, String message) =>
      _show(context, ToastVariant.warning, message);

  static void info(BuildContext context, String message) =>
      _show(context, ToastVariant.info, message);

  /// A success toast with an Undo action, open for [AppMotion.undoWindow].
  static void undo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    String actionLabel = 'Undo',
  }) =>
      _show(
        context,
        ToastVariant.success,
        message,
        actionLabel: actionLabel,
        onAction: onUndo,
        duration: AppMotion.undoWindow,
      );

  /// Remove whatever is on screen right now (e.g. before signing out).
  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  static void _show(
    BuildContext context,
    ToastVariant variant,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    if (message.trim().isEmpty) return;

    // The root overlay sits above sheets and dialogs, so a toast raised just
    // before a sheet closes still lands somewhere visible.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        variant: variant,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration ?? _durations[variant]!,
        onDismissed: () {
          if (identical(_entry, entry)) {
            entry.remove();
            _entry = null;
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

/// Errors linger longest; they usually ask something of the reader.
const _durations = <ToastVariant, Duration>{
  ToastVariant.success: Duration(seconds: 3),
  ToastVariant.error: Duration(seconds: 5),
  ToastVariant.warning: Duration(seconds: 4),
  ToastVariant.info: Duration(seconds: 3),
};

const _icons = <ToastVariant, IconData>{
  ToastVariant.success: Icons.check_rounded,
  ToastVariant.error: Icons.error_rounded,
  ToastVariant.warning: Icons.info_rounded,
  ToastVariant.info: Icons.auto_awesome_rounded,
};

const _iconColors = <ToastVariant, Color>{
  ToastVariant.success: AppColors.sunriseA,
  ToastVariant.error: AppColors.coral,
  ToastVariant.warning: AppColors.amber,
  ToastVariant.info: AppColors.sunriseA,
};

class _Toast extends StatefulWidget {
  const _Toast({
    required this.variant,
    required this.message,
    required this.duration,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final ToastVariant variant;
  final String message;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    reverseDuration: AppMotion.fast,
  );
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  void _act() {
    HapticFeedback.selectionClick();
    widget.onAction?.call();
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = AppMotion.reduceMotion(context);
    final media = MediaQuery.of(context);

    final pill = Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: widget.actionLabel == null ? AppSpacing.lg - 4 : 6,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: p.raised,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: p.raisedBorderSide,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[widget.variant],
              size: 18,
              color: _iconColors[widget.variant],
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.message,
                  style: AppTypography.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    height: 1.35,
                    color: p.onRaised,
                  ),
                ),
              ),
            ),
            if (widget.actionLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _act,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.onRaised.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: AppTypography.chip.copyWith(color: p.onRaised),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Positioned(
      left: AppSpacing.gutter,
      right: AppSpacing.gutter,
      bottom: media.viewInsets.bottom > 0
          ? media.viewInsets.bottom + AppSpacing.sm
          : media.padding.bottom +
              AppSpacing.navBottom +
              AppSpacing.navHeight +
              AppSpacing.sm,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: GestureDetector(
            onTap: widget.actionLabel == null ? _leave : null,
            // A flick downward gets rid of it.
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 0) _leave();
            },
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (reduce) {
                  return Opacity(opacity: _controller.value, child: child);
                }
                final v = _controller.value;
                final slide = _controller.status == AnimationStatus.reverse
                    ? Curves.easeInCubic.transform(v)
                    : AppMotion.emphasized.transform(v);
                return Opacity(
                  opacity: Curves.easeOut.transform(v),
                  child: Transform.translate(
                    offset: Offset(0, (1 - slide) * 24),
                    child: Transform.scale(
                      scale: .94 + .06 * slide,
                      child: child,
                    ),
                  ),
                );
              },
              child: pill,
            ),
          ),
        ),
      ),
    );
  }
}
