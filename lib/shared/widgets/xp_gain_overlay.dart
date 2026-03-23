import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Full-screen overlay that shows "+X XP" text with a scale-in animation.
/// Optionally shows a streak bonus. Auto-dismisses after 2 seconds.
class XpGainOverlay extends StatefulWidget {
  final int xp;
  final int? streakBonus;
  final VoidCallback onDismiss;

  const XpGainOverlay({
    super.key,
    required this.xp,
    this.streakBonus,
    required this.onDismiss,
  });

  @override
  State<XpGainOverlay> createState() => _XpGainOverlayState();
}

class _XpGainOverlayState extends State<XpGainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IgnorePointer(
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              alignment: Alignment.center,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+${widget.xp} XP',
                      style: const TextStyle(
                        color: AppColors.xpPrimary,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(
                            color: AppColors.xpPrimary,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    if (widget.streakBonus != null && widget.streakBonus! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Streak Bonus +${widget.streakBonus}',
                          style: TextStyle(
                            color: AppColors.streakFlame.withValues(alpha: 0.9),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
