import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// Anchors the first-run coach marks point at. Screens attach these keys to the
/// widgets they own; the overlay reads their positions to place the spotlight.
class CoachMarkKeys {
  final GlobalKey hero = GlobalKey(debugLabel: 'coach-hero');
  final GlobalKey auroraTab = GlobalKey(debugLabel: 'coach-aurora-tab');
  final GlobalKey fab = GlobalKey(debugLabel: 'coach-fab');
}

final coachMarkKeysProvider = Provider<CoachMarkKeys>((ref) => CoachMarkKeys());

class _Step {
  const _Step({
    required this.title,
    required this.body,
    required this.radius,
    required this.circle,
  });
  final String title;
  final String body;
  final double radius;
  final bool circle;
}

const _steps = <_Step>[
  _Step(
    title: 'Your living world',
    body:
        'This is you. It grows greener and brighter as you tend the things you '
        'care about.',
    radius: AppSpacing.radiusLg,
    circle: false,
  ),
  _Step(
    title: 'Aurora, your companion',
    body:
        'A weekly reflection in your own words, and a calm space to talk things '
        'through whenever you need it.',
    radius: AppSpacing.radiusPill,
    circle: false,
  ),
  _Step(
    title: 'Add anything, fast',
    body:
        'Tap to add a habit, task or goal, or simply describe it and let Aurora '
        'set it up for you.',
    radius: AppSpacing.radiusPill,
    circle: true,
  ),
];

/// A gentle three-step tour of Home, shown once after onboarding. Renders
/// nothing when it has already been seen. Drop it as the topmost child of the
/// navigation shell so it can cover the nav bar and the floating button.
class CoachMarks extends ConsumerStatefulWidget {
  const CoachMarks({super.key, required this.enabled});

  /// Only show while the Home tab is the active destination.
  final bool enabled;

  @override
  ConsumerState<CoachMarks> createState() => _CoachMarksState();
}

class _CoachMarksState extends ConsumerState<CoachMarks> {
  int _step = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first layout so the anchors have real positions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  Rect? _rectFor(int step) {
    final keys = ref.read(coachMarkKeysProvider);
    final key = switch (step) {
      0 => keys.hero,
      1 => keys.auroraTab,
      _ => keys.fab,
    };
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      ref.read(onboardingProvider.notifier).markCoachMarksSeen();
    }
  }

  void _dismiss() => ref.read(onboardingProvider.notifier).markCoachMarksSeen();

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    if (!widget.enabled ||
        !onboarding.loaded ||
        !onboarding.setupComplete ||
        onboarding.coachMarksSeen ||
        !_ready) {
      return const SizedBox.shrink();
    }

    final target = _rectFor(_step);
    if (target == null) return const SizedBox.shrink();

    final step = _steps[_step];
    final media = MediaQuery.of(context);
    final spotlight = target.inflate(AppSpacing.xs);

    // Place the caption on whichever side has more room.
    final below = spotlight.bottom + AppSpacing.md;
    final captionBelow = below + 190 < media.size.height;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: Stack(
            children: [
              // Dimmed scrim with a hole punched over the target.
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    rect: spotlight,
                    radius: step.circle ? spotlight.longestSide : step.radius,
                  ),
                ),
              ),
              // A soft aurora ring around the spotlight.
              Positioned(
                left: spotlight.left,
                top: spotlight.top,
                width: spotlight.width,
                height: spotlight.height,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          step.circle ? spotlight.longestSide : step.radius),
                      border: Border.all(
                        color: AppColors.auroraLilac.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.auroraLilac.withValues(alpha: 0.45),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Caption.
              Positioned(
                left: AppSpacing.gutter,
                right: AppSpacing.gutter,
                top: captionBelow ? below : null,
                bottom: captionBelow
                    ? null
                    : media.size.height - spotlight.top + AppSpacing.md,
                child: _CaptionCard(
                  step: step,
                  index: _step,
                  total: _steps.length,
                  onNext: _next,
                  onSkip: _dismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.rect, required this.radius});

  final Rect rect;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      Paint()..color = const Color(0xFF080C1A).withValues(alpha: 0.82),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.rect != rect || old.radius != radius;
}

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final _Step step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(step.title, style: theme.textTheme.titleLarge),
          AppSpacing.gapXs,
          Text(
            step.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              for (var i = 0; i < total; i++)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: i == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: i == index ? AppColors.auroraGradient : null,
                    color: i == index
                        ? null
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              const Spacer(),
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(width: AppSpacing.xxs),
              _PillButton(label: isLast ? 'Got it' : 'Next', onTap: onNext),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.fast).slideY(
        begin: 0.06, end: 0, curve: AppMotion.standard);
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF10243B),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
