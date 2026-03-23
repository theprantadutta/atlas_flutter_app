import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// A reusable circular avatar display widget with optional XP ring and level badge.
class AvatarDisplay extends StatelessWidget {
  final Avatar? avatar;
  final double size;
  final bool showLevel;
  final bool showXpRing;
  final VoidCallback? onTap;

  const AvatarDisplay({
    super.key,
    this.avatar,
    this.size = 80,
    this.showLevel = true,
    this.showXpRing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = avatar?.name ?? 'A';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final level = avatar?.level ?? 1;
    final progress = avatar?.progressToNextLevel ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (showXpRing ? 12 : 0),
        height: size + (showXpRing ? 12 : 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // XP ring
            if (showXpRing)
              SizedBox(
                width: size + 12,
                height: size + 12,
                child: CustomPaint(
                  painter: _XpRingPainter(
                    progress: progress,
                    ringColor: AppColors.xpPrimary,
                    trackColor: AppColors.xpPrimary.withValues(alpha: 0.15),
                    strokeWidth: 3.5,
                  ),
                ),
              ),

            // Avatar circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // Level badge
            if (showLevel)
              Positioned(
                bottom: showXpRing ? 2 : 0,
                right: showXpRing ? 2 : 0,
                child: Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _XpRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  _XpRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_XpRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
