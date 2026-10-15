import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

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
    title: 'Your day at a glance',
    body:
        'This card shows how today is going. It fills with light as you tend '
        'the things you care about.',
    radius: AppSpacing.radiusXl,
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
        'Tap to add a habit, task or goal, or just describe it and let Aurora '
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
                        color: AppColors.sunriseB.withValues(alpha: 0.9),
                        width: 2,
                      ),
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
      Paint()..color = AppColors.ink.withValues(alpha: 0.72),
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
    final p = context.palette;
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      decoration: BoxDecoration(
        color: p.canvas,
        borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(step.title,
              style: AppTypography.section.copyWith(color: p.textPrimary)),
          AppSpacing.gapXs,
          Text(step.body, style: AppTypography.body.copyWith(color: p.textBody)),
          AppSpacing.gapMd,
          Row(
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: AppMotion.fast,
                  margin: const EdgeInsets.only(right: 4),
                  width: i == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: i == index ? AppColors.sunriseBar : null,
                    color: i == index ? null : p.outline,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              const Spacer(),
              if (!isLast)
                PillButton(
                  label: 'Skip',
                  variant: PillVariant.track,
                  haptic: PressHaptic.selection,
                  onTap: onSkip,
                ),
              const SizedBox(width: AppSpacing.xs),
              PillButton(label: isLast ? 'Got it' : 'Next', onTap: onNext),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.fast).slideY(
        begin: 0.06, end: 0, curve: AppMotion.standard);
  }
}
