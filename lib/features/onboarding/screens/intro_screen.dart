import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// The pre-auth introduction: Atlas's pitch, shown before we ask for anything.
/// Three calm pages, each with a small piece of the real app as its picture
/// (the spark, today's card filling, Aurora's letter). Ends at sign-up, which
/// is the point.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <(String, String, String)>[
    (
      'Welcome to Atlas',
      'Every day is a\nsmall sunrise',
      'Tend the habits and tasks that matter to you, and watch a whole world '
          'of places open up over time. No pressure, just gentle progress.',
    ),
    (
      'Tend your days',
      'Small things,\nkept kindly',
      'Add what matters, tap Tend when it’s done, and watch today fill with '
          'light. Miss a day? Nothing is lost.',
    ),
    (
      'Meet Aurora',
      'A companion\nwho notices',
      'Aurora writes you a letter about your week, talks things through when '
          'it helps, and can turn “read before bed” into a habit for you.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Leaving the intro always records it, so it never interrupts again.
  Future<void> _leave(String destination) async {
    await ref.read(onboardingProvider.notifier).markIntroSeen();
    if (!mounted) return;
    // A signed-in replay just falls through to the rest of the first run.
    if (ref.read(authProvider).isAuthenticated) return;
    context.go(destination);
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: AppMotion.medium, curve: AppMotion.standard);
    } else {
      _leave('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLast = _page == _pages.length - 1;
    final signedIn = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.gutter + AppSpacing.headerInset),
                  const AtlasLockup(height: 22),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: isLast ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: isLast,
                      child: Pressable(
                        onTap: () => _leave('/login'),
                        haptic: PressHaptic.selection,
                        semanticLabel: 'Skip',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.gutter, vertical: 14),
                          child: Text('Skip',
                              style: AppTypography.chip.copyWith(color: p.textMuted)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    _IntroPage(
                      index: i,
                      eyebrow: _pages[i].$1,
                      title: _pages[i].$2,
                      body: _pages[i].$3,
                    ),
                ],
              ),
            ),
            Padding(
              padding: readableInsets(context, top: AppSpacing.sm, bottom: AppSpacing.md),
              child: Column(
                children: [
                  _Dots(count: _pages.length, index: _page),
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: isLast ? (signedIn ? 'Continue' : 'Create your account') : 'Continue',
                    icon: isLast ? Symbols.auto_awesome_rounded : null,
                    height: 56,
                    expand: true,
                    onTap: _next,
                  ),
                  // The quiet path for people who already have an account.
                  SizedBox(
                    height: 48,
                    child: AnimatedOpacity(
                      duration: AppMotion.fast,
                      opacity: isLast && !signedIn ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !isLast || signedIn,
                        child: Center(
                          child: Pressable(
                            onTap: () => _leave('/login'),
                            haptic: PressHaptic.selection,
                            semanticLabel: 'I already have an account',
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text('I already have an account',
                                  style: AppTypography.chip.copyWith(color: p.textMuted)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.index,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final int index;
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final page = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: (constraints.maxHeight * .5).clamp(200.0, 320.0),
                  child: Center(
                    child: IgnorePointer(child: ExcludeSemantics(child: _Picture(index: index))),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eyebrow.toUpperCase(),
                          style: AppTypography.kicker.copyWith(color: AtlasPalette.accent)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(title,
                          style: AppTypography.display(size: 36, height: 1.05, color: p.textPrimary)),
                      const SizedBox(height: AppSpacing.md),
                      Text(body, style: AppTypography.body.copyWith(color: p.textBody)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
    if (AppMotion.reduceMotion(context)) return page;
    return page
        .animate(key: ValueKey(title))
        .fadeIn(duration: AppMotion.medium)
        .slideY(begin: 0.04, end: 0, curve: AppMotion.standard);
  }
}

/// The small piece of the app each page shows.
class _Picture extends StatelessWidget {
  const _Picture({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    switch (index) {
      case 0:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.letter),
            ),
            const AtlasSpark(size: 128, animated: true),
          ],
        );
      case 1:
        return SizedBox(
          width: 300,
          child: InkHeroCard(
            height: 190,
            glowLevel: .75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today',
                    style: AppTypography.dateLine.copyWith(color: p.onRaised.withValues(alpha: .7))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CountUpText(
                          value: 75,
                          animateFromZero: true,
                          style: AppTypography.display(size: 72, height: .8, color: p.onRaised),
                        ),
                        GradientText('%', style: AppTypography.display(size: 72, height: .8)),
                        const SizedBox(width: 10),
                        Text('3 of 4\ntended',
                            style: AppTypography.sans(
                                size: 14,
                                weight: FontWeight.w600,
                                color: p.onRaised.withValues(alpha: .75))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ProgressSegments(total: 4, done: 3),
                  ],
                ),
              ],
            ),
          ),
        );
      default:
        return Container(
          width: 300,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: p.letter,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                right: -50,
                top: -50,
                child: Opacity(opacity: .5, child: AtlasSpark(size: 120, animated: true)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SUNDAY LETTER', style: AppTypography.kicker.copyWith(color: p.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  Text('You moved at your own pace, and it counted.',
                      style: AppTypography.display(
                          size: 26, weight: FontWeight.w600, height: 1.08, color: p.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    PillButton(label: 'Listen', icon: Symbols.play_arrow_rounded, onTap: () {}),
                  ]),
                ],
              ),
            ],
          ),
        );
    }
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                gradient: i == index ? AppColors.sunriseBar : null,
                color: i == index ? null : p.outline,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
        ],
      ),
    );
  }
}
