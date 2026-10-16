import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';

/// How the spark is filled.
enum SparkVariant {
  /// The sunrise gradient. Aurora, the logo, anything alive.
  gradient,

  /// Solid in the theme's primary text color (ink in light, cream in dark).
  ink,

  /// Solid white, for use on gradients and photos.
  white,
}

/// The Atlas mark: a four-point spark.
///
/// Used as the app logo and as Aurora's face. With [animated] it shimmers
/// (rotation ±12°, scale 1 → 1.08, a 5s mirror loop); with [busy] the loop
/// tightens to 1.2s and the opacity pulses, which is how Aurora shows she is
/// thinking. Both loops switch off under reduced motion.
class AtlasSpark extends StatefulWidget {
  const AtlasSpark({
    super.key,
    this.size = 40,
    this.variant = SparkVariant.gradient,
    this.animated = false,
    this.busy = false,
    this.semanticLabel,
  });

  final double size;
  final SparkVariant variant;
  final bool animated;
  final bool busy;
  final String? semanticLabel;

  @override
  State<AtlasSpark> createState() => _AtlasSparkState();
}

class _AtlasSparkState extends State<AtlasSpark>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool _shouldLoop(BuildContext context) =>
      (widget.animated || widget.busy) && !AppMotion.reduceMotion(context);

  Duration get _period =>
      widget.busy ? AppMotion.ambientSparkBusy : AppMotion.ambientSpark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AtlasSpark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy ||
        oldWidget.animated != widget.animated) {
      _sync();
    }
  }

  /// Start, retime or stop the loop without restarting it from zero, so a
  /// theme change or a busy flip never makes the spark jump.
  void _sync() {
    if (!_shouldLoop(context)) {
      _controller?.stop();
      return;
    }
    final c = _controller ??= AnimationController(vsync: this);
    // Half the period each way (mirror).
    final half = _period ~/ 2;
    if (c.duration != half || !c.isAnimating) {
      c.duration = half;
      c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final paint = SparkPainter(
      gradient: widget.variant == SparkVariant.gradient ? AppColors.spark : null,
      color: switch (widget.variant) {
        SparkVariant.gradient => null,
        SparkVariant.ink => p.textPrimary,
        SparkVariant.white => AppColors.white,
      },
    );
    Widget spark = CustomPaint(
      size: Size.square(widget.size),
      painter: paint,
    );

    final c = _controller;
    if (c != null && _shouldLoop(context)) {
      spark = AnimatedBuilder(
        animation: c,
        child: spark,
        builder: (context, child) {
          final t = AppMotion.gentle.transform(c.value);
          final opacity = widget.busy ? .7 + .3 * (1 - t) : 1.0;
          return Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: t * 12 * math.pi / 180,
              child: Transform.scale(scale: 1 + .08 * t, child: child),
            ),
          );
        },
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(child: spark),
      ),
    );
  }
}

/// Paints the spark: `(0,-1) (.22,-.22) (1,0) (.22,.22) (0,1) (-.22,.22)
/// (-1,0) (-.22,-.22)` in unit coordinates, scaled to fit the canvas.
class SparkPainter extends CustomPainter {
  const SparkPainter({this.gradient, this.color})
      : assert(gradient != null || color != null);

  final Gradient? gradient;
  final Color? color;

  static const _waist = .22;

  static Path pathFor(Rect rect) {
    final c = rect.center;
    final r = rect.shortestSide / 2;
    Offset at(double x, double y) => Offset(c.dx + x * r, c.dy + y * r);
    return Path()
      ..moveTo(at(0, -1).dx, at(0, -1).dy)
      ..lineTo(at(_waist, -_waist).dx, at(_waist, -_waist).dy)
      ..lineTo(at(1, 0).dx, at(1, 0).dy)
      ..lineTo(at(_waist, _waist).dx, at(_waist, _waist).dy)
      ..lineTo(at(0, 1).dx, at(0, 1).dy)
      ..lineTo(at(-_waist, _waist).dx, at(-_waist, _waist).dy)
      ..lineTo(at(-1, 0).dx, at(-1, 0).dy)
      ..lineTo(at(-_waist, -_waist).dx, at(-_waist, -_waist).dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..isAntiAlias = true;
    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color!;
    }
    canvas.drawPath(pathFor(rect), paint);
  }

  @override
  bool shouldRepaint(SparkPainter old) =>
      old.gradient != gradient || old.color != color;
}

/// The spark beside the "Atlas" wordmark in Funnel Display 700.
class AtlasLockup extends StatelessWidget {
  const AtlasLockup({super.key, this.height = 40, this.animated = false});

  /// Cap height of the lockup; the spark is drawn at this size.
  final double height;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Atlas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtlasSpark(size: height, animated: animated),
          SizedBox(width: height * .3),
          Text(
            'Atlas',
            style: AppTypography.display(
              size: height * 1.05,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The app icon as a widget: the gradient spark on an ink squircle. Used on
/// About and anywhere the "real" icon should appear in-app.
class AtlasAppIcon extends StatelessWidget {
  const AtlasAppIcon({super.key, this.size = 88, this.animated = false});

  final double size;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: AppColors.ink,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(size * .3),
        ),
      ),
      child: AtlasSpark(size: size * .56, animated: animated),
    );
  }
}
