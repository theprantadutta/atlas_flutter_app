import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// "Remember this?" under an Aurora reply: one quiet card per fact she
/// offers to keep in mind, with Save and Not now. Nothing is stored without
/// the Save tap. Only premium replies carry proposals, so for everyone else
/// (and once every chip is answered) this renders nothing.
class MemoryProposals extends ConsumerWidget {
  const MemoryProposals({super.key, required this.index});

  /// The reply's position in the conversation.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(auroraChatProvider.select((s) => s.openMemories(index)));
    return AnimatedSize(
      duration: AppMotion.reduceMotion(context) ? Duration.zero : AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.topLeft,
      child: open.isEmpty
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < open.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: EntryFade(
                      id: 'memory-$index-${open[i]}',
                      index: i,
                      child: MemoryChip(
                        text: open[i],
                        onSave: () async {
                          await ref
                              .read(auroraChatProvider.notifier)
                              .saveMemory(index, open[i]);
                          if (context.mounted) {
                            AtlasToast.success(context, 'Aurora will remember that');
                          }
                        },
                        onDismiss: () => ref
                            .read(auroraChatProvider.notifier)
                            .dismissMemory(index, open[i]),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// One "Remember this?" card: the fact in Aurora's words, Save / Not now.
class MemoryChip extends StatelessWidget {
  const MemoryChip({
    super.key,
    required this.text,
    required this.onSave,
    required this.onDismiss,
  });

  final String text;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const AtlasSpark(size: 14),
            const SizedBox(width: 6),
            Text('REMEMBER THIS?', style: AppTypography.kicker.copyWith(color: p.textMuted)),
          ]),
          const SizedBox(height: 6),
          Text(text,
              style: AppTypography.sans(
                  size: 14, weight: FontWeight.w600, height: 1.4, color: p.textPrimary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PillButton(
                label: 'Not now',
                variant: PillVariant.track,
                height: 34,
                haptic: PressHaptic.selection,
                onTap: onDismiss,
              ),
              const SizedBox(width: AppSpacing.xs),
              PillButton(
                label: 'Save',
                icon: Symbols.bookmark_rounded,
                height: 34,
                haptic: PressHaptic.light,
                onTap: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
