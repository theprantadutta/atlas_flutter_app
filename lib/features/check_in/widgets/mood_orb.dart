import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// A mood drawn as a small sun on a horizon: heavy sits low, mostly below
/// the line; bright has fully risen with a soft halo. Words, not scores:
/// the colours are calm and none of them reads as a failure.
class MoodOrb extends StatelessWidget {
  const MoodOrb({
    super.key,
    required this.mood,
    this.size = 44,
    this.horizon,
    this.animate = true,
  });

  /// 1 (heavy) to 5 (bright).
  final int mood;
  final double size;

  /// The horizon line colour; defaults to the palette hairline.
  final Color? horizon;

  /// Rise into place on first build (skipped under reduced motion).
  final bool animate;

  /// How far the sun has risen, in sun radii above the horizon.
  static double riseFor(int mood) => switch (mood) {
        <= 1 => -.15,
        2 => .35,
        3 => .8,
        4 => 1.3,
        _ => 1.8,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.mood(mood);
    final line = horizon ?? p.outline;
    final target = riseFor(mood);
    Widget paint(double rise) => CustomPaint(
          size: Size.square(size),
          painter: _OrbPainter(
            color: color,
            horizon: line,
            rise: rise,
            halo: mood >= CheckInMood.bright,
          ),
        );
    final reduce = AppMotion.reduceMotion(context);
    return Semantics(
      label: CheckInMood.labels[mood],
      child: !animate || reduce
          ? paint(target)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: target - .6, end: target),
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              builder: (_, r, _) => paint(r),
            ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.color,
    required this.horizon,
    required this.rise,
    required this.halo,
  });

  final Color color;
  final Color horizon;
  final double rise;
  final bool halo;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final horizonY = size.height * .72;
    final r = w * .2;
    final center = Offset(w / 2, horizonY - rise * r);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, w, horizonY));
    if (halo) {
      canvas.drawCircle(
          center, r * 1.65, Paint()..color = color.withValues(alpha: .28));
    }
    canvas.drawCircle(center, r, Paint()..color = color);
    canvas.restore();

    final stroke = (w * .045).clamp(1.5, 3.0);
    canvas.drawLine(
      Offset(w * .14, horizonY),
      Offset(w * .86, horizonY),
      Paint()
        ..color = horizon
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.color != color ||
      old.horizon != horizon ||
      old.rise != rise ||
      old.halo != halo;
}
