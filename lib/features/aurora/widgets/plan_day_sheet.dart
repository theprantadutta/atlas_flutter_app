import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/aurora/data/aurora_models.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// "Plan my day" (premium): say how much energy you have, and Aurora picks
/// two to four things for today from your own habits and tasks. Picks can be
/// tended right here; nothing is changed automatically. Opened from the
/// Aurora screen (and Home).
Future<void> showPlanDaySheet(BuildContext context) {
  ProviderScope.containerOf(context, listen: false).read(planDayProvider.notifier).reset();
  return showAtlasSheet<void>(context, builder: (_) => const PlanDaySheet());
}

extension on AuroraEnergy {
  String get label => switch (this) {
        AuroraEnergy.low => 'Low',
        AuroraEnergy.steady => 'Steady',
        AuroraEnergy.high => 'High',
      };

  String get blurb => switch (this) {
        AuroraEnergy.low => 'Go easy',
        AuroraEnergy.steady => 'A normal day',
        AuroraEnergy.high => 'Bring it on',
      };

  IconData get icon => switch (this) {
        AuroraEnergy.low => Symbols.battery_2_bar_rounded,
        AuroraEnergy.steady => Symbols.battery_5_bar_rounded,
        AuroraEnergy.high => Symbols.bolt_rounded,
      };
}

class PlanDaySheet extends ConsumerStatefulWidget {
  const PlanDaySheet({super.key});

  @override
  ConsumerState<PlanDaySheet> createState() => _PlanDaySheetState();
}

class _PlanDaySheetState extends ConsumerState<PlanDaySheet> {
  final _note = TextEditingController();
  AuroraEnergy _energy = AuroraEnergy.steady;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _plan() async {
    FocusScope.of(context).unfocus();
    await ref.read(planDayProvider.notifier).request(energy: _energy, note: _note.text);
  }

  void _openPaywall() {
    final router = GoRouter.maybeOf(context);
    ref.read(planDayProvider.notifier).clearPaywall();
    Navigator.of(context).pop();
    router?.push('/paywall');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planDayProvider);
    ref.listen(planDayProvider.select((s) => s.needsPaywall), (_, hit) {
      if (hit) _openPaywall();
    });

    final Widget body;
    if (state.loading) {
      body = const _Thinking(key: ValueKey('loading'));
    } else if (state.plan != null) {
      body = _PlanResult(
        key: const ValueKey('result'),
        plan: state.plan!,
        onAgain: () => ref.read(planDayProvider.notifier).reset(),
      );
    } else {
      body = _Picker(
        key: const ValueKey('picker'),
        energy: _energy,
        note: _note,
        error: state.error,
        onEnergy: (e) => setState(() => _energy = e),
        onPlan: _plan,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
      child: AnimatedSwitcher(
        duration: AppMotion.reduceMotion(context) ? Duration.zero : AppMotion.fast,
        child: body,
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    super.key,
    required this.energy,
    required this.note,
    required this.error,
    required this.onEnergy,
    required this.onPlan,
  });

  final AuroraEnergy energy;
  final TextEditingController note;
  final String? error;
  final ValueChanged<AuroraEnergy> onEnergy;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Plan my day', style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('How much do you have in you today?',
              style: AppTypography.body.copyWith(color: p.textMuted)),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          for (final e in AuroraEnergy.values) ...[
            if (e != AuroraEnergy.low) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _EnergyTile(energy: e, selected: e == energy, onTap: () => onEnergy(e)),
            ),
          ],
        ]),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
          ),
          child: TextField(
            controller: note,
            minLines: 1,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.sans(size: 15, color: p.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Anything Aurora should know? (optional)',
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          ErrorRow(message: error!, onRetry: onPlan),
        ],
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Plan my day',
          icon: Symbols.wb_sunny_rounded,
          height: 56,
          expand: true,
          haptic: PressHaptic.medium,
          onTap: onPlan,
        ),
      ],
    );
  }
}

class _EnergyTile extends StatelessWidget {
  const _EnergyTile({required this.energy, required this.selected, required this.onTap});

  final AuroraEnergy energy;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onAction : p.textPrimary;
    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      semanticLabel: '${energy.label} energy, ${energy.blurb}',
      child: Semantics(
        selected: selected,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected ? p.action : p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtlasIcon(energy.icon, size: 22, filled: true, color: fg),
              const SizedBox(height: AppSpacing.xs),
              Text(energy.label, style: AppTypography.rowTitle.copyWith(color: fg)),
              Text(energy.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.meta.copyWith(
                      color: selected ? p.onAction.withValues(alpha: .72) : p.textMuted)),
            ],
          ),
        ),
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
          Text('Aurora is looking at your day',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: p.textMuted)),
        ],
      ),
    );
  }
}

/// A local item a pick or a set-aside id points at.
typedef _Item = ({Habit? habit, Task? task});

class _PlanResult extends ConsumerWidget {
  const _PlanResult({super.key, required this.plan, required this.onAgain});

  final AuroraDayPlan plan;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final habits = ref.watch(habitsStreamProvider).value ?? const <Habit>[];
    final tasks = ref.watch(tasksStreamProvider).value ?? const <Task>[];

    _Item? find(String kind, String id) {
      if (kind != 'task') {
        for (final h in habits) {
          if (h.id == id && !h.isDeleted) return (habit: h, task: null);
        }
      }
      if (kind != 'habit') {
        for (final t in tasks) {
          if (t.id == id && !t.isDeleted) return (habit: null, task: t);
        }
      }
      return null;
    }

    // Anything deleted since Aurora answered (or never local) is skipped.
    final picks = [
      for (final pick in plan.picks)
        if (find(pick.kind, pick.id) case final item?) (pick: pick, item: item),
    ];
    final later = [
      for (final id in plan.later) ?find('any', id),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
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
                child: Text(
                  plan.message.isEmpty ? 'Here is a gentle shape for today.' : plan.message,
                  style: AppTypography.body.copyWith(color: p.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (picks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: AppSpacing.xs),
            child: Text('No picks today. A lighter day counts too.',
                style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
          )
        else ...[
          const SectionTitle('For today', padding: EdgeInsets.symmetric(horizontal: 4)),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < picks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EntryFade(
                id: 'pick-${picks[i].pick.id}',
                index: i,
                child: _PickRow(
                  key: ValueKey('pick-${picks[i].pick.id}'),
                  item: picks[i].item,
                  reason: picks[i].pick.reason,
                ),
              ),
            ),
        ],
        if (later.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const SectionTitle('Set aside for today', padding: EdgeInsets.symmetric(horizontal: 4)),
          const SizedBox(height: AppSpacing.xs),
          for (final item in later)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Row(children: [
                AtlasIcon(Symbols.bedtime_rounded, size: 18, color: p.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(item.habit?.title ?? item.task!.title,
                      style: AppTypography.sans(size: 14, weight: FontWeight.w600, color: p.textMuted)),
                ),
              ]),
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Plan again',
          variant: PillVariant.track,
          height: 52,
          expand: true,
          haptic: PressHaptic.selection,
          onTap: onAgain,
        ),
      ],
    );
  }
}

/// One pick: the item, Aurora's reason, and a check you can tend from here.
class _PickRow extends ConsumerStatefulWidget {
  const _PickRow({super.key, required this.item, required this.reason});

  final _Item item;
  final String? reason;

  @override
  ConsumerState<_PickRow> createState() => _PickRowState();
}

class _PickRowState extends ConsumerState<_PickRow> {
  final _checkKey = GlobalKey();

  bool get _done {
    final today = dateOnly(DateTime.now());
    final h = widget.item.habit, t = widget.item.task;
    if (h != null) {
      return h.isCompletedToday && HabitSchedule.doneInPeriod(h.frequency, h.lastCompletedDate, today);
    }
    return t!.isCompleted && TaskSchedule.doneInPeriod(t.type, t.lastCompletedDate, today);
  }

  Future<void> _tend() async {
    final tend = ref.read(tendControllerProvider);
    final h = widget.item.habit, t = widget.item.task;
    final outcome = h != null ? await tend.tendHabit(h) : await tend.tendTask(t!);
    if (outcome == null || !mounted) return;
    XpFloat.fromKey(context, _checkKey, outcome.xp);
    final level = outcome.leveledUpTo;
    if (level != null) HapticFeedback.mediumImpact();
    AtlasToast.undo(
      context,
      level != null
          ? 'Level $level. +${outcome.xp} XP'
          : '+${outcome.xp} XP · ${h?.title ?? t!.title}',
      onUndo: outcome.undo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.item.habit, t = widget.item.task;
    final title = h?.title ?? t!.title;
    final style = CategoryStyle.forItem(title: title, category: h?.category ?? t!.category);
    final done = _done;
    return AtlasRow(
      leading: IconTile(style: style),
      title: title,
      // Aurora's reason is the point of a pick, so it wraps instead of being
      // cut to one line like an ordinary row's meta. `meta` still carries it
      // for the row's spoken label.
      meta: widget.reason ?? (h != null ? 'Habit' : 'Task'),
      metaWidget: Text(
        widget.reason ?? (h != null ? 'Habit' : 'Task'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.meta.copyWith(color: context.palette.textMuted),
      ),
      titleMaxLines: 2,
      semanticsValue: done ? 'done' : 'not done',
      trailing: KeyedSubtree(
        key: _checkKey,
        child: CheckCircle(
          done: done,
          enabled: !done,
          semanticLabel: done ? '$title, done' : 'Tend $title',
          onTap: _tend,
        ),
      ),
      onSwipeRight: done ? null : _tend,
    );
  }
}
