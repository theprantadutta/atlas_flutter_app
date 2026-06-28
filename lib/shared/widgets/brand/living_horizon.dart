import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// The signature of Atlas: a living world horizon.
///
/// A time-of-day sky (dawn → day → dusk → night) with drifting aurora curtains,
/// a sun or moon tracing an arc, and layered hills that grow lusher as
/// [progress] climbs. Ambient drift is disabled when the user prefers reduced
/// motion. This is the emotional centre of the home screen.
class LivingHorizon extends StatefulWidget {
  const LivingHorizon({
    super.key,
    this.progress = 0.5,
    this.height = 240,
    this.hourOverride,
    this.borderRadius,
    this.brightness,
  });

  /// 0..1 — how much of your world has flourished. Drives the greenery.
  final double progress;
  final double height;

  /// Override the hour (0..23) for previews; defaults to the device clock.
  final int? hourOverride;
  final BorderRadius? borderRadius;

  /// Force a palette. Defaults to the ambient theme brightness, so the world
  /// is airy in light mode and twilight in dark mode. Splash/auth headers pass
  /// [Brightness.dark] to stay immersive behind white text.
  final Brightness? brightness;

  @override
  State<LivingHorizon> createState() => _LivingHorizonState();
}

class _LivingHorizonState extends State<LivingHorizon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: AppMotion.ambient,
  );

  @override
  void initState() {
    super.initState();
    // Start ambient drift after first frame so we can honor reduced-motion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !AppMotion.reduceMotion(context)) _drift.repeat();
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = widget.hourOverride ?? DateTime.now().hour;
    final brightness = widget.brightness ?? Theme.of(context).brightness;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => CustomPaint(
            painter: _HorizonPainter(
              progress: widget.progress.clamp(0, 1),
              hour: hour,
              phase: _drift.value,
              brightness: brightness,
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizonPainter extends CustomPainter {
  _HorizonPainter({
    required this.progress,
    required this.hour,
    required this.phase,
    required this.brightness,
  });

  final double progress;
  final int hour;
  final double phase;
  final Brightness brightness;

  bool get _dark => brightness == Brightness.dark;
  bool get _isNight => hour < 5 || hour >= 20;
  bool get _isDusk => hour >= 17 && hour < 20;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final horizonY = h * 0.62;

    // ── Sky ──
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _dark
              ? AppColors.skyForHour(hour)
              : AppColors.skyForHourLight(hour),
        ).createShader(rect),
    );

    // ── Stars (dark mode dusk & night only) ──
    if (_dark && (_isNight || _isDusk)) {
      final starPaint = Paint()..color = Colors.white;
      for (var i = 0; i < 28; i++) {
        // Deterministic pseudo-scatter.
        final sx = ((math.sin(i * 12.9898) * 43758.5453) % 1).abs();
        final sy = ((math.sin(i * 78.233) * 12543.123) % 1).abs();
        final x = sx * w;
        final y = sy * horizonY * 0.9;
        final twinkle =
            0.4 + 0.6 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi + i));
        starPaint.color = Colors.white
            .withValues(alpha: (_isNight ? 0.7 : 0.4) * twinkle);
        canvas.drawCircle(Offset(x, y), i.isEven ? 1.1 : 0.7, starPaint);
      }
    }

    // ── Aurora curtains ── (softer over a bright daytime sky)
    var auroraStrength = _isNight ? 0.55 : (_isDusk ? 0.7 : 0.22);
    if (!_dark) auroraStrength *= 0.5;
    _auroraCurtain(canvas, w, horizonY * 0.55, h * 0.10, 1.6,
        phase * 2 * math.pi, auroraStrength);
    _auroraCurtain(canvas, w, horizonY * 0.38, h * 0.07, 2.3,
        phase * 2 * math.pi + 2, auroraStrength * 0.8);

    // ── Sun / Moon orb ──
    _orb(canvas, w, horizonY);

    // ── Layered hills (lusher with progress) ──
    final barren = _dark ? const Color(0xFF2A3350) : const Color(0xFF93B6AE);
    final lush = _dark ? const Color(0xFF1F7A5E) : const Color(0xFF4FA67E);
    final back = Color.lerp(barren, lush, progress * 0.5)!;
    final mid = Color.lerp(barren, lush, progress * 0.75)!;
    final front = Color.lerp(barren, lush, progress)!;

    _hill(canvas, w, h, horizonY + 6, h * 0.05, 1.4, 0.6, back);
    _hill(canvas, w, h, horizonY + h * 0.10, h * 0.045, 2.0, 2.1, mid);
    _hill(canvas, w, h, horizonY + h * 0.20, h * 0.035, 2.6, 4.0, front);

    // Trees appear on the front hill as the world flourishes.
    _trees(canvas, w, h, horizonY + h * 0.20, h * 0.035, 2.6, 4.0, progress);
  }

  void _auroraCurtain(Canvas canvas, double w, double centerY, double amp,
      double freq, double ph, double strength) {
    if (strength <= 0) return;
    final path = Path();
    const n = 48;
    for (var i = 0; i <= n; i++) {
      final x = w * i / n;
      final y = centerY + math.sin(x / w * math.pi * freq + ph) * amp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = amp * 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, amp * 0.9)
        ..shader = LinearGradient(
          colors: [
            AppColors.auroraTeal.withValues(alpha: 0.0),
            AppColors.auroraTeal.withValues(alpha: strength),
            AppColors.auroraLilac.withValues(alpha: strength),
            AppColors.auroraRose.withValues(alpha: strength * 0.6),
            AppColors.auroraRose.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.25, 0.55, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(0, centerY - amp, w, amp * 3)),
    );
  }

  void _orb(Canvas canvas, double w, double horizonY) {
    final bool isSun = hour >= 6 && hour < 18;
    final double t = isSun
        ? (hour - 6) / 12
        : (((hour < 6 ? hour + 24 : hour) - 18) / 12);
    final x = (0.16 + 0.68 * t) * w;
    final y = horizonY * 0.92 - math.sin(t * math.pi) * (horizonY * 0.55);
    final center = Offset(x, y);
    final r = w * 0.045;

    final color = isSun ? const Color(0xFFFBE3B0) : const Color(0xFFE9EEFF);
    final glow = isSun ? AppColors.tertiaryLight : AppColors.auroraLilac;

    canvas.drawCircle(
      center,
      r * 3.0,
      Paint()
        ..color = glow.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.6),
    );
    canvas.drawCircle(center, r, Paint()..color = color);
  }

  void _hill(Canvas canvas, double w, double h, double baseY, double amp,
      double freq, double ph, Color color) {
    final path = Path()..moveTo(0, h);
    const n = 40;
    for (var i = 0; i <= n; i++) {
      final x = w * i / n;
      final y = baseY + math.sin(x / w * math.pi * freq + ph) * amp;
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _trees(Canvas canvas, double w, double h, double baseY, double amp,
      double freq, double ph, double progress) {
    final count = (progress * 9).round();
    if (count == 0) return;
    final paint = Paint()..color = const Color(0xFF123D32);
    for (var i = 0; i < count; i++) {
      final frac = (i + 0.5) / 9;
      final x = frac * w;
      final y = baseY + math.sin(x / w * math.pi * freq + ph) * amp;
      final treeH = h * 0.045;
      final path = Path()
        ..moveTo(x, y - treeH)
        ..lineTo(x - treeH * 0.4, y)
        ..lineTo(x + treeH * 0.4, y)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonPainter old) =>
      old.phase != phase ||
      old.progress != progress ||
      old.hour != hour ||
      old.brightness != brightness;
}
