import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// The Atlas logo — the "Aurora A" mark: a bold aurora-gradient peak that reads
/// as the letter A (Atlas) and a mountain (the living world), a thin horizon gap
/// as the crossbar, and a warm gold sun rising behind it on a twilight sky. The
/// mark *is* the product's metaphor, so it scales from a 24px glyph to a splash
/// hero and matches the app launcher icon.
///
/// Use [AtlasLogo] for the symbol, or [AtlasLogo.wordmark] for symbol + name.
class AtlasLogo extends StatelessWidget {
  const AtlasLogo({super.key, this.size = 48, this.glow = false})
      : _wordmark = false;

  const AtlasLogo.wordmark({super.key, this.size = 40, this.glow = false})
      : _wordmark = true;

  /// Edge length of the square mark.
  final double size;

  /// Adds a soft aurora glow behind the mark (nice on dark heroes).
  final bool glow;

  final bool _wordmark;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AtlasMarkPainter()),
    );

    final glowing = glow
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.auroraLilac.withValues(alpha: 0.35),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.04,
                ),
              ],
            ),
            child: mark,
          )
        : mark;

    if (!_wordmark) return glowing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        glowing,
        SizedBox(width: size * 0.32),
        Text(
          'Atlas',
          style: GoogleFonts.fraunces(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AtlasMarkPainter extends CustomPainter {
  // Brand palette (kept exact so the glyph matches the launcher icon).
  static const _skyTop = Color(0xFF10162B);
  static const _skyMid = Color(0xFF1C2748);
  static const _skyBottom = Color(0xFF2A3A66);
  static const _horizon = Color(0xFF17203F);
  static const _auroraTeal = Color(0xFF5EEAD4);
  static const _auroraLilac = Color(0xFF8B9CF7);
  static const _auroraRose = Color(0xFFF5A9C0);
  static const _gold = Color(0xFFF4C77B);
  static const _goldCore = Color(0xFFFFF4CE);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final squircle = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.3));

    canvas.save();
    canvas.clipRRect(squircle);

    // Twilight sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyMid, _skyBottom],
        ).createShader(rect),
    );

    // Faint aurora glow high in the sky.
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.30),
      w * 0.34,
      Paint()
        ..color = _auroraLilac.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.10),
    );

    // A couple of quiet stars.
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(w * 0.26, h * 0.24), w * 0.012, starPaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.15), w * 0.008, starPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.16), w * 0.009, starPaint);

    // Gold sun rising behind the upper-right slope (drawn before the peak).
    final sunCenter = Offset(w * 0.66, h * 0.33);
    final sunR = w * 0.105;
    canvas.drawCircle(
      sunCenter,
      sunR * 1.7,
      Paint()
        ..color = _gold.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
    canvas.drawCircle(sunCenter, sunR, Paint()..color = _gold);
    canvas.drawCircle(
        sunCenter, sunR * 0.6, Paint()..color = _goldCore.withValues(alpha: 0.95));

    // The peak — a rounded triangle filled with the aurora gradient.
    final apex = Offset(w * 0.5, h * 0.19);
    final baseL = Offset(w * 0.15, h * 0.85);
    final baseR = Offset(w * 0.85, h * 0.85);
    final peak = _roundedTriangle([apex, baseR, baseL], w * 0.055);
    final peakRect = Rect.fromLTRB(w * 0.15, h * 0.19, w * 0.85, h * 0.85);
    canvas.drawPath(
      peak,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [_auroraTeal, _auroraLilac, _auroraRose],
        ).createShader(peakRect),
    );

    // Horizon crossbar — a thin twilight gap across the lower third (the "A" bar).
    canvas.save();
    canvas.clipPath(peak);
    final barY = h * 0.635;
    final barH = h * 0.055;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.10, barY - barH / 2, w * 0.90, barY + barH / 2),
        Radius.circular(barH / 2),
      ),
      Paint()..color = _horizon,
    );
    canvas.restore();

    canvas.restore();

    // Inner hairline for crispness.
    canvas.drawRRect(
      squircle.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  /// A closed triangle path with rounded corners (radius [r]).
  Path _roundedTriangle(List<Offset> pts, double r) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final curr = pts[i];
      final prev = pts[(i - 1 + n) % n];
      final next = pts[(i + 1) % n];

      final toPrev = prev - curr;
      final toNext = next - curr;
      final lenPrev = toPrev.distance;
      final lenNext = toNext.distance;
      final rr = math.min(r, math.min(lenPrev, lenNext) / 2);

      final p1 = curr + toPrev / lenPrev * rr;
      final p2 = curr + toNext / lenNext * rr;

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter oldDelegate) => false;
}

/// A rounded app-icon-style container around the mark — handy for splash and
/// empty states where the mark needs a little breathing room.
class AtlasLogoBadge extends StatelessWidget {
  const AtlasLogoBadge({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: AtlasLogo(size: size * 0.72, glow: true),
    );
  }
}
