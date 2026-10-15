import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

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
    await ref.read(onboardingProvider.notifier).completeSetup(focusIds: _selected);
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
    final p = context.palette;
    final name = _firstName;
    final reduce = AppMotion.reduceMotion(context);

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
            child: AtlasSpark(size: 44, animated: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'WHERE SHALL WE BEGIN?' : 'WELCOME, ${name.toUpperCase()}',
                  style: AppTypography.kicker.copyWith(color: AtlasPalette.accent),
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  header: true,
                  child: Text('Pick what matters\nright now',
                      style: AppTypography.display(size: 36, height: 1.05, color: p.textPrimary)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We’ll add a few gentle habits to get you started. Change them anytime. '
                  'Nothing is locked in.',
                  style: AppTypography.body.copyWith(color: p.textBody),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - AppSpacing.xs) / 2;
            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < kFocusAreas.length; i++)
                  SizedBox(
                    width: w,
                    child: EntryFade(
                      id: 'focus-${kFocusAreas[i].id}',
                      index: i,
                      child: _FocusTile(
                        area: kFocusAreas[i],
                        selected: _selected.contains(kFocusAreas[i].id),
                        onTap: () => setState(() {
                          final id = kFocusAreas[i].id;
                          _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
                        }),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
    if (!reduce) {
      content = content
          .animate()
          .fadeIn(duration: AppMotion.medium)
          .slideY(begin: 0.03, end: 0, curve: AppMotion.standard);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: content),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
              child: PillButton(
                label: _selected.isEmpty
                    ? 'Start fresh'
                    : 'Begin with ${_selected.length} focus${_selected.length == 1 ? '' : 'es'}',
                icon: Symbols.auto_awesome_rounded,
                height: 56,
                expand: true,
                busy: _finishing,
                onTap: _finishing ? null : _finish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A focus area: paper tile with its category tint and a check that pops in
/// when chosen. The chosen state wears a soft sunrise outline.
class _FocusTile extends StatelessWidget {
  const _FocusTile({required this.area, required this.selected, required this.onTap});

  final FocusArea area;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = CategoryStyle.forCategory(area.category);
    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      semanticLabel: '${area.label}, ${area.blurb}',
      child: Semantics(
        selected: selected,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
            border: Border.all(
              color: selected ? p.recommendedBorder : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconTile(style: style, size: 40),
                  const Spacer(),
                  SizedBox.square(
                    dimension: 26,
                    child: AnimatedScale(
                      duration: AppMotion.fast,
                      curve: AppMotion.emphasized,
                      scale: selected ? 1 : 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.sunrise,
                        ),
                        child: const AtlasIcon(Symbols.check_rounded,
                            size: 16, color: AppColors.white, weight: 600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(area.label, style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: 2),
              Text(area.blurb,
                  maxLines: 2,
                  style: AppTypography.meta.copyWith(color: p.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
