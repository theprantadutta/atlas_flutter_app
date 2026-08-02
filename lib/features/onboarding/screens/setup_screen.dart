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

/// The post-sign-in personalisation step. Picking a few focus areas seeds real
/// habits into the local database, so the very first Home screen has something
/// to tend instead of an empty world.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _selected = <String>{};
  bool _finishing = false;

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref
        .read(onboardingProvider.notifier)
        .completeSetup(focusIds: _selected);
    if (!mounted) return;
    context.go('/');
  }

  String get _firstName {
    final full = ref.read(authProvider).user?.fullName.trim() ?? '';
    if (full.isEmpty) return '';
    return full.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _firstName;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.34,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const LivingHorizon(
                    height: double.infinity,
                    progress: 0.9,
                    brightness: Brightness.dark,
                    borderRadius: BorderRadius.zero,
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
                        stops: const [0.0, 0.45, 1.0],
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.xxl, AppSpacing.gutter, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty
                              ? 'WHERE SHALL WE BEGIN?'
                              : 'WELCOME, ${name.toUpperCase()}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.auroraLilac,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          'Pick what matters\nright now',
                          style: theme.textTheme.displaySmall
                              ?.copyWith(height: 1.12),
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
                        AppSpacing.gapLg,
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final area in kFocusAreas)
                              _FocusChip(
                                area: area,
                                selected: _selected.contains(area.id),
                                onTap: () => setState(() {
                                  _selected.contains(area.id)
                                      ? _selected.remove(area.id)
                                      : _selected.add(area.id);
                                }),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: AppMotion.medium).slideY(
                      begin: 0.04, end: 0, curve: AppMotion.standard),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0,
                      AppSpacing.gutter, AppSpacing.md),
                  child: AppButton(
                    label: _selected.isEmpty
                        ? 'Start fresh'
                        : 'Begin with ${_selected.length} focus${_selected.length == 1 ? '' : 'es'}',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _finishing,
                    onPressed: _finishing ? null : _finish,
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
