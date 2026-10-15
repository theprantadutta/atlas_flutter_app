import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atlas_flutter_app/shared/themes/app_motion.dart';

/// Which haptic a [Pressable] fires when it commits.
enum PressHaptic { none, selection, light, medium, heavy }

void fireHaptic(PressHaptic haptic) {
  switch (haptic) {
    case PressHaptic.none:
      break;
    case PressHaptic.selection:
      HapticFeedback.selectionClick();
    case PressHaptic.light:
      HapticFeedback.lightImpact();
    case PressHaptic.medium:
      HapticFeedback.mediumImpact();
    case PressHaptic.heavy:
      HapticFeedback.heavyImpact();
  }
}

/// Press feedback for every tappable in Atlas.
///
/// Scales down to 0.96 (or 0.92 for [circle] buttons) over 90ms on touch and
/// springs back with easeOutBack over 220ms. No ripples anywhere. Under
/// reduced motion the scale is skipped and only the haptic remains.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.circle = false,
    this.haptic = PressHaptic.none,
    this.longPressHaptic = PressHaptic.medium,
    this.semanticLabel,
    this.semanticHint,
    this.isButton = true,
    this.behavior = HitTestBehavior.opaque,
    this.scale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool circle;
  final PressHaptic haptic;
  final PressHaptic longPressHaptic;
  final String? semanticLabel;
  final String? semanticHint;
  final bool isButton;
  final HitTestBehavior behavior;

  /// Override the pressed scale.
  final double? scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.press,
    reverseDuration: AppMotion.fast,
  );

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  double get _pressedScale =>
      widget.scale ??
      (widget.circle ? AppMotion.pressScaleCircle : AppMotion.pressScaleRow);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (!_enabled || AppMotion.reduceMotion(context)) return;
    _c.forward();
  }

  void _up() {
    if (_c.value == 0 && !_c.isAnimating) return;
    // Let the press register visually even on a very quick tap.
    if (_c.isAnimating && _c.status == AnimationStatus.forward) {
      _c.forward().whenComplete(() {
        if (mounted) _c.reverse();
      });
    } else {
      _c.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final forward = _c.status == AnimationStatus.forward ||
            _c.status == AnimationStatus.completed;
        final t = forward
            ? Curves.easeOut.transform(_c.value)
            : AppMotion.emphasized.transform(_c.value).clamp(0.0, 1.2);
        final s = 1 - (1 - _pressedScale) * t;
        return Transform.scale(scale: s, child: child);
      },
    );

    return Semantics(
      button: widget.isButton && _enabled,
      enabled: _enabled,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _down,
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        onTap: widget.onTap == null
            ? null
            : () {
                fireHaptic(widget.haptic);
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _up();
                fireHaptic(widget.longPressHaptic);
                widget.onLongPress!();
              },
        child: child,
      ),
    );
  }
}
