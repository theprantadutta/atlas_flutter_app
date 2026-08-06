import 'dart:async';

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// Atlas's feedback toast.
///
/// Anchored to the **top** of the screen on purpose: the bottom belongs to the
/// floating nav bar and the quick-add button, and a default Material snack bar
/// collides with both.
///
/// ```dart
/// AtlasToast.success(context, 'Habit added');
/// AtlasToast.error(context, AppErrors.message(e));
/// AtlasToast.warning(context, 'Notifications are off for Atlas.');
/// AtlasToast.info(context, 'Coming soon');
/// ```
///
/// One toast is visible at a time — a new one replaces the old rather than
/// stacking, which keeps a burst of feedback calm instead of overwhelming.
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

  /// Remove whatever is on screen right now (e.g. before signing out).
  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  static void _show(
    BuildContext context,
    ToastVariant variant,
    String message,
  ) {
    if (message.trim().isEmpty) return;

    // The root overlay sits above sheets and dialogs, so a toast raised just
    // before a sheet closes still lands somewhere visible.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastCard(
        variant: variant,
        message: message,
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

class _ToastStyle {
  const _ToastStyle(this.color, this.icon, this.duration);
  final Color color;
  final IconData icon;
  final Duration duration;
}

/// Errors linger longest — they usually ask something of the reader.
const _styles = <ToastVariant, _ToastStyle>{
  ToastVariant.success: _ToastStyle(
      AppColors.xpPrimary, Icons.check_circle_rounded, Duration(seconds: 3)),
  ToastVariant.error: _ToastStyle(
      AppColors.error, Icons.error_outline_rounded, Duration(seconds: 5)),
  ToastVariant.warning: _ToastStyle(AppColors.streakFlame,
      Icons.warning_amber_rounded, Duration(seconds: 4)),
  ToastVariant.info: _ToastStyle(
      AppColors.auroraLilac, Icons.info_outline_rounded, Duration(seconds: 3)),
};

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.variant,
    required this.message,
    required this.onDismissed,
  });

  final ToastVariant variant;
  final String message;
  final VoidCallback onDismissed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    reverseDuration: AppMotion.fast,
  );
  Timer? _timer;
  bool _leaving = false;

  _ToastStyle get _style => _styles[widget.variant]!;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(_style.duration, _leave);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = AppMotion.reduceMotion(context);
    final color = _style.color;

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.12),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.40 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(_style.icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.xs,
      left: AppSpacing.gutter,
      right: AppSpacing.gutter,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _leave,
          // A flick upward gets rid of it, the way a notification would.
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < 0) _leave();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_controller.value);
              if (reduce) {
                return Opacity(opacity: _controller.value, child: child);
              }
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * -24),
                  child: child,
                ),
              );
            },
            child: card,
          ),
        ),
      ),
    );
  }
}
