import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_palette.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/pressable.dart';

// ─── Text helpers ──────────────────────────────────────────────────

/// Text painted with a gradient (the "%" glyph, the best-day name).
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = AppColors.sunriseText,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => gradient.createShader(bounds),
        child: Text(text,
            style: style.copyWith(color: AppColors.white), textAlign: textAlign),
      );
}

/// An integer that tweens to its new value over 600ms with tabular figures,
/// so the width never jitters. Set [animateFromZero] to count up on first
/// build (e.g. Insights' hero number).
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.animateFromZero = false,
    this.duration = AppMotion.slow,
    this.format,
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final bool animateFromZero;
  final Duration duration;
  final String Function(int value)? format;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  late double _from = widget.animateFromZero ? 0 : widget.value.toDouble();

  @override
  void didUpdateWidget(CountUpText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    final style = widget.style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    String fmt(int v) =>
        '${widget.prefix}${widget.format?.call(v) ?? '$v'}${widget.suffix}';
    if (reduce) return Text(fmt(widget.value), style: style);
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween(begin: _from, end: widget.value.toDouble()),
      duration: widget.duration,
      curve: AppMotion.standard,
      builder: (context, v, _) => Text(fmt(v.round()), style: style),
    );
  }
}

// ─── Bars ──────────────────────────────────────────────────────────

/// A 6px progress bar. Ink (palette `progressFill`) by default; pass
/// [gradient] for the sunrise fill. Width animates over 600ms. With [sheen],
/// a white glint sweeps across once when the bar reaches 100%.
class GradientBar extends StatelessWidget {
  const GradientBar({
    super.key,
    required this.value,
    this.height = 6,
    this.gradient,
    this.color,
    this.trackColor,
    this.sheen = false,
  });

  final double value;
  final double height;
  final Gradient? gradient;
  final Color? color;
  final Color? trackColor;
  final bool sheen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final reduce = AppMotion.reduceMotion(context);
    Widget fill(double f) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: f,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: gradient == null ? (color ?? p.progressFill) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        );

    return Semantics(
      value: '${(v * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor ?? p.track,
          borderRadius: BorderRadius.circular(height),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (reduce)
                fill(v)
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(end: v),
                  duration: AppMotion.slow,
                  curve: AppMotion.standard,
                  builder: (_, f, _) => fill(f),
                ),
              if (sheen && v >= 1 && !reduce) const _Sheen(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single white glint that sweeps across its parent once (700ms).
class _Sheen extends StatelessWidget {
  const _Sheen();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: -0.4, end: 1.4),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (_, t, _) => FractionallySizedBox(
          alignment: Alignment(t * 2 - 1, 0),
          widthFactor: .35,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0x00FFFFFF),
                Color(0x99FFFFFF),
                Color(0x00FFFFFF),
              ]),
            ),
          ),
        ),
      );
}

/// The hero's day bar: one segment per item (up to [maxSegments]), then a
/// continuous bar. Done segments show the sunrise gradient sampled across
/// the whole bar, so a full day runs amber → coral → violet.
class ProgressSegments extends StatelessWidget {
  const ProgressSegments({
    super.key,
    required this.total,
    required this.done,
    this.height = 8,
    this.gap = 6,
    this.maxSegments = 8,
    this.emptyColor,
  });

  final int total;
  final int done;
  final double height;
  final double gap;
  final int maxSegments;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final empty = emptyColor ?? AppColors.white.withValues(alpha: .15);
    final reduce = AppMotion.reduceMotion(context);
    return Semantics(
      label: '$done of $total done',
      child: SizedBox(
        height: height,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final shader = AppColors.sunriseBar.createShader(Rect.fromLTWH(0, 0, w, height));
          if (total <= 0) {
            return _Seg(color: empty, height: height);
          }
          if (total > maxSegments) {
            final f = (done / total).clamp(0.0, 1.0);
            return Stack(children: [
              _Seg(color: empty, height: height),
              _AnimatedFill(
                value: f,
                reduce: reduce,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (_) => shader,
                  child: _Seg(color: AppColors.white, height: height),
                ),
              ),
            ]);
          }
          final segW = (w - gap * (total - 1)) / total;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (_) => shader,
            // srcATop paints the gradient only over opaque white fills; empty
            // segments are drawn after, outside the mask.
            child: Stack(children: [
              for (var i = 0; i < total; i++)
                Positioned(
                  left: i * (segW + gap),
                  width: segW,
                  top: 0,
                  bottom: 0,
                  child: _AnimatedFill(
                    value: i < done ? 1 : 0,
                    reduce: reduce,
                    child: _Seg(color: AppColors.white, height: height),
                  ),
                ),
            ]),
          ).withEmptyBehind(
            total: total,
            segW: segW,
            gap: gap,
            height: height,
            color: empty,
          );
        }),
      ),
    );
  }
}

extension on Widget {
  Widget withEmptyBehind({
    required int total,
    required double segW,
    required double gap,
    required double height,
    required Color color,
  }) =>
      Stack(children: [
        for (var i = 0; i < total; i++)
          Positioned(
            left: i * (segW + gap),
            width: segW,
            top: 0,
            bottom: 0,
            child: _Seg(color: color, height: height),
          ),
        Positioned.fill(child: this),
      ]);
}

class _Seg extends StatelessWidget {
  const _Seg({required this.color, required this.height});
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height),
        ),
        child: const SizedBox.expand(),
      );
}

class _AnimatedFill extends StatelessWidget {
  const _AnimatedFill({
    required this.value,
    required this.child,
    required this.reduce,
  });
  final double value;
  final Widget child;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    if (reduce) {
      return value <= 0
          ? const SizedBox.shrink()
          : FractionallySizedBox(
              alignment: Alignment.centerLeft, widthFactor: value, child: child);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (_, v, child) => v <= 0.001
          ? const SizedBox.shrink()
          : ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: child,
              ),
            ),
      child: child,
    );
  }
}

// ─── Rings ─────────────────────────────────────────────────────────

/// A 34 ring whose sunrise sweep shows a day's completion, with the day
/// number in the middle. Sweeps from 0 to [value] on first appear.
class DayRing extends StatelessWidget {
  const DayRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 34,
    this.stroke = 3.5,
    this.delay = Duration.zero,
    this.labelColor,
  });

  final double value;
  final String label;
  final double size;
  final double stroke;
  final Duration delay;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value.clamp(0.0, 1.0);
    final reduce = AppMotion.reduceMotion(context);
    Widget ring(double t) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(value: t, track: p.track, stroke: stroke),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Text(label,
                  style: AppTypography.sans(
                    size: 12,
                    weight: FontWeight.w800,
                    height: 1,
                    tabular: true,
                    color: labelColor ?? p.textPrimary,
                  )),
            ),
          ),
        );
    if (reduce) return ring(v);
    return _Delayed(
      delay: delay,
      builder: (started) => TweenAnimationBuilder<double>(
        tween: Tween(end: started ? v : 0),
        duration: AppMotion.slow,
        curve: AppMotion.standard,
        builder: (_, t, _) => ring(t),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.stroke});
  final double value;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (value <= 0) return;
    final sweep = math.pi * 2 * value;
    final shader = SweepGradient(
      colors: const [AppColors.sunriseA, AppColors.sunriseB, AppColors.sunriseC],
      stops: [0, .6 * value, value],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(Offset.zero & size);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.stroke != stroke;
}

/// Runs [builder] with `false` until [delay] passes, then `true`.
class _Delayed extends StatefulWidget {
  const _Delayed({required this.delay, required this.builder});
  final Duration delay;
  final Widget Function(bool started) builder;

  @override
  State<_Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<_Delayed> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _started = true);
      });
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _started = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_started);
}

// ─── Sparkline ─────────────────────────────────────────────────────

/// Seven 4px bars for the last seven days, oldest first. Done days are drawn
/// in the category color at a gentle, deterministic height (14 to 22, seeded
/// by [seed] and the day) so they read as rhythm rather than data; missed
/// days are 4px stubs. Bars grow from the bottom on first appear.
class Sparkline7 extends StatelessWidget {
  const Sparkline7({
    super.key,
    required this.days,
    required this.color,
    required this.seed,
    this.dayKeys,
  }) : assert(days.length == 7);

  final List<bool> days;
  final Color color;
  final String seed;

  /// Optional per-day keys (e.g. ISO dates) so heights stay stable as the
  /// window slides. Defaults to the index.
  final List<String>? dayKeys;

  static const _maxH = 22.0;
  static const _minDone = 14.0;
  static const _empty = 4.0;

  static double heightFor(String seed, String day) {
    var h = 0;
    for (final c in '$seed|$day'.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _minDone + (h % 9);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = AppMotion.reduceMotion(context);
    final done = days.where((d) => d).length;
    return Semantics(
      label: 'Done $done of the last 7 days',
      child: SizedBox(
        height: _maxH,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _Bar(
                height: days[i] ? heightFor(seed, dayKeys?[i] ?? '$i') : _empty,
                color: days[i] ? color : p.sparkEmpty,
                delay: Duration(milliseconds: 30 * i),
                reduce: reduce,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.color,
    required this.delay,
    required this.reduce,
  });
  final double height;
  final Color color;
  final Duration delay;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    Widget bar(double h) => AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          width: 4,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    if (reduce) return bar(height);
    return _Delayed(
      delay: delay,
      builder: (started) => bar(started ? height : 4),
    );
  }
}

// ─── Check circle ──────────────────────────────────────────────────

/// The done check. Unchecked: a 2px outline. Checked: the border fades, the
/// sunrise fill scales in from 0.4 with easeOutBack and the check draws.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.done,
    this.onTap,
    this.size = 34,
    this.semanticLabel,
    this.enabled = true,
  });

  final bool done;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = AppMotion.reduceMotion(context);
    final circle = SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: done ? 1 : 0),
        duration: reduce ? AppMotion.instant : AppMotion.fast,
        curve: done ? AppMotion.emphasized : AppMotion.standard,
        builder: (context, t, _) {
          final tc = t.clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - tc,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.outline, width: 2),
                  ),
                ),
              ),
              if (t > 0)
                Transform.scale(
                  scale: reduce ? 1 : .4 + .6 * t,
                  child: Opacity(
                    opacity: tc,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.sunrise,
                      ),
                      child: CustomPaint(painter: _CheckPainter(progress: tc)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    return Pressable(
      onTap: enabled ? onTap : null,
      circle: true,
      haptic: done ? PressHaptic.selection : PressHaptic.light,
      semanticLabel: semanticLabel ?? (done ? 'Done' : 'Not done'),
      semanticHint: done ? 'Double tap to undo' : 'Double tap to tend',
      // Pad to a 44 tap target without changing the visual size.
      child: Padding(
        padding: EdgeInsets.all(math.max(0, (AppSpacing.iconButton - size) / 2)),
        child: circle,
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    if (w <= 0 || progress <= 0) return;
    final path = Path()
      ..moveTo(w * .29, w * .52)
      ..lineTo(w * .44, w * .66)
      ..lineTo(w * .72, w * .37);
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
