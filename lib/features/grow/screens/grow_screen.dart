import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/sample/sample_grow.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// The Grow hub — one calm home for Tasks, Habits and Goals.
class GrowScreen extends ConsumerStatefulWidget {
  const GrowScreen({super.key});

  @override
  ConsumerState<GrowScreen> createState() => _GrowScreenState();
}

class _GrowScreenState extends ConsumerState<GrowScreen> {
  int _segment = 0;

  void _comingSoon(String what) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(what)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.bottomNavSpace),
          children: [
            AtlasHeader(
              title: 'Grow',
              subtitle: 'Small steps, every day',
              trailing: CircleActionButton(
                icon: Icons.add_rounded,
                onTap: () => _comingSoon('Add coming soon'),
              ),
            ),
            AppSpacing.gapLg,
            SegmentedTabs(
              labels: const ['Tasks', 'Habits', 'Goals'],
              index: _segment,
              onChanged: (i) => setState(() => _segment = i),
            ),
            AppSpacing.gapLg,
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: switch (_segment) {
                0 => const _TasksView(key: ValueKey('tasks')),
                1 => const _HabitsView(key: ValueKey('habits')),
                _ => const _GoalsView(key: ValueKey('goals')),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tasks ──────────────────────────────────────────────────────────

class _TasksView extends ConsumerWidget {
  const _TasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    const cadences = ['Daily', 'Weekly', 'Long-term'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final cadence in cadences) ...[
          if (tasks.any((t) => t.cadence == cadence)) ...[
            SectionHeader(title: cadence),
            ...tasks.where((t) => t.cadence == cadence).map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TaskRow(
                      task: t,
                      onTap: () =>
                          ref.read(tasksProvider.notifier).toggle(t.id),
                    ),
                  ),
                ),
            AppSpacing.gapXs,
          ],
        ],
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onTap});
  final SampleTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.done;
    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          _IconTile(icon: task.icon, color: task.color, dim: done),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  done ? 'Done · +${task.xp} XP' : task.note,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _Check(done: done, color: task.color),
        ],
      ),
    );
  }
}

// ─── Habits ─────────────────────────────────────────────────────────

class _HabitsView extends ConsumerWidget {
  const _HabitsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final doneToday = habits.where((h) => h.doneToday).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtlasCard(
          child: Row(
            children: [
              ProgressRing(
                progress: habits.isEmpty ? 0 : doneToday / habits.length,
                size: 56,
                stroke: 6,
                child: Text('$doneToday/${habits.length}',
                    style: Theme.of(context).textTheme.labelMedium),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s habits',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Keep your streaks alive',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        ...habits.map(
          (h) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _HabitRow(
              habit: h,
              onTap: () => ref.read(habitsProvider.notifier).toggle(h.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.onTap});
  final SampleHabit habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              _IconTile(icon: habit.icon, color: habit.color, dim: !habit.doneToday),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: theme.textTheme.titleMedium),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppColors.streakFlame),
                        const SizedBox(width: 3),
                        Text('${habit.streak} day streak · ${habit.frequency}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              _Check(done: habit.doneToday, color: habit.color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < habit.week.length; i++)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: habit.week[i]
                        ? habit.color.withValues(alpha: 0.9)
                        : theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  child: habit.week[i]
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: Colors.white)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Goals ──────────────────────────────────────────────────────────

class _GoalsView extends ConsumerWidget {
  const _GoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _GoalCard(goal: g),
          ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final SampleGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = goal.status == 'Completed';
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: goal.icon, color: goal.color, dim: done),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(goal.title, style: theme.textTheme.titleMedium),
              ),
              _StatusChip(status: goal.status, color: goal.color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AtlasProgressBar(
                  fraction: goal.progress,
                  color: done ? AppColors.success : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${(goal.progress * 100).round()}%',
                  style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Target · ${goal.dueLabel}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = switch (status) {
      'Completed' => AppColors.success,
      'Due soon' => AppColors.streakFlame,
      _ => color,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(status,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: c, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Shared bits ────────────────────────────────────────────────────

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color, this.dim = false});
  final IconData icon;
  final Color color;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dim ? 0.10 : 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(icon, color: color.withValues(alpha: dim ? 0.6 : 1), size: 22),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.color});
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : Colors.transparent,
        border: Border.all(
            color: done ? color : theme.colorScheme.outline, width: 2),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    ).animate(target: done ? 1 : 0).scaleXY(
        begin: 1, end: 1.08, duration: AppMotion.fast, curve: AppMotion.standard);
  }
}
