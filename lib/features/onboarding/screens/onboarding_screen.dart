import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/living_horizon.dart';

/// First-run introduction. Three calm pages that set up the living-world
/// metaphor and introduce Aurora, then a gentle personalisation step that gives
/// the user something real to tend on day one. The horizon behind the copy
/// grows richer with each page — the promise, demonstrated.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  final _selected = <String>{};
  bool _finishing = false;

  static const _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(
          duration: AppMotion.medium, curve: AppMotion.standard);
    } else {
      _finish(_selected);
    }
  }

  Future<void> _finish(Set<String> focus) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref.read(onboardingProvider.notifier).complete(focusIds: focus);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pageCount - 1;

    // The world fills in as the user moves through the intro.
    final horizonProgress = 0.25 + (_page / (_pageCount - 1)) * 0.7;

    return Scaffold(
      body: Stack(
        children: [
          // Atmospheric hero, growing with progress.
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
                  // Melt the hero into the page.
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
                // Skip — quiet, always available.
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
                          onPressed: _finishing ? null : () => _finish(const {}),
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
                      const _IntroPage(
                        eyebrow: 'Welcome to Atlas',
                        title: 'A world that grows\nas you care for yourself',
                        body:
                            'Every habit you tend, every small step you take, '
                            'brings your world a little more to life. No '
                            'pressure — just gentle progress.',
                      ),
                      const _IntroPage(
                        eyebrow: 'Tend your days',
                        title: 'Small things,\nkept kindly',
                        body:
                            'Add the habits, tasks and goals that matter to '
                            'you. Check them off and watch your horizon turn '
                            'greener. Miss a day? Nothing is lost.',
                      ),
                      const _IntroPage(
                        eyebrow: 'Meet Aurora',
                        title: 'A companion\nwho notices',
                        body:
                            'Aurora reflects on your week in your own words, '
                            'talks things through when it helps, and can turn '
                            '“read before bed” into a habit for you.',
                      ),
                      _FocusPage(
                        selected: _selected,
                        onToggle: (id) => setState(() {
                          _selected.contains(id)
                              ? _selected.remove(id)
                              : _selected.add(id);
                        }),
                      ),
                    ],
                  ),
                ),

                // Dots + primary action.
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                      AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                  child: Column(
                    children: [
                      _Dots(count: _pageCount, index: _page),
                      AppSpacing.gapMd,
                      AppButton(
                        label: isLast
                            ? (_selected.isEmpty
                                ? 'Start fresh'
                                : 'Begin with ${_selected.length} focus${_selected.length == 1 ? '' : 'es'}')
                            : 'Continue',
                        icon: isLast
                            ? Icons.auto_awesome_rounded
                            : Icons.arrow_forward_rounded,
                        isLoading: _finishing,
                        onPressed: _finishing ? null : _next,
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

// ─── Intro page ─────────────────────────────────────────────────────

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
                Text(
                  title,
                  style: theme.textTheme.displaySmall?.copyWith(height: 1.12),
                ),
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

// ─── Personalisation page ───────────────────────────────────────────

class _FocusPage extends StatelessWidget {
  const _FocusPage({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

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
                  'WHERE SHALL WE BEGIN?',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.auroraLilac,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  'Pick what matters\nright now',
                  style: theme.textTheme.displaySmall?.copyWith(height: 1.12),
                ),
                AppSpacing.gapXs,
                Text(
                  'We’ll add a few gentle habits to get you started. '
                  'Change them anytime — nothing is locked in.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                AppSpacing.gapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final area in kFocusAreas)
                      _FocusChip(
                        area: area,
                        selected: selected.contains(area.id),
                        onTap: () => onToggle(area.id),
                      ),
                  ],
                ),
                AppSpacing.gapLg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({
    required this.area,
    required this.selected,
    required this.onTap,
  });

  final FocusArea area;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: (MediaQuery.of(context).size.width - AppSpacing.gutter * 2 -
                  AppSpacing.sm) /
              2,
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: selected
                ? area.color.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? area.color : theme.colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          // The tick floats over the corner so it never squeezes the label.
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          area.color.withValues(alpha: selected ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(area.icon, size: 20, color: area.color),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(area.label,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          area.blurb,
                          maxLines: 2,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedScale(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  scale: selected ? 1 : 0,
                  child: Icon(Icons.check_circle_rounded,
                      size: 18, color: area.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page dots ──────────────────────────────────────────────────────

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
