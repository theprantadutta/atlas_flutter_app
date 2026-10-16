import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/grow/widgets/item_editor_sheet.dart';
import 'package:atlas_flutter_app/features/home/providers/home_prefs.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

enum _ItemAction { edit, skip, tomorrow, delete }

/// The long-press menu for a task or habit: Edit, Skip today, Snooze to
/// tomorrow, Delete (with Undo). Pass exactly one of [task] / [habit].
Future<void> showItemMenu(
  BuildContext context,
  WidgetRef ref, {
  Task? task,
  Habit? habit,
  Goal? goal,
  bool allowSnooze = true,
}) async {
  final title = task?.title ?? habit?.title ?? goal?.title ?? '';
  final id = task?.id ?? habit?.id ?? goal?.id;
  if (id == null) return;
  final action = await showActionSheet<_ItemAction>(
    context,
    title: title,
    actions: [
      const SheetAction(value: _ItemAction.edit, label: 'Edit', icon: Symbols.edit_rounded),
      if (allowSnooze && goal == null) ...[
        const SheetAction(
            value: _ItemAction.skip, label: 'Skip today', icon: Symbols.do_not_disturb_on_rounded),
        const SheetAction(
            value: _ItemAction.tomorrow, label: 'Snooze to tomorrow', icon: Symbols.snooze_rounded),
      ],
      const SheetAction(
          value: _ItemAction.delete, label: 'Delete', icon: Symbols.delete_rounded, destructive: true),
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _ItemAction.edit:
      await showItemEditor(context, task: task, habit: habit, goal: goal);
    case _ItemAction.skip:
      await ref.read(snoozeProvider.notifier).skipToday(id);
      if (context.mounted) {
        AtlasToast.undo(context, 'Skipped for today',
            onUndo: () => ref.read(snoozeProvider.notifier).clear(id));
      }
    case _ItemAction.tomorrow:
      await ref.read(snoozeProvider.notifier).tomorrow(id);
      if (context.mounted) {
        AtlasToast.undo(context, 'See you tomorrow morning',
            onUndo: () => ref.read(snoozeProvider.notifier).clear(id));
      }
    case _ItemAction.delete:
      await deleteItem(context, ref, task: task, habit: habit, goal: goal);
  }
}

/// Soft-delete (a tombstone, so it syncs) with a 4s Undo.
Future<void> deleteItem(
  BuildContext context,
  WidgetRef ref, {
  Task? task,
  Habit? habit,
  Goal? goal,
}) async {
  final db = ref.read(databaseProvider);
  Future<void> setDeleted(bool deleted) async {
    final now = DateTime.now();
    if (task != null) {
      await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(TasksCompanion(
        isDeleted: Value(deleted),
        deletedAt: Value(deleted ? now : null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    } else if (habit != null) {
      await (db.update(db.habits)..where((h) => h.id.equals(habit.id))).write(HabitsCompanion(
        isDeleted: Value(deleted),
        deletedAt: Value(deleted ? now : null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    } else if (goal != null) {
      await (db.update(db.goals)..where((g) => g.id.equals(goal.id))).write(GoalsCompanion(
        isDeleted: Value(deleted),
        deletedAt: Value(deleted ? now : null),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ));
    }
  }

  await setDeleted(true);
  if (!context.mounted) return;
  final what = task != null ? 'Task' : habit != null ? 'Habit' : 'Goal';
  AtlasToast.undo(context, '$what deleted', onUndo: () => setDeleted(false));
}
