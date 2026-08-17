import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/aurora_nudge_card.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Aurora — the AI companion's home. A calm landing that surfaces the weekly
/// reflection over your real progress and gentle ways in; the focused
/// conversation opens full-screen from here.
class AuroraScreen extends ConsumerStatefulWidget {
  const AuroraScreen({super.key});

  @override
  ConsumerState<AuroraScreen> createState() => _AuroraScreenState();
}

class _AuroraScreenState extends ConsumerState<AuroraScreen> {
  @override
  Widget build(BuildContext context) {
    // Route reflection over-limit to the paywall.
    ref.listen(reflectionGenProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit == true) {
        ref.read(reflectionGenProvider.notifier).clearPaywall();
        context.push('/paywall');
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md,
              AppSpacing.gutter, AppSpacing.bottomNavSpace),
          children: [
            const AtlasHeader(
              title: 'Aurora',
              subtitle: 'Your gentle companion',
              trailing: _AuroraMark(),
            ),
            const AuroraNudgeCard(),
            AppSpacing.gapLg,
            const _ReflectionCard()
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.05, end: 0, curve: AppMotion.standard),
            AppSpacing.gapLg,
            _TalkCard(onOpen: () => context.push('/aurora-chat'))
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 80.ms),
            AppSpacing.gapMd,
            Text('Ways in', style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.gapSm,
            _PromptWrap(
              onPrompt: (p) => context.push('/aurora-chat', extra: p),
            ).animate().fadeIn(duration: AppMotion.medium, delay: 140.ms),
            AppSpacing.gapMd,
            const AuroraUsageMeter(),
          ],
        ),
      ),
    );
  }
}

// ─── The Aurora mark (a small living orb) ───────────────────────────

class _AuroraMark extends StatelessWidget {
  const _AuroraMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.auroraGradient,
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          size: 20, color: Color(0xFF10243B)),
    );
  }
}

// ─── Talk-it-through entry ──────────────────────────────────────────

class _TalkCard extends StatelessWidget {
  const _TalkCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                child: const Icon(Icons.forum_rounded,
                    color: Color(0xFF10243B), size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Talk it through',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: const Color(0xFF10243B))),
                    Text('A calm space to check in with Aurora',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF10243B)
                                .withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF10243B)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Suggested prompts ──────────────────────────────────────────────

class _PromptWrap extends StatelessWidget {
  const _PromptWrap({required this.onPrompt});
  final ValueChanged<String> onPrompt;

  static const _prompts = <(IconData, String, String)>[
    (Icons.spa_rounded, 'How was my week?', 'How was my week?'),
    (Icons.self_improvement_rounded, 'Help me reset gently',
        'I’m feeling off and could use a gentle reset. Can you help?'),
    (Icons.add_task_rounded, 'Add a habit',
        'Add a habit to read for 20 minutes before bed'),
    (Icons.favorite_rounded, 'A word of encouragement',
        'Could you share a little encouragement for today?'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (icon, label, prompt) in _prompts)
          _PromptChip(icon: icon, label: label, onTap: () => onPrompt(prompt)),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reflection card ────────────────────────────────────────────────

class _ReflectionCard extends ConsumerWidget {
  const _ReflectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reflectionAsync = ref.watch(latestReflectionProvider);
    final gen = ref.watch(reflectionGenProvider);

    return reflectionAsync.when(
      loading: () => const _ReflectionSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reflection) {
        if (reflection == null) {
          return AtlasCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Weekly reflection',
                        style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'When you’re ready, Aurora can look back over your week and '
                  'reflect with you, gently and never graded.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: gen.generating ? 'Reflecting…' : 'Reflect on my week',
                  icon: Icons.auto_awesome_rounded,
                  isLoading: gen.generating,
                  onPressed: gen.generating
                      ? null
                      : () =>
                          ref.read(reflectionGenProvider.notifier).generate(),
                ),
              ],
            ),
          );
        }

        return AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.spa_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text('This week with Aurora',
                        style: theme.textTheme.titleLarge),
                  ),
                  if (reflection.modelTier == 'paid') const _DeepBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              GptMarkdown(
                reflection.content,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface, height: 1.55),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    _periodLabel(reflection),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: gen.generating
                        ? null
                        : () =>
                            ref.read(reflectionGenProvider.notifier).generate(),
                    icon: gen.generating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(gen.generating ? 'Reflecting…' : 'Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppMotion.medium);
      },
    );
  }

  String _periodLabel(AuroraReflection r) {
    String d(DateTime t) => '${t.month}/${t.day}';
    return 'Week of ${d(r.periodStart)} to ${d(r.periodEnd)}';
  }
}

class _DeepBadge extends StatelessWidget {
  const _DeepBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text('Deep',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF3A2A00),
                fontWeight: FontWeight.w700,
              )),
    );
  }
}

class _ReflectionSkeleton extends StatelessWidget {
  const _ReflectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget bar(double w) => Container(
          width: w,
          height: 12,
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        );
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(140),
          const SizedBox(height: AppSpacing.xs),
          bar(double.infinity),
          bar(double.infinity),
          bar(220),
        ],
      ),
    );
  }
}
