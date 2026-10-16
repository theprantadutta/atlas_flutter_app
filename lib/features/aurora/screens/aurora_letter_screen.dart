import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/core/utils/prose.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/providers/letter_tts_provider.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/letter_widgets.dart';
import 'package:atlas_flutter_app/features/home/providers/home_prefs.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// The whole letter. Opening it marks it read (the Home tile goes quiet).
class AuroraLetterScreen extends ConsumerStatefulWidget {
  const AuroraLetterScreen({super.key});

  @override
  ConsumerState<AuroraLetterScreen> createState() => _AuroraLetterScreenState();
}

class _AuroraLetterScreenState extends ConsumerState<AuroraLetterScreen> {
  String? _markedId;

  void _markRead(String id) {
    if (_markedId == id) return;
    _markedId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(letterReadProvider.notifier).markRead(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reflection = ref.watch(latestReflectionProvider).value;
    final gen = ref.watch(reflectionGenProvider);
    if (reflection != null) _markRead(reflection.id);

    return Scaffold(
      body: SafeArea(
        child: reflection == null
            ? Column(children: [
                Padding(
                  padding: readableInsets(context, top: AppSpacing.xs, bottom: 0),
                  child: ScreenHeader(title: 'Letter', onBack: () => context.pop()),
                ),
                const Expanded(
                  child: Center(child: EmptyState(title: 'No letter yet.')),
                ),
              ])
            : ListView(
                padding: readableInsets(context, top: AppSpacing.xs, bottom: AppSpacing.xxl),
                children: [
                  Row(children: [
                    CircleIconButton.back(onTap: () {
                      ref.read(letterTtsProvider.notifier).stop();
                      context.pop();
                    }),
                    const Spacer(),
                    if (reflection.modelTier.startsWith('paid'))
                      AtlasChip(
                        label: 'Deep',
                        icon: Symbols.auto_awesome_rounded,
                        iconColor: AppColors.sunriseB,
                        background: p.paper,
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: p.letter,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const AtlasSpark(size: 26, animated: true),
                          const SizedBox(width: 10),
                          Text(letterKicker(reflection),
                              style: AppTypography.kicker.copyWith(color: p.textPrimary)),
                          const Spacer(),
                          Text(letterRange(reflection),
                              style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
                        ]),
                        const SizedBox(height: AppSpacing.lg - 4),
                        Consumer(builder: (context, ref, _) {
                          final tts = ref.watch(letterTtsProvider);
                          final speaking = tts.textId == reflection.id && tts.offset > 0;
                          return SpokenHeadline(
                            text: firstSentence(reflection.content),
                            spokenUpTo: speaking ? tts.offset : null,
                            style: AppTypography.letterHeadline.copyWith(color: p.textPrimary),
                          );
                        }),
                        const SizedBox(height: AppSpacing.md),
                        ListenButton(reflection: reflection),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GptMarkdown(
                      reflection.content,
                      style: AppTypography.sans(size: 16, height: 1.65, color: p.textBody),
                      linkBuilder: null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('From Aurora',
                      style: AppTypography.sans(
                          size: 15, weight: FontWeight.w600, fontStyle: FontStyle.italic, color: p.textMuted)),
                  const SizedBox(height: AppSpacing.xl),
                  Row(children: [
                    Expanded(
                      child: PillButton(
                        label: 'Talk about it',
                        icon: Symbols.forum_rounded,
                        height: 52,
                        onTap: () => context.push('/aurora-chat',
                            extra: 'I just read my letter. Can we talk about it?'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    PillButton(
                      label: gen.generating ? 'Writing' : 'Write a new one',
                      variant: PillVariant.track,
                      height: 52,
                      busy: gen.generating,
                      onTap: () => ref.read(reflectionGenProvider.notifier).generate(),
                    ),
                  ]),
                ],
              ),
      ),
    );
  }
}
