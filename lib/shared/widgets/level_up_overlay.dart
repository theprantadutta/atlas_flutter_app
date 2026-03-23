import 'dart:math';

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Full-screen overlay for level-up celebration.
/// Shows "LEVEL UP!" with scale animation (overshoot), the new level number
/// with a golden glow, simple particle effects, and auto-dismisses after 3s.
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _particleController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Particle effect
    final rng = Random();
    _particles = List.generate(10, (i) {
      final angle = (2 * pi / 10) * i;
      return _Particle(angle: angle, speed: 80 + rng.nextDouble() * 60);
    });

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _mainController.forward();
    _particleController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _mainController.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _particleController]),
      builder: (context, child) {
        return IgnorePointer(
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.tertiary.withValues(alpha: 0.7),
                    AppColors.tertiaryDark.withValues(alpha: 0.85),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Particles
                  ..._particles.map((p) {
                    final progress = _particleController.value;
                    final dx = cos(p.angle) * p.speed * progress;
                    final dy = sin(p.angle) * p.speed * progress;
                    final opacity = (1.0 - progress).clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Main text
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.none,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.white,
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.tertiary.withValues(alpha: 0.6),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'Level ${widget.newLevel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(
                                  color: AppColors.tertiary,
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;

  _Particle({required this.angle, required this.speed});
}
