import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// "Break it down with Aurora" (premium): three to five small steps for a
/// goal, all ticked by default. "Add selected" creates them as tasks in
/// local Drift (offline-first, dirty for sync).
Future<void> showGoalStepsSheet(BuildContext context, Goal goal) {
  ProviderScope.containerOf(context, listen: false).read(goalStepsProvider.notifier).reset();
  return showAtlasSheet<void>(context, builder: (_) => GoalStepsSheet(goal: goal));
}

String _typeLabel(String type) => switch (type) {
      'weekly' => 'Each week',
      'longTerm' => 'Once',
      _ => 'Every day',
    };

class GoalStepsSheet extends ConsumerStatefulWidget {
  const GoalStepsSheet({super.key, required this.goal});
  final Goal goal;

  @override
  ConsumerState<GoalStepsSheet> createState() => _GoalStepsSheetState();
}

class _GoalStepsSheetState extends ConsumerState<GoalStepsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(goalStepsProvider);
      if (s.goalId != widget.goal.id) _request();
    });
  }

  void _request() => ref.read(goalStepsProvider.notifier).request(widget.goal);

  Future<void> _add() async {
    final n = await ref.read(goalStepsProvider.notifier).addSelected();
    if (n > 0) HapticFeedback.mediumImpact();
  }

  void _openPaywall() {
    final router = GoRouter.maybeOf(context);
    ref.read(goalStepsProvider.notifier).reset();
    Navigator.of(context).pop();
    router?.push('/paywall');
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = ref.watch(goalStepsProvider);
    ref.listen(goalStepsProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit) _openPaywall();
    });

    final Widget body;
    if (s.added != null) {
      body = _Added(key: const ValueKey('added'), count: s.added!, onDone: _close);
    } else if (s.steps.isNotEmpty) {
      body = _Steps(
        key: const ValueKey('steps'),
        state: s,
        onToggle: (i) => ref.read(goalStepsProvider.notifier).toggle(i),
        onAdd: _add,
      );
    } else if (s.error != null) {
      body = ErrorRow(key: const ValueKey('error'), message: s.error!, onRetry: _request);
    } else if (!s.loading && s.goalId == widget.goal.id) {
      body = const Padding(
        key: ValueKey('empty'),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: EmptyState(title: 'Aurora couldn’t find steps this time.'),
      );
    } else {
      body = const _Thinking(key: ValueKey('loading'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Break it down',
                style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(widget.goal.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppMotion.reduceMotion(context) ? Duration.zero : AppMotion.fast,
            child: body,
          ),
        ],
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AtlasSpark(size: 56, animated: true, busy: true),
          const SizedBox(height: AppSpacing.md),
          Text('Aurora is finding small first steps',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: p.textMuted)),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({
    super.key,
    required this.state,
    required this.onToggle,
    required this.onAdd,
  });

  final GoalStepsState state;
  final ValueChanged<int> onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = state.selected.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if ((state.message ?? '').isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: p.letter,
              borderRadius: BorderRadius.circular(AppSpacing.radiusTile),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AtlasSpark(size: 26, animated: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(state.message!,
                      style: AppTypography.body.copyWith(color: p.textPrimary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (var i = 0; i < state.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: EntryFade(
              id: 'step-$i-${state.steps[i].title}',
              index: i,
              child: _StepRow(
                step: state.steps[i],
                selected: state.selected.contains(i),
                onTap: () => onToggle(i),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: n == 0
              ? 'Pick a step to add'
              : n == 1
                  ? 'Add 1 step'
                  : 'Add $n steps',
          icon: Symbols.add_task_rounded,
          height: 56,
          expand: true,
          busy: state.adding,
          haptic: PressHaptic.medium,
          onTap: n == 0 || state.adding ? null : onAdd,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('They are added to Grow as tasks. You can edit them there.',
            textAlign: TextAlign.center,
            style: AppTypography.meta.copyWith(color: p.textMuted)),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.selected, required this.onTap});

  final AuroraGoalStep step;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      checked: selected,
      child: AtlasRow(
        leading: IconTile(style: CategoryStyle.forItem(title: step.title, category: step.category)),
        title: step.title,
        meta: _typeLabel(step.type),
        onTap: onTap,
        trailing: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? p.action : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: selected ? p.action : p.outline, width: 2),
            ),
            child: selected
                ? AtlasIcon(Symbols.check_rounded, size: 18, weight: 700, color: p.onAction)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Added extends StatelessWidget {
  const _Added({super.key, required this.count, required this.onDone});

  final int count;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AtlasSpark(size: 64, animated: true)),
          const SizedBox(height: AppSpacing.md),
          Text(
            count == 1 ? 'Added 1 step to Grow.' : 'Added $count steps to Grow.',
            textAlign: TextAlign.center,
            style: AppTypography.section.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text('One small step at a time is still moving.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: p.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          PillButton(label: 'Done', height: 56, expand: true, onTap: onDone),
        ],
      ),
    );
  }
}
