import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Your conversations with Aurora, newest first. Tap one to reopen it; swipe
/// left or long press to delete it (with Undo). Everything here lives on the
/// device only.
Future<void> showConversationHistorySheet(BuildContext context) {
  return showAtlasSheet<void>(context, builder: (_) => const ConversationHistorySheet());
}

/// "Today, 9:15 am", "Yesterday", "Monday", "12 Oct", "12 Oct 2024".
String conversationDateLabel(DateTime when, DateTime now) {
  final days = daysBetween(dateOnly(when), dateOnly(now));
  if (days <= 0) return 'Today, ${clockLabel(when.hour, when.minute)}';
  if (days == 1) return 'Yesterday';
  if (days < 7) return weekdayName(when);
  final short = '${when.day} ${monthShort(when)}';
  return when.year == now.year ? short : '$short ${when.year}';
}

class ConversationHistorySheet extends ConsumerWidget {
  const ConversationHistorySheet({super.key, this.now});

  /// For tests; defaults to the clock.
  final DateTime? now;

  Future<void> _open(BuildContext context, WidgetRef ref, AuroraConversation c) async {
    final nav = Navigator.of(context);
    await ref.read(auroraChatProvider.notifier).openConversation(c.id);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AuroraConversation c) async {
    final notifier = ref.read(auroraChatProvider.notifier);
    final deleted = await notifier.deleteConversation(c.id);
    if (deleted == null || !context.mounted) return;
    AtlasToast.undo(
      context,
      'Conversation deleted',
      onUndo: () => notifier.restoreConversation(deleted),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, AuroraConversation c) async {
    final choice = await showActionSheet<String>(
      context,
      title: c.title,
      actions: const [
        SheetAction(value: 'open', label: 'Open', icon: Symbols.forum_rounded),
        SheetAction(
            value: 'delete', label: 'Delete', icon: Symbols.delete_rounded, destructive: true),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'open':
        await _open(context, ref, c);
      case 'delete':
        await _delete(context, ref, c);
    }
  }

  void _new(BuildContext context, WidgetRef ref) {
    ref.read(auroraChatProvider.notifier).reset();
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(auroraConversationsProvider);
    final openId = ref.watch(auroraChatProvider.select((s) => s.conversationId));
    final list = async.value ?? const <AuroraConversation>[];
    final clock = now ?? DateTime.now();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter + 4, 0, AppSpacing.gutter, 0),
            child: Row(children: [
              Expanded(
                child: Text('Conversations',
                    style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
              ),
              PillButton(
                label: 'New',
                icon: Symbols.add_rounded,
                height: 40,
                haptic: PressHaptic.selection,
                onTap: () => _new(context, ref),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter + 4),
            child: Text('Kept on this device only.',
                style: AppTypography.meta.copyWith(color: p.textMuted)),
          ),
          const SizedBox(height: AppSpacing.md),
          if (async.isLoading && list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: SkeletonList(count: 3),
            )
          else if (list.isEmpty)
            const EmptyState(
              title: 'No conversations yet.',
              body: 'Whatever you talk about with Aurora will wait for you here.',
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final c = list[i];
                  final isOpen = c.id == openId;
                  return Padding(
                    key: ValueKey('conversation-${c.id}'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EntryFade(
                      id: 'conversation-${c.id}',
                      index: i,
                      child: AtlasRow(
                        leading: IconTile(
                          style: const CategoryStyle(Symbols.forum_rounded, AppColors.violet),
                          size: 40,
                        ),
                        title: c.title.isEmpty ? 'A conversation' : c.title,
                        meta: conversationDateLabel(c.updatedAt, clock),
                        trailing: isOpen
                            ? AtlasChip(label: 'Open now', dense: true, background: p.track)
                            : null,
                        swipeLeftLabel: 'Delete',
                        onTap: () => _open(context, ref, c),
                        onLongPress: () => _menu(context, ref, c),
                        onSwipeLeft: () => _delete(context, ref, c),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
