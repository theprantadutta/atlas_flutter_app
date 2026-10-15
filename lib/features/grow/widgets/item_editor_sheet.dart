import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

enum ItemKind { task, habit, goal }

extension ItemKindX on ItemKind {
  String get label => switch (this) {
        ItemKind.task => 'task',
        ItemKind.habit => 'habit',
        ItemKind.goal => 'goal',
      };
  String get title => switch (this) {
        ItemKind.task => 'Task',
        ItemKind.habit => 'Habit',
        ItemKind.goal => 'Goal',
      };
}

/// Open the editor to create a new item of [kind], or to edit [task],
/// [habit] or [goal]. Everything is written to Drift first and marked dirty.
Future<bool> showItemEditor(
  BuildContext context, {
  ItemKind kind = ItemKind.task,
  Task? task,
  Habit? habit,
  Goal? goal,
}) async {
  final saved = await showAtlasSheet<bool>(
    context,
    builder: (_) => ItemEditorSheet(
      kind: task != null
          ? ItemKind.task
          : habit != null
              ? ItemKind.habit
              : goal != null
                  ? ItemKind.goal
                  : kind,
      task: task,
      habit: habit,
      goal: goal,
    ),
  );
  return saved ?? false;
}

class ItemEditorSheet extends ConsumerStatefulWidget {
  const ItemEditorSheet({
    super.key,
    required this.kind,
    this.task,
    this.habit,
    this.goal,
  });

  final ItemKind kind;
  final Task? task;
  final Habit? habit;
  final Goal? goal;

  @override
  ConsumerState<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

const _taskCategories = [
  'health', 'fitness', 'mindfulness', 'learning', 'work', 'social', 'creative', 'finance', 'custom',
];
const _habitCategories = [
  'health', 'fitness', 'mindfulness', 'learning', 'creative', 'social', 'productivity', 'custom',
];
const _goalCategories = [
  'health', 'fitness', 'mindfulness', 'learning', 'career', 'financial', 'relationships', 'personal',
];

class _ItemEditorSheetState extends ConsumerState<ItemEditorSheet> {
  late ItemKind _kind = widget.kind;
  late final _title = TextEditingController(
    text: widget.task?.title ?? widget.habit?.title ?? widget.goal?.title ?? '',
  );
  late final _note = TextEditingController(
    text: widget.task?.description ??
        widget.habit?.description ??
        widget.goal?.description ??
        '',
  );
  late String _category = widget.task?.category ??
      widget.habit?.category ??
      widget.goal?.category ??
      'custom';

  // Task
  late String _taskType = widget.task?.type ?? 'daily';
  late DateTime? _dueDate = widget.task?.dueDate;
  late int _effort = _effortFromXp(widget.task?.xpReward ?? 25);

  // Habit
  late String _frequency = widget.habit?.frequency ?? 'daily';
  late String? _reminder = widget.habit?.reminderTime;
  late int _difficulty = (widget.habit?.difficulty ?? 1).clamp(1, 3);

  // Goal
  late DateTime? _deadline = widget.goal?.deadline;
  late String _priority = widget.goal?.priority ?? 'medium';

  bool _saving = false;

  bool get _editing => widget.task != null || widget.habit != null || widget.goal != null;

  static int _effortFromXp(int xp) => xp <= 15 ? 1 : (xp <= 30 ? 2 : 3);
  static int _xpForEffort(int e) => switch (e) { 1 => 15, 3 => 40, _ => 25 };

  List<String> get _categories => switch (_kind) {
        ItemKind.task => _taskCategories,
        ItemKind.habit => _habitCategories,
        ItemKind.goal => _goalCategories,
      };

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null && (_dueDate!.hour != 0 || _dueDate!.minute != 0)
          ? TimeOfDay.fromDateTime(_dueDate!)
          : const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Add a time (optional)',
      cancelText: 'No time',
    );
    setState(() {
      _dueDate = time == null
          ? DateTime(date.year, date.month, date.day)
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickReminder() async {
    final t = parseHm(_reminder);
    final time = await showTimePicker(
      context: context,
      initialTime: t == null ? const TimeOfDay(hour: 9, minute: 0) : TimeOfDay(hour: t.hour, minute: t.minute),
    );
    if (time != null) setState(() => _reminder = formatHm(time.hour, time.minute));
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? addDays(now, 30),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date != null) setState(() => _deadline = date);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      HapticFeedback.selectionClick();
      AtlasToast.warning(context, 'Give it a name first.');
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final userId = ref.read(currentUserIdProvider);
    final now = DateTime.now();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    const uuid = Uuid();
    try {
      switch (_kind) {
        case ItemKind.task:
          final patch = TasksCompanion(
            title: Value(title),
            description: Value(note),
            type: Value(_taskType),
            category: Value(_category),
            xpReward: Value(_xpForEffort(_effort)),
            difficulty: Value(_effort),
            dueDate: Value(_dueDate),
            updatedAt: Value(now),
            isDirty: const Value(true),
          );
          if (widget.task != null) {
            await (db.update(db.tasks)..where((t) => t.id.equals(widget.task!.id))).write(patch);
          } else {
            await db.into(db.tasks).insert(patch.copyWith(
                  id: Value(uuid.v4()),
                  userId: Value(userId),
                  createdAt: Value(now),
                ));
          }
        case ItemKind.habit:
          final patch = HabitsCompanion(
            title: Value(title),
            description: Value(note),
            category: Value(_category),
            frequency: Value(_frequency),
            difficulty: Value(_difficulty),
            reminderTime: Value(_reminder),
            updatedAt: Value(now),
            isDirty: const Value(true),
          );
          if (widget.habit != null) {
            await (db.update(db.habits)..where((h) => h.id.equals(widget.habit!.id))).write(patch);
          } else {
            await db.into(db.habits).insert(patch.copyWith(
                  id: Value(uuid.v4()),
                  userId: Value(userId),
                  createdAt: Value(now),
                ));
          }
        case ItemKind.goal:
          final patch = GoalsCompanion(
            title: Value(title),
            description: Value(note),
            category: Value(_category == 'custom' ? 'personal' : _category),
            priority: Value(_priority),
            deadline: Value(_deadline),
            updatedAt: Value(now),
            isDirty: const Value(true),
          );
          if (widget.goal != null) {
            await (db.update(db.goals)..where((g) => g.id.equals(widget.goal!.id))).write(patch);
          } else {
            await db.into(db.goals).insert(patch.copyWith(
                  id: Value(uuid.v4()),
                  userId: Value(userId),
                  status: const Value('notStarted'),
                  progress: const Value(0.0),
                  startDate: Value(now),
                  createdAt: Value(now),
                ));
          }
      }
      if (!mounted) return;
      HapticFeedback.lightImpact();
      AtlasToast.success(context, _editing ? 'Saved' : 'Added to Grow');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AtlasToast.error(context, 'That didn’t save. Try once more.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _editing ? 'Edit ${_kind.label}' : 'New ${_kind.label}',
              style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!_editing) ...[
            SegmentedPill(
              labels: const ['Task', 'Habit', 'Goal'],
              index: _kind.index,
              onChanged: (i) => setState(() {
                _kind = ItemKind.values[i];
                if (!_categories.contains(_category)) _category = _categories.last;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _title,
            autofocus: !_editing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: AppTypography.sans(size: 16, weight: FontWeight.w600, color: p.textPrimary),
            decoration: InputDecoration(
              hintText: switch (_kind) {
                ItemKind.task => 'e.g. Reply to Sam',
                ItemKind.habit => 'e.g. Read 20 pages',
                ItemKind.goal => 'e.g. Run a half marathon',
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.sans(size: 15, color: p.textPrimary),
            decoration: const InputDecoration(hintText: 'A note (optional)'),
          ),
          const SizedBox(height: AppSpacing.lg - 4),
          _Label('Area'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _categories)
                ChoiceChipPill(
                  label: CategoryStyle.label(c),
                  icon: CategoryStyle.forCategory(c).icon,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg - 4),
          ..._kindFields(p),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: _editing ? 'Save' : 'Add ${_kind.label}',
            height: 56,
            expand: true,
            busy: _saving,
            onTap: _save,
          ),
        ],
      ),
    );
  }

  List<Widget> _kindFields(AtlasPalette p) {
    switch (_kind) {
      case ItemKind.task:
        return [
          _Label('Repeats'),
          _Choices(
            options: const {'daily': 'Every day', 'weekly': 'Every week', 'longTerm': 'Once'},
            value: _taskType,
            onChanged: (v) => setState(() => _taskType = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _Label('Effort'),
          _Choices(
            options: const {'1': 'Light · 15 XP', '2': 'Medium · 25 XP', '3': 'Big · 40 XP'},
            value: '$_effort',
            onChanged: (v) => setState(() => _effort = int.parse(v)),
          ),
          const SizedBox(height: AppSpacing.md),
          _PickerRow(
            icon: Symbols.event_rounded,
            label: _dueDate == null
                ? 'Add a date'
                : (_dueDate!.hour == 0 && _dueDate!.minute == 0)
                    ? '${weekdayName(_dueDate!)}, ${_dueDate!.day} ${monthShort(_dueDate!)}'
                    : '${weekdayName(_dueDate!)}, ${_dueDate!.day} ${monthShort(_dueDate!)} · ${clockLabel(_dueDate!.hour, _dueDate!.minute)}',
            onTap: _pickDue,
            onClear: _dueDate == null ? null : () => setState(() => _dueDate = null),
          ),
        ];
      case ItemKind.habit:
        return [
          _Label('How often'),
          _Choices(
            options: const {
              'daily': 'Every day',
              'weekdays': 'Weekdays',
              'weekends': 'Weekends',
              'weekly': 'Once a week',
            },
            value: _frequency,
            onChanged: (v) => setState(() => _frequency = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _Label('Effort'),
          _Choices(
            options: const {'1': 'Light', '2': 'Medium', '3': 'Big'},
            value: '$_difficulty',
            onChanged: (v) => setState(() => _difficulty = int.parse(v)),
          ),
          const SizedBox(height: AppSpacing.md),
          _PickerRow(
            icon: Symbols.schedule_rounded,
            label: _reminder == null
                ? 'Add a time'
                : () {
                    final t = parseHm(_reminder)!;
                    return 'Around ${clockLabel(t.hour, t.minute)}';
                  }(),
            onTap: _pickReminder,
            onClear: _reminder == null ? null : () => setState(() => _reminder = null),
          ),
        ];
      case ItemKind.goal:
        return [
          _Label('Priority'),
          _Choices(
            options: const {'low': 'Gentle', 'medium': 'Steady', 'high': 'Focus'},
            value: _priority,
            onChanged: (v) => setState(() => _priority = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _PickerRow(
            icon: Symbols.flag_rounded,
            label: _deadline == null
                ? 'Add a target date'
                : 'By ${_deadline!.day} ${monthShort(_deadline!)} ${_deadline!.year}',
            onTap: _pickDeadline,
            onClear: _deadline == null ? null : () => setState(() => _deadline = null),
          ),
        ];
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.xs),
        child: Text(text.toUpperCase(),
            style: AppTypography.kicker.copyWith(color: context.palette.textMuted)),
      );
}

class _Choices extends StatelessWidget {
  const _Choices({required this.options, required this.value, required this.onChanged});
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in options.entries)
            ChoiceChipPill(
              label: e.value,
              selected: value == e.key,
              onTap: () => onChanged(e.key),
            ),
        ],
      );
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.icon, required this.label, required this.onTap, this.onClear});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      semanticLabel: label,
      child: Container(
        height: 54,
        padding: const EdgeInsets.only(left: 18, right: 6),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(children: [
          AtlasIcon(icon, size: 20, color: p.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppTypography.sans(size: 15, weight: FontWeight.w600, color: p.textPrimary)),
          ),
          if (onClear != null)
            CircleIconButton(
              icon: Symbols.close_rounded,
              size: 40,
              iconSize: 18,
              background: p.track,
              semanticLabel: 'Clear',
              onTap: onClear,
            ),
        ]),
      ),
    );
  }
}
