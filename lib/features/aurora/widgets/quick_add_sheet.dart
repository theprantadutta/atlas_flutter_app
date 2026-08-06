import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/feedback/atlas_toast.dart';

/// Opens the quick-add sheet: natural-language capture with Aurora (premium)
/// plus manual add for everyone. Everything is created in local Drift.
Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const QuickAddSheet(),
  );
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
      AtlasToast.success(context, n == 1 ? 'Added 1 item' : 'Added $n items');
      Navigator.of(context).pop();
      ref.read(quickAddProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final qa = ref.watch(quickAddProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('Add something new',
                style: theme.textTheme.headlineSmall),
          ),

          // ── Aurora natural-language capture ──
          if (isPremium)
            _NlField(
              controller: _input,
              submitting: qa.submitting,
              error: qa.error,
              onSubmit: _submitNl,
            )
          else
            _PremiumNlTeaser(onTap: () {
              Navigator.of(context).pop();
              context.push('/paywall');
            }),

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: Divider(color: theme.colorScheme.outline)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('or add manually',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              Expanded(child: Divider(color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _ManualTile(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.categoryWork,
            title: 'New task',
            subtitle: 'A one-off to tend to',
            onTap: () => _manualAdd(_ManualKind.task),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ManualTile(
            icon: Icons.eco_outlined,
            color: AppColors.xpPrimary,
            title: 'New habit',
            subtitle: 'Something to nurture daily',
            onTap: () => _manualAdd(_ManualKind.habit),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ManualTile(
            icon: Icons.flag_outlined,
            color: AppColors.tertiary,
            title: 'New goal',
            subtitle: 'A horizon to grow toward',
            onTap: () => _manualAdd(_ManualKind.goal),
          ),
        ],
      ),
    );
  }

  Future<void> _manualAdd(_ManualKind kind) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _TitleDialog(kind: kind),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    final userId = ref.read(currentUserIdProvider);
    switch (kind) {
      case _ManualKind.task:
        await ref
            .read(taskActionsProvider)
            .create(userId: userId, title: title.trim());
      case _ManualKind.habit:
        await ref
            .read(habitActionsProvider)
            .create(userId: userId, title: title.trim());
      case _ManualKind.goal:
        await ref
            .read(goalActionsProvider)
            .create(userId: userId, title: title.trim());
    }
    if (!mounted) return;
    AtlasToast.success(context, 'Added ${kind.label}');
    Navigator.of(context).pop();
  }
}

enum _ManualKind {
  task('task'),
  habit('habit'),
  goal('goal');

  const _ManualKind(this.label);
  final String label;
}

// ─── Aurora NL field (premium) ──────────────────────────────────────

class _NlField extends StatelessWidget {
  const _NlField({
    required this.controller,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppColors.auroraLilac),
            const SizedBox(width: AppSpacing.xs),
            Text('Ask Aurora',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  autofocus: true,
                  enabled: !submitting,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'e.g. “read 20 pages on weekdays”',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: GestureDetector(
                  onTap: submitting ? null : onSubmit,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: submitting ? null : AppColors.auroraGradient,
                      color: submitting
                          ? theme.colorScheme.surfaceContainerHighest
                          : null,
                    ),
                    child: submitting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child:
                                CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Icon(Icons.arrow_upward_rounded,
                            color: Color(0xFF10243B)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}

class _PremiumNlTeaser extends StatelessWidget {
  const _PremiumNlTeaser({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const ink = Color(0xFF10243B);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: ink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add with Aurora',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: ink, fontWeight: FontWeight.w700)),
                    Text('Describe it in words — a premium touch',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: ink.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const Icon(Icons.lock_rounded, color: ink, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Manual add ─────────────────────────────────────────────────────

class _ManualTile extends StatelessWidget {
  const _ManualTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleDialog extends StatefulWidget {
  const _TitleDialog({required this.kind});
  final _ManualKind kind;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New ${widget.kind.label}'),
      content: TextField(
        controller: _c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(context).pop(v),
        decoration: const InputDecoration(hintText: 'Give it a name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_c.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
