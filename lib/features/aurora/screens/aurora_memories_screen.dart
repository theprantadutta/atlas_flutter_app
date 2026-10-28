import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_memory_repository.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// "What Aurora remembers": the small, lasting facts Aurora keeps in mind
/// (premium). They are saved from chat with a tap, or typed here, and stay
/// on this device. Free users see what the feature is and the upgrade row.
class AuroraMemoriesScreen extends ConsumerWidget {
  const AuroraMemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(isPremiumProvider);
    return SettingsPage(
      title: 'What Aurora remembers',
      onBack: () => context.pop(),
      children: [
        const _Intro(),
        settingsGap,
        if (premium) const _MemoryList() else const _Locked(),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: p.letter,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Stack(children: [
        const Positioned(
          right: -24,
          top: -24,
          child: Opacity(opacity: .5, child: AtlasSpark(size: 110, animated: true)),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SHE KEEPS IN MIND', style: AppTypography.kicker.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.md),
              Text('The things that matter to you, so you don’t have to say them twice.',
                  style: AppTypography.letterHeadline.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aurora only remembers what you save. Everything stays on this device, '
                'and you can forget any of it at any time.',
                style: AppTypography.body.copyWith(color: p.textBody),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsFootnote(
            'In a chat, Aurora can offer to remember a lasting fact, like a goal you are '
            'working towards or a change in your life. You choose what to keep, and you '
            'can add your own.',
          ),
          settingsGap,
          UpgradeCtaCard(
            icon: Symbols.bookmark_rounded,
            title: 'Memory is part of Atlas Aurora',
            subtitle: 'Let Aurora keep what matters in mind.',
            actionLabel: 'Upgrade',
          ),
        ],
      );
}

class _MemoryList extends ConsumerWidget {
  const _MemoryList();

  Future<void> _forget(BuildContext context, WidgetRef ref, AuroraMemory m) async {
    final actions = ref.read(auroraMemoryActionsProvider);
    await actions.delete(m.id);
    if (!context.mounted) return;
    AtlasToast.undo(context, 'Forgotten', onUndo: () => actions.restore(m));
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, AuroraMemory m) async {
    final choice = await showActionSheet<bool>(
      context,
      title: m.content,
      actions: const [
        SheetAction(value: true, label: 'Forget this', icon: Symbols.delete_rounded, destructive: true),
      ],
    );
    if (choice == true && context.mounted) await _forget(context, ref, m);
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final ok = await confirmSheet(
      context,
      title: 'Forget everything?',
      body: 'Aurora will forget every memory on this list. This can’t be undone.',
      confirmLabel: 'Forget everything',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(auroraMemoryActionsProvider).clearAll();
    HapticFeedback.mediumImpact();
    if (context.mounted) AtlasToast.success(context, 'Aurora has forgotten everything');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(auroraMemoriesProvider);
    final list = async.value ?? const <AuroraMemory>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Text(
              list.isEmpty ? 'NOTHING YET' : '${list.length} ${list.length == 1 ? 'THING' : 'THINGS'}',
              style: AppTypography.kicker.copyWith(color: p.textMuted),
            ),
          ),
          PillButton(
            label: 'Add your own',
            icon: Symbols.add_rounded,
            height: 40,
            haptic: PressHaptic.selection,
            onTap: () => showAddMemorySheet(context),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        if (async.isLoading && list.isEmpty)
          const SkeletonList(count: 3)
        else if (list.isEmpty)
          const EmptyState(
            title: 'Aurora hasn’t saved anything yet.',
            body: 'When she offers to remember something in a chat, tap Save. Or add a '
                'line of your own.',
          )
        else ...[
          for (var i = 0; i < list.length; i++)
            Padding(
              key: ValueKey('memory-${list[i].id}'),
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EntryFade(
                id: 'memory-${list[i].id}',
                index: i,
                child: AtlasRow(
                  leading: IconTile(
                    style: list[i].source == AuroraMemorySource.aurora.wire
                        ? const CategoryStyle(Symbols.auto_awesome_rounded, AppColors.violet)
                        : const CategoryStyle(Symbols.person_rounded, AppColors.sky),
                    size: 40,
                  ),
                  title: list[i].content,
                  titleMaxLines: 6,
                  meta: _meta(list[i]),
                  swipeLeftLabel: 'Forget',
                  onSwipeLeft: () => _forget(context, ref, list[i]),
                  onLongPress: () => _menu(context, ref, list[i]),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          const SettingsFootnote('Swipe left or press and hold to forget one.'),
          settingsGap,
          LinkRow(
            icon: Symbols.delete_sweep_rounded,
            label: 'Forget everything',
            destructive: true,
            trailing: const SizedBox.shrink(),
            onTap: () => _clearAll(context, ref),
          ),
        ],
      ],
    );
  }

  static String _meta(AuroraMemory m) {
    final from = m.source == AuroraMemorySource.aurora.wire ? 'Saved from a chat' : 'Added by you';
    return '$from · ${m.createdAt.day} ${monthShort(m.createdAt)}';
  }
}

/// "Add your own": one line Aurora should keep in mind, up to 200 characters.
Future<void> showAddMemorySheet(BuildContext context) =>
    showAtlasSheet<void>(context, builder: (_) => const AddMemorySheet());

class AddMemorySheet extends ConsumerStatefulWidget {
  const AddMemorySheet({super.key});

  @override
  ConsumerState<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends ConsumerState<AddMemorySheet> {
  final _input = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _input.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    await ref.read(auroraMemoryActionsProvider).add(text);
    if (!mounted) return;
    nav.pop();
    AtlasToast.success(context, 'Aurora will remember that');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Something to remember',
              style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text('Write it the way you would tell a friend.',
              style: AppTypography.meta.copyWith(color: p.textMuted)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            decoration: BoxDecoration(
              color: p.paper,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
            ),
            child: TextField(
              controller: _input,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              maxLength: AuroraMemoryRepository.maxLength,
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.sans(size: 15, height: 1.5, color: p.textPrimary),
              decoration: InputDecoration(
                hintText: 'Training for a 10k in December',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                counterStyle: AppTypography.meta.copyWith(color: p.textMuted),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _input,
            builder: (context, v, _) => PillButton(
              label: 'Save',
              height: 56,
              expand: true,
              busy: _saving,
              haptic: PressHaptic.medium,
              onTap: v.text.trim().isEmpty || _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
