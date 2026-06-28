import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// The Atlas logo — a tiny "living world" inside a soft squircle: a twilight
/// sky, an aurora glow, a rising orb, and a layered horizon. The mark *is* the
/// product's metaphor, so it scales from a 24px app-bar glyph to a splash hero.
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
          colors: [Color(0xFF141A33), Color(0xFF24305C), Color(0xFF35617E)],
        ).createShader(rect),
    );

    // Aurora glow band.
    final auroraRect = Rect.fromLTWH(0, h * 0.12, w, h * 0.42);
    canvas.drawRect(
      auroraRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x005EEAD4),
            Color(0x665EEAD4),
            Color(0x668B9CF7),
            Color(0x33F5A9C0),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ).createShader(auroraRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );

    // Rising orb (with soft glow).
    final orbCenter = Offset(w * 0.66, h * 0.40);
    final orbR = w * 0.13;
    canvas.drawCircle(
      orbCenter,
      orbR * 1.9,
      Paint()
        ..color = AppColors.tertiaryLight.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
    canvas.drawCircle(
      orbCenter,
      orbR,
      Paint()..color = const Color(0xFFFBE3B0),
    );

    // Layered horizon hills.
    void hill(double baseY, double amp, Color color) {
      final path = Path()..moveTo(0, h);
      path.lineTo(0, baseY);
      path.cubicTo(
        w * 0.28, baseY - amp,
        w * 0.52, baseY + amp * 0.6,
        w * 0.74, baseY - amp * 0.5,
      );
      path.cubicTo(
        w * 0.88, baseY - amp * 0.9,
        w * 0.96, baseY - amp * 0.2,
        w, baseY - amp * 0.4,
      );
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    hill(h * 0.66, h * 0.08, const Color(0xFF2C4A6E));
    hill(h * 0.78, h * 0.07, const Color(0xFF1F6E66));
    hill(h * 0.90, h * 0.05, const Color(0xFF15463F));

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
