import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/utils/prose.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/providers/letter_tts_provider.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/letter_widgets.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// A way into a conversation: tapping sends the label as the first message.
class _Starter {
  const _Starter(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

const _starters = [
  _Starter('Tell it the way it is', Symbols.edit_note_rounded, AppColors.coral),
  _Starter('Plan my week', Symbols.calendar_month_rounded, AppColors.violet),
  _Starter('Celebrate a small win', Symbols.celebration_rounded, AppColors.amber),
  _Starter('I feel stuck', Symbols.cloud_rounded, AppColors.sky),
];

/// Aurora: her weekly letter, and ways to start a conversation.
class AuroraScreen extends ConsumerWidget {
  const AuroraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Route reflection over-limit to the paywall.
    ref.listen(reflectionGenProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit == true) {
        ref.read(reflectionGenProvider.notifier).clearPaywall();
        context.push('/paywall');
      }
    });
    ref.listen(reflectionGenProvider.select((s) => s.error), (_, err) {
      if (err != null) AtlasToast.error(context, err);
    });

    final gen = ref.watch(reflectionGenProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: ref.watch(tabScrollControllersProvider).of(2),
          padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, navScrollPadding(context)),
          children: [
            ScreenHeader(
              title: 'Aurora',
              leading: AtlasSpark(size: 40, animated: true, busy: gen.generating),
              trailing: CircleIconButton(
                icon: Symbols.tune_rounded,
                semanticLabel: 'Aurora’s voice',
                onTap: () => context.push('/aurora/settings'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _LetterCard(),
            const SizedBox(height: AppSpacing.md),
            const SectionTitle('Start a conversation'),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _starters.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: EntryFade(
                  id: 'starter-$i',
                  index: i,
                  child: LinkRow(
                    icon: _starters[i].icon,
                    iconColor: _starters[i].color,
                    label: _starters[i].label,
                    onTap: () => context.push('/aurora-chat', extra: _starters[i].label),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: LinkRow(
                icon: Symbols.forum_rounded,
                label: 'Just talk',
                onTap: () => context.push('/aurora-chat'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const AuroraUsageMeter(padding: EdgeInsets.symmetric(horizontal: 4)),
          ],
        ),
      ),
    );
  }
}

/// Aurora's letter: the first sentence as a headline, the next two as body,
/// Listen and Read all. Before the first letter, an invitation to write one.
class _LetterCard extends ConsumerWidget {
  const _LetterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(latestReflectionProvider);
    final gen = ref.watch(reflectionGenProvider);
    final reflection = async.value;

    if (async.isLoading && reflection == null) {
      return const Skeleton(height: 300, radius: AppSpacing.radiusXl);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: p.letter,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -30,
            top: -30,
            child: Opacity(opacity: .5, child: AtlasSpark(size: 140, animated: true)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: reflection == null
                ? _Invitation(generating: gen.generating)
                : _Letter(reflection: reflection),
          ),
          if (reflection != null) _ListenProgress(reflection: reflection),
        ],
      ),
    );
  }
}

class _Letter extends ConsumerWidget {
  const _Letter({required this.reflection});
  final AuroraReflection reflection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tts = ref.watch(letterTtsProvider);
    final headline = firstSentence(reflection.content);
    final body = nextSentences(reflection.content, 2);
    final speaking = tts.textId == reflection.id && (tts.playing || tts.offset > 0);
    final id = 'letter-${reflection.id}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(letterKicker(reflection), style: AppTypography.kicker.copyWith(color: p.textPrimary)),
          const Spacer(),
          Text(letterRange(reflection), style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
        ]),
        const SizedBox(height: AppSpacing.md),
        EntryFade(
          id: '$id-h',
          index: 0,
          duration: AppMotion.fast,
          child: SpokenHeadline(
            text: headline,
            spokenUpTo: speaking ? tts.offset : null,
            style: AppTypography.letterHeadline.copyWith(color: p.textPrimary),
          ),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          EntryFade(
            id: '$id-b',
            index: 2,
            child: Text(body, style: AppTypography.body.copyWith(color: p.textBody)),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        EntryFade(
          id: '$id-a',
          index: 4,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ListenButton(reflection: reflection),
              PillButton(
                label: 'Read all',
                variant: PillVariant.letter,
                height: 46,
                haptic: PressHaptic.selection,
                onTap: () => context.push('/aurora/letter'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The thin sunrise line that grows along the bottom while she reads.
class _ListenProgress extends ConsumerWidget {
  const _ListenProgress({required this.reflection});
  final AuroraReflection reflection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(letterTtsProvider);
    final active = tts.textId == reflection.id && tts.progress > 0 && tts.progress < 1;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 3,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: AppMotion.fast,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: AppMotion.medium,
            widthFactor: tts.textId == reflection.id ? tts.progress : 0,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.sunriseBar),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Invitation extends ConsumerWidget {
  const _Invitation({required this.generating});
  final bool generating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR LETTER', style: AppTypography.kicker.copyWith(color: p.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        Text('Your week, in Aurora’s words.',
            style: AppTypography.letterHeadline.copyWith(color: p.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        Text(
          'When you’re ready, she’ll look back over your week with you. Gently, and never graded.',
          style: AppTypography.body.copyWith(color: p.textBody),
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: generating ? 'Writing your letter' : 'Write my letter',
          icon: Symbols.edit_rounded,
          height: 46,
          busy: generating,
          onTap: () => ref.read(reflectionGenProvider.notifier).generate(),
        ),
      ],
    );
  }
}
