import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/grow/widgets/item_editor_sheet.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Opens the quick-add sheet: describe it to Aurora (premium), or add a
/// task, habit or goal by hand. Everything is created in local Drift.
Future<void> showQuickAddSheet(BuildContext context) {
  return showAtlasSheet<void>(context, builder: (_) => const QuickAddSheet());
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submitNl() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(quickAddProvider.notifier).submit(text);
    if (!mounted) return;
    final state = ref.read(quickAddProvider);
    if (state.needsPaywall) {
      Navigator.of(context).pop();
      context.push('/paywall');
      ref.read(quickAddProvider.notifier).reset();
      return;
    }
    if (ok) {
      final n = state.result?.created.length ?? 0;
      AtlasToast.success(
          context, n == 1 ? 'Added 1 thing to Grow' : 'Added $n things to Grow');
      Navigator.of(context).pop();
      ref.read(quickAddProvider.notifier).reset();
    }
  }

  Future<void> _manual(ItemKind kind) async {
    final nav = Navigator.of(context);
    final rootContext = nav.context;
    nav.pop();
    await showItemEditor(rootContext, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isPremium = ref.watch(isPremiumProvider);
    final qa = ref.watch(quickAddProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Add something',
                style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isPremium)
            _AuroraInput(
              controller: _input,
              submitting: qa.submitting,
              onSubmit: _submitNl,
            )
          else
            _AuroraTeaser(onTap: () {
              Navigator.of(context).pop();
              context.push('/paywall');
            }),
          if (qa.error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ErrorRow(message: qa.error!, onRetry: _submitNl),
          ],
          const SizedBox(height: AppSpacing.lg - 4),
          Row(children: [
            Expanded(child: Divider(color: p.hairline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('or add manually',
                  style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
            ),
            Expanded(child: Divider(color: p.hairline)),
          ]),
          const SizedBox(height: AppSpacing.lg - 4),
          _ManualRow(
            style: const CategoryStyle(Symbols.task_alt_rounded, AppColors.sky),
            title: 'New task',
            subtitle: 'Something to get done',
            onTap: () => _manual(ItemKind.task),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ManualRow(
            style: const CategoryStyle(Symbols.repeat_rounded, AppColors.leaf),
            title: 'New habit',
            subtitle: 'Something to come back to',
            onTap: () => _manual(ItemKind.habit),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ManualRow(
            style: const CategoryStyle(Symbols.flag_rounded, AppColors.amber),
            title: 'New goal',
            subtitle: 'Somewhere you’re heading',
            onTap: () => _manual(ItemKind.goal),
          ),
        ],
      ),
    );
  }
}

/// The Aurora input: a 56 paper pill with the spark, and a gradient send.
class _AuroraInput extends StatelessWidget {
  const _AuroraInput({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          AtlasSpark(size: 22, busy: submitting),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              autofocus: true,
              enabled: !submitting,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              style: AppTypography.sans(size: 15, color: p.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. read 20 pages on weekdays',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SendButton(onTap: submitting ? null : onSubmit, size: 44),
        ],
      ),
    );
  }
}

/// The round sunrise send button (quick add, chat composer).
class SendButton extends StatelessWidget {
  const SendButton({super.key, required this.onTap, this.size = 54});
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        circle: true,
        haptic: PressHaptic.light,
        semanticLabel: 'Send',
        child: AnimatedOpacity(
          duration: AppMotion.instant,
          opacity: onTap == null ? .5 : 1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.sunrise,
              boxShadow: size >= 54 ? AppColors.fabShadow : null,
            ),
            child: const AtlasIcon(Symbols.arrow_upward_rounded,
                color: AppColors.white, size: 24, weight: 600),
          ),
        ),
      );
}

/// For free users: what Aurora can do here, and where to unlock it.
class _AuroraTeaser extends StatelessWidget {
  const _AuroraTeaser({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AtlasTile(
      gradient: p.letter,
      onTap: onTap,
      semanticLabel: 'Add with Aurora. Premium.',
      child: Row(
        children: [
          const AtlasSpark(size: 30, animated: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Just say it to Aurora',
                    style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text('Describe it in words and she sets it up. Premium.',
                    style: AppTypography.meta.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          AtlasIcon(Symbols.arrow_forward_rounded, size: 20, color: p.textMuted),
        ],
      ),
    );
  }
}

class _ManualRow extends StatelessWidget {
  const _ManualRow({
    required this.style,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final CategoryStyle style;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtlasRow(
        leading: IconTile(style: style),
        title: title,
        meta: subtitle,
        onTap: onTap,
        trailing: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: AtlasIcon(Symbols.arrow_forward_rounded,
              size: 20, color: context.palette.chevron),
        ),
      );
}
