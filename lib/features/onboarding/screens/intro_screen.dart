import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/living_horizon.dart';

/// The pre-auth introduction — Atlas's pitch, shown before we ask for anything.
/// Three calm pages set up the living-world metaphor and introduce Aurora, and
/// the horizon behind the copy grows richer with each one: the promise,
/// demonstrated. Ends at the sign-up, which is the point.
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
      'A world that grows\nas you care for yourself',
      'Every habit you tend, every small step you take, brings your world a '
          'little more to life. No pressure, just gentle progress.',
    ),
    (
      'Tend your days',
      'Small things,\nkept kindly',
      'Add the habits, tasks and goals that matter to you. Check them off and '
          'watch your horizon turn greener. Miss a day? Nothing is lost.',
    ),
    (
      'Meet Aurora',
      'A companion\nwho notices',
      'Aurora reflects on your week in your own words, talks things through '
          'when it helps, and can turn “read before bed” into a habit for you.',
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
      _controller.nextPage(
          duration: AppMotion.medium, curve: AppMotion.standard);
    } else {
      _leave('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;
    final signedIn = ref.watch(authProvider).isAuthenticated;
    final horizonProgress = 0.25 + (_page / (_pages.length - 1)) * 0.65;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.46,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.25, end: horizonProgress),
                    duration: AppMotion.slow,
                    curve: AppMotion.standard,
                    builder: (context, value, _) => LivingHorizon(
                      height: double.infinity,
                      progress: value,
                      brightness: Brightness.dark,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                          theme.scaffoldBackgroundColor,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: isLast ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: isLast,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: TextButton(
                          onPressed: () => _leave('/login'),
                          child: Text(
                            'Skip',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      for (final (eyebrow, title, body) in _pages)
                        _IntroPage(eyebrow: eyebrow, title: title, body: body),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                      AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                  child: Column(
                    children: [
                      _Dots(count: _pages.length, index: _page),
                      AppSpacing.gapMd,
                      AppButton(
                        label: isLast
                            ? (signedIn ? 'Continue' : 'Create your account')
                            : 'Continue',
                        icon: isLast
                            ? Icons.auto_awesome_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: _next,
                      ),
                      // The quiet path for people who already have an account.
                      SizedBox(
                        height: 44,
                        child: AnimatedOpacity(
                          duration: AppMotion.fast,
                          opacity: isLast && !signedIn ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !isLast || signedIn,
                            child: TextButton(
                              onPressed: () => _leave('/login'),
                              child: Text(
                                'I already have an account',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
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
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.auroraLilac,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                AppSpacing.gapSm,
                Text(title,
                    style: theme.textTheme.displaySmall?.copyWith(height: 1.12)),
                AppSpacing.gapMd,
                Text(
                  body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                AppSpacing.gapLg,
              ],
            ),
          ),
        ),
      ),
    ).animate(key: ValueKey(title)).fadeIn(duration: AppMotion.medium).slideY(
        begin: 0.05, end: 0, curve: AppMotion.standard);
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
              gradient: i == index ? AppColors.auroraGradient : null,
              color: i == index
                  ? null
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
      ],
    );
  }
}
