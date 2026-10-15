import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/goals/providers/goal_providers.dart';
import 'package:atlas_flutter_app/features/grow/providers/grow_providers.dart';
import 'package:atlas_flutter_app/features/grow/widgets/item_actions.dart';
import 'package:atlas_flutter_app/features/grow/widgets/item_editor_sheet.dart';
import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/home/providers/home_prefs.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Grow: everything you're tending, in three tabs.
class GrowScreen extends ConsumerStatefulWidget {
  const GrowScreen({super.key});

  @override
  ConsumerState<GrowScreen> createState() => _GrowScreenState();
}

enum _Freq { all, daily, weekly }

class _GrowScreenState extends ConsumerState<GrowScreen> {
  int _tab = 1; // Habits first, like the design.
  bool _searching = false;
  final _search = TextEditingController();
  String _query = '';
  DateTime? _day; // null = today
  _Freq _freq = _Freq.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String title) =>
      _query.isEmpty || title.toLowerCase().contains(_query.toLowerCase());

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _search.clear();
        _query = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dailyRolloverProvider);
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final day = _day ?? today;

    final Widget body = switch (_tab) {
      0 => _TasksTab(key: const ValueKey('tasks'), matches: _matches),
      1 => _HabitsTab(
        key: const ValueKey('habits'),
        matches: _matches,
        day: day,
        today: today,
        freq: _freq,
        onFreq: () =>
            setState(() => _freq = _Freq.values[(_freq.index + 1) % 3]),
        onDay: (d) => setState(() => _day = isSameDay(d, today) ? null : d),
      ),
      _ => _GoalsTab(key: const ValueKey('goals'), matches: _matches),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SparkRefresh(
          onRefresh: () => refreshEverything(ref),
          child: ListView(
            physics: sparkRefreshPhysics,
            controller: ref.watch(tabScrollControllersProvider).of(1),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              navScrollPadding(context),
            ),
            children: [
              ScreenHeader(
                title: 'Grow',
                trailing: CircleIconButton(
                  icon: _searching
                      ? Symbols.close_rounded
                      : Symbols.search_rounded,
                  semanticLabel: _searching ? 'Close search' : 'Search',
                  onTap: _toggleSearch,
                ),
              ),
              AnimatedSize(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                child: _searching
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: TextField(
                          controller: _search,
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v.trim()),
                          style: AppTypography.sans(
                            size: 15,
                            color: p.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search tasks, habits and goals',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 8,
                              ),
                              child: AtlasIcon(
                                Symbols.search_rounded,
                                size: 20,
                                color: p.textMuted,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 44,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedPill(
                labels: const ['Tasks', 'Habits', 'Goals'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                switchInCurve: AppMotion.standard,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Habits ─────────────────────────────────────────────────────────

class _HabitsTab extends ConsumerWidget {
  const _HabitsTab({
    super.key,
    required this.matches,
    required this.day,
    required this.today,
    required this.freq,
    required this.onFreq,
    required this.onDay,
  });

  final bool Function(String) matches;
  final DateTime day;
  final DateTime today;
  final _Freq freq;
  final VoidCallback onFreq;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final days = ref.watch(ledgerDaysProvider);
    final week = ref.watch(weekStripProvider);
    final isToday = isSameDay(day, today);

    final all = habitsAsync.value ?? const <Habit>[];
    final habits =
        all.where((h) {
          if (!matches(h.title)) return false;
          final weekly = HabitSchedule.isWeekly(h.frequency);
          if (freq == _Freq.daily && weekly) return false;
          if (freq == _Freq.weekly && !weekly) return false;
          if (!isToday && dateOnly(h.createdAt).isAfter(day)) return false;
          return weekly || HabitSchedule.isScheduledOn(h.frequency, day);
        }).toList()..sort((a, b) {
          final ad = habitDoneOn(a, day, today, days),
              bd = habitDoneOn(b, day, today, days);
          // Done ones first, like a filled week.
          if (ad != bd) return ad ? -1 : 1;
          return a.createdAt.compareTo(b.createdAt);
        });
    final done = habits.where((h) => habitDoneOn(h, day, today, days)).length;
    final label = isToday ? 'Today' : weekdayName(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekStrip(days: week, selected: day, today: today, onTap: onDay),
        const SizedBox(height: AppSpacing.md),
        SectionTitle(
          habits.isEmpty ? label : '$label · $done of ${habits.length}',
          action: switch (freq) {
            _Freq.all => 'All',
            _Freq.daily => 'Daily',
            _Freq.weekly => 'Weekly',
          },
          onAction: onFreq,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (habitsAsync.isLoading && all.isEmpty)
          const SkeletonList(height: AppSpacing.habitRowHeight)
        else if (habits.isEmpty)
          EmptyState(
            title: all.isEmpty ? 'No habits yet.' : 'Nothing here.',
            body: all.isEmpty
                ? 'Start with one small thing you want to come back to.'
                : null,
            actionLabel: all.isEmpty ? 'Add a habit' : null,
            onAction: () => showItemEditor(context, kind: ItemKind.habit),
          )
        else
          for (var i = 0; i < habits.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EntryFade(
                id: 'habit-${habits[i].id}',
                index: i,
                child: _HabitRow(
                  habit: habits[i],
                  day: day,
                  today: today,
                  days: days,
                ),
              ),
            ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final List<WeekDay> days;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selIndex = days.indexWhere((d) => isSameDay(d.date, selected));
    return AtlasTile(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < days.length; i++)
                Pressable(
                  onTap: days[i].isFuture ? null : () => onTap(days[i].date),
                  haptic: PressHaptic.selection,
                  circle: true,
                  semanticLabel:
                      '${weekdayName(days[i].date)} ${days[i].date.day}, ${(days[i].value * 100).round()} percent',
                  child: Column(
                    children: [
                      Text(
                        weekdayLetter(days[i].date),
                        style: AppTypography.dayLabel.copyWith(
                          color: isSameDay(days[i].date, today)
                              ? AtlasPalette.accent
                              : p.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: days[i].isFuture ? .6 : 1,
                        child: DayRing(
                          value: days[i].value,
                          label: '${days[i].date.day}',
                          delay: AppMotion.listStagger * i,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // The 2px ink underline under the selected day.
          SizedBox(
            height: 2,
            child: LayoutBuilder(
              builder: (context, c) {
                final slot = (c.maxWidth - 34) / 6;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: AppMotion.reduceMotion(context)
                          ? Duration.zero
                          : AppMotion.medium,
                      curve: AppMotion.emphasized,
                      left: selIndex < 0 ? 0 : selIndex * slot + 7,
                      width: 20,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.textPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({
    required this.habit,
    required this.day,
    required this.today,
    required this.days,
  });

  final Habit habit;
  final DateTime day;
  final DateTime today;
  final List<LedgerDay> days;

  Future<void> _tend(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(tendControllerProvider).tendHabit(habit);
    if (outcome == null || !context.mounted) return;
    final level = outcome.leveledUpTo;
    AtlasToast.undo(
      context,
      level != null
          ? 'Level $level. +${outcome.xp} XP'
          : '+${outcome.xp} XP · ${habit.title}',
      onUndo: outcome.undo,
    );
  }

  Future<void> _untend(WidgetRef ref) =>
      ref.read(tendControllerProvider).untendHabit(habit, days);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = CategoryStyle.forItem(
      title: habit.title,
      category: habit.category,
    );
    final isToday = isSameDay(day, today);
    final done = habitDoneOn(habit, day, today, days);
    final week = habitWeek(habit, day, today, days);
    final streakAlive = HabitSchedule.streakAlive(
      habit.frequency,
      habit.lastCompletedDate,
      today,
    );
    final streak = streakAlive ? habit.streakCount : 0;
    final time = parseHm(habit.reminderTime);
    final unit = HabitSchedule.isWeekly(habit.frequency) ? 'week' : 'day';
    final meta = !isToday
        ? (done ? 'Done' : 'Not this day')
        : (done || time == null)
        ? (streak > 0
              ? '$streak $unit streak'
              : HabitSchedule.isWeekly(habit.frequency)
              ? 'Once this week'
              : '+${GamificationConstants.calculateHabitXp(difficulty: habit.difficulty)} XP')
        : clockLabel(time.hour, time.minute);

    return AtlasRow(
      minHeight: AppSpacing.habitRowHeight,
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      leading: IconTile(style: style, size: 44),
      title: habit.title,
      metaWidget: AnimatedSwitcher(
        duration: AppMotion.fast,
        child: Text(
          meta,
          key: ValueKey(meta),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.meta.copyWith(color: context.palette.textMuted),
        ),
      ),
      semanticsValue: done ? 'done' : 'not done',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Sparkline7(
            days: week,
            color: style.fg(context),
            seed: habit.id,
            dayKeys: [for (var i = 6; i >= 0; i--) dayKey(addDays(day, -i))],
          ),
          CheckCircle(
            done: done,
            enabled: isToday,
            semanticLabel: '${habit.title}, ${done ? 'done' : 'not done'}',
            onTap: () => done ? _untend(ref) : _tend(context, ref),
          ),
        ],
      ),
      onTap: () => showItemEditor(context, habit: habit),
      onLongPress: () => showItemMenu(context, ref, habit: habit),
      onSwipeRight: isToday && !done ? () => _tend(context, ref) : null,
      onSwipeLeft: isToday && !done
          ? () {
              ref.read(snoozeProvider.notifier).skipToday(habit.id);
              HapticFeedback.selectionClick();
              AtlasToast.undo(
                context,
                'Skipped for today',
                onUndo: () => ref.read(snoozeProvider.notifier).clear(habit.id),
              );
            }
          : null,
      swipeLeftLabel: 'Skip today',
    );
  }
}

// ─── Tasks ──────────────────────────────────────────────────────────

class _TasksTab extends ConsumerWidget {
  const _TasksTab({super.key, required this.matches});
  final bool Function(String) matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksStreamProvider);
    final today = ref.watch(todayProvider);
    final all = (async.value ?? const <Task>[])
        .where((t) => matches(t.title))
        .toList();

    bool isDone(Task t) =>
        t.isCompleted &&
        TaskSchedule.doneInPeriod(t.type, t.lastCompletedDate, today);

    List<Task> group(bool Function(Task) test) =>
        all.where(test).toList()..sort((a, b) {
          if (isDone(a) != isDone(b)) return isDone(a) ? 1 : -1;
          final ad = a.dueDate, bd = b.dueDate;
          if (ad != null && bd != null) return ad.compareTo(bd);
          if (ad != null) return -1;
          if (bd != null) return 1;
          return a.createdAt.compareTo(b.createdAt);
        });

    final groups = [
      ('Daily', group((t) => t.type == 'daily')),
      ('Weekly', group((t) => t.type == 'weekly')),
      ('Long-term', group((t) => t.type != 'daily' && t.type != 'weekly')),
    ].where((g) => g.$2.isNotEmpty).toList();

    if (async.isLoading && all.isEmpty) return const SkeletonList();
    if (groups.isEmpty) {
      return EmptyState(
        title: (async.value ?? const []).isEmpty
            ? 'No tasks yet.'
            : 'Nothing matches.',
        body: (async.value ?? const []).isEmpty
            ? 'Add the next small thing you want done.'
            : null,
        actionLabel: (async.value ?? const []).isEmpty ? 'Add a task' : null,
        onAction: () => showItemEditor(context, kind: ItemKind.task),
      );
    }

    var index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, tasks) in groups) ...[
          SectionTitle(
            '$label · ${tasks.where(isDone).length} of ${tasks.length}',
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EntryFade(
                id: 'task-${t.id}',
                index: index++,
                child: _TaskRow(task: t, done: isDone(t)),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.done});
  final Task task;
  final bool done;

  Future<void> _tend(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(tendControllerProvider).tendTask(task);
    if (outcome == null || !context.mounted) return;
    final level = outcome.leveledUpTo;
    AtlasToast.undo(
      context,
      level != null
          ? 'Level $level. +${outcome.xp} XP'
          : 'Done · +${outcome.xp} XP',
      onUndo: outcome.undo,
    );
  }

  String _meta(DateTime today) {
    if (done) {
      return task.type == 'daily' ? 'Done today' : 'Done';
    }
    final due = task.dueDate;
    final xp = '+${task.xpReward} XP';
    if (due == null) return xp;
    final hasTime = due.hour != 0 || due.minute != 0;
    final diff = daysBetween(today, due);
    final when = diff == 0
        ? (hasTime ? clockLabel(due.hour, due.minute) : 'Today')
        : diff == 1
        ? 'Tomorrow'
        : diff < 0
        ? 'Waiting since ${due.day} ${monthShort(due)}'
        : diff < 7
        ? weekdayName(due)
        : '${due.day} ${monthShort(due)}';
    return '$when · $xp';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final style = CategoryStyle.forItem(
      title: task.title,
      category: task.category,
    );
    return AtlasRow(
      minHeight: AppSpacing.habitRowHeight,
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      leading: IconTile(style: style, size: 44),
      title: task.title,
      meta: _meta(today),
      semanticsValue: done ? 'done' : 'not done',
      trailing: CheckCircle(
        done: done,
        semanticLabel: '${task.title}, ${done ? 'done' : 'not done'}',
        onTap: () => done
            ? ref.read(tendControllerProvider).untendTask(task)
            : _tend(context, ref),
      ),
      onTap: () => showItemEditor(context, task: task),
      onLongPress: () => showItemMenu(context, ref, task: task),
      onSwipeRight: done ? null : () => _tend(context, ref),
      onSwipeLeft: done
          ? null
          : () {
              ref.read(snoozeProvider.notifier).skipToday(task.id);
              AtlasToast.undo(
                context,
                'Skipped for today',
                onUndo: () => ref.read(snoozeProvider.notifier).clear(task.id),
              );
            },
      swipeLeftLabel: 'Skip today',
    );
  }
}

// ─── Goals ──────────────────────────────────────────────────────────

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab({super.key, required this.matches});
  final bool Function(String) matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalsStreamProvider);
    final all = async.value ?? const <Goal>[];
    final goals =
        all.where((g) => matches(g.title) && g.status != 'cancelled').toList()
          ..sort((a, b) {
            final ad = a.progress >= 1, bd = b.progress >= 1;
            if (ad != bd) return ad ? 1 : -1;
            final adl = a.deadline, bdl = b.deadline;
            if (adl != null && bdl != null) return adl.compareTo(bdl);
            if (adl != null) return -1;
            if (bdl != null) return 1;
            return a.createdAt.compareTo(b.createdAt);
          });

    if (async.isLoading && all.isEmpty) return const SkeletonList(height: 132);
    if (goals.isEmpty) {
      return EmptyState(
        title: all.isEmpty ? 'No goals yet.' : 'Nothing matches.',
        body: all.isEmpty
            ? 'Pick somewhere you’d like to be in a few months.'
            : null,
        actionLabel: all.isEmpty ? 'Add a goal' : null,
        onAction: () => showItemEditor(context, kind: ItemKind.goal),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < goals.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: EntryFade(
              id: 'goal-${goals[i].id}',
              index: i,
              child: _GoalCard(goal: goals[i]),
            ),
          ),
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final style = CategoryStyle.forItem(
      title: goal.title,
      category: goal.category,
    );
    final pct = (goal.progress * 100).round();
    final complete = goal.progress >= 1;
    final deadline = goal.deadline;
    String target;
    if (complete) {
      final c = goal.completedAt;
      target = c == null ? 'Complete' : 'Reached ${c.day} ${monthShort(c)}';
    } else if (deadline == null) {
      target = 'No target date';
    } else {
      final d = daysBetween(today, deadline);
      target = d < 0
          ? 'Target was ${deadline.day} ${monthShort(deadline)}'
          : d == 0
          ? 'Target · today'
          : d < 14
          ? 'Target · in $d ${d == 1 ? 'day' : 'days'}'
          : 'Target · in ${(d / 7).round()} weeks';
    }
    final status = complete
        ? 'Complete'
        : pct == 0
        ? 'Not started'
        : 'In progress';

    return Pressable(
      onTap: () => showGoalProgressSheet(context, ref, goal),
      onLongPress: () => showItemMenu(context, ref, goal: goal),
      semanticLabel: '${goal.title}, $status, $pct percent, $target',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconTile(style: style, size: 38),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.rowTitle.copyWith(
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AtlasChip(
                  label: status,
                  dense: true,
                  background: complete ? p.successBg : p.track,
                  foreground: complete ? p.success : p.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CountUpText(
                  value: pct,
                  suffix: '%',
                  style: AppTypography.cardNumber.copyWith(
                    color: p.textPrimary,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    target,
                    style: AppTypography.meta.copyWith(color: p.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GradientBar(
              value: goal.progress,
              gradient: AppColors.sunriseBar,
              sheen: complete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Set a goal's progress precisely (replaces the old fixed +25% tap).
Future<void> showGoalProgressSheet(
  BuildContext context,
  WidgetRef ref,
  Goal goal,
) async {
  await showAtlasSheet<void>(
    context,
    builder: (_) => _GoalProgressSheet(goal: goal),
  );
}

class _GoalProgressSheet extends ConsumerStatefulWidget {
  const _GoalProgressSheet({required this.goal});
  final Goal goal;

  @override
  ConsumerState<_GoalProgressSheet> createState() => _GoalProgressSheetState();
}

class _GoalProgressSheetState extends ConsumerState<_GoalProgressSheet> {
  late double _value = widget.goal.progress;

  Future<void> _save() async {
    final nav = Navigator.of(context);
    final outcome = await ref
        .read(tendControllerProvider)
        .setGoalProgress(widget.goal, _value);
    nav.pop();
    if (!mounted) return;
    if (outcome != null) {
      HapticFeedback.heavyImpact();
      AtlasToast.undo(
        context,
        'Goal reached · +${outcome.xp} XP',
        onUndo: outcome.undo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = (_value * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.goal.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.section.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$pct',
                  style: AppTypography.statNumber.copyWith(
                    color: p.textPrimary,
                  ),
                ),
                GradientText('%', style: AppTypography.statNumber),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: _value,
            divisions: 20,
            onChanged: (v) {
              if ((v * 20).round() != (_value * 20).round()) {
                HapticFeedback.selectionClick();
              }
              setState(() => _value = v);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final v in [0.25, 0.5, 0.75, 1.0])
                ChoiceChipPill(
                  label: v == 1.0 ? 'Done' : '${(v * 100).round()}%',
                  selected: (_value - v).abs() < .001,
                  onTap: () => setState(() => _value = v),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: _value >= 1 && widget.goal.progress < 1
                ? 'Mark as reached'
                : 'Save',
            variant: _value >= 1 && widget.goal.progress < 1
                ? PillVariant.gradient
                : PillVariant.action,
            height: 56,
            expand: true,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}
