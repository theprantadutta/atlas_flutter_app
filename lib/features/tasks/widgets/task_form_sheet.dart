import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/core/utils/haptic_utils.dart';
import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/task.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_text_field.dart';

import 'package:atlas_flutter_app/features/tasks/providers/tasks_provider.dart';

/// Opens a modal bottom sheet with the task creation/edit form.
void showTaskFormSheet(
  BuildContext context, {
  required WidgetRef ref,
  Task? task,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskFormSheet(task: task, ref: ref),
  );
}

class _TaskFormSheet extends StatefulWidget {
  final Task? task;
  final WidgetRef ref;

  const _TaskFormSheet({this.task, required this.ref});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TaskType _selectedType;
  late TaskCategory _selectedCategory;
  late double _difficulty;
  DateTime? _dueDate;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _selectedType = task?.type ?? TaskType.daily;
    _selectedCategory = task?.category ?? TaskCategory.work;
    _difficulty = (task?.difficulty ?? 5).toDouble();
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int get _estimatedXp => GamificationConstants.calculateTaskXp(
        taskType: _selectedType.name,
        difficulty: _difficulty.round(),
      );

  String _taskTypeApiValue(TaskType type) {
    return switch (type) {
      TaskType.daily => 'daily',
      TaskType.weekly => 'weekly',
      TaskType.longTerm => 'long_term',
    };
  }

  String _taskCategoryApiValue(TaskCategory category) {
    return switch (category) {
      TaskCategory.health => 'health',
      TaskCategory.fitness => 'fitness',
      TaskCategory.mindfulness => 'mindfulness',
      TaskCategory.finance => 'finance',
      TaskCategory.work => 'work',
      TaskCategory.learning => 'learning',
      TaskCategory.social => 'social',
      TaskCategory.creative => 'creative',
      TaskCategory.custom => 'custom',
    };
  }

  String _displayName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticUtils.lightTap();

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'type': _taskTypeApiValue(_selectedType),
      'category': _taskCategoryApiValue(_selectedCategory),
      'difficulty': _difficulty.round(),
      if (_dueDate != null) 'due_date': _dueDate!.toIso8601String(),
    };

    bool success;
    if (_isEditing) {
      success =
          await widget.ref.read(tasksProvider.notifier).updateTask(
                widget.task!.id,
                data,
              );
    } else {
      success = await widget.ref.read(tasksProvider.notifier).createTask(data);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        HapticUtils.successVibrate();
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Handle ───
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Title ───
              Text(
                _isEditing ? 'Edit Task' : 'New Task',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Task Title ───
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'What do you need to do?',
                prefixIcon: Icons.edit_outlined,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    Validators.validateRequired(v, fieldName: 'Title'),
              ),
              const SizedBox(height: 16),

              // ─── Description ───
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Add some details (optional)',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // ─── Type Selector ───
              Text(
                'Type',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TaskType>(
                  segments: const [
                    ButtonSegment(
                      value: TaskType.daily,
                      label: Text('Daily'),
                      icon: Icon(Icons.today_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: TaskType.weekly,
                      label: Text('Weekly'),
                      icon: Icon(Icons.date_range_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: TaskType.longTerm,
                      label: Text('Long-Term'),
                      icon: Icon(Icons.flag_rounded, size: 18),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (s) =>
                      setState(() => _selectedType = s.first),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Category Dropdown ───
              Text(
                'Category',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.cardBorderDark
                          : AppColors.cardBorderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.cardBorderDark
                          : AppColors.cardBorderLight,
                    ),
                  ),
                ),
                items: TaskCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(_displayName(cat.name)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 20),

              // ─── Difficulty Slider ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Difficulty',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.xpPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '~$_estimatedXp XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.xpPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _difficulty,
                min: 1,
                max: 10,
                divisions: 9,
                label: _difficulty.round().toString(),
                onChanged: (v) => setState(() => _difficulty = v),
              ),
              const SizedBox(height: 8),

              // ─── Due Date Picker ───
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cardBorderDark
                          : AppColors.cardBorderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? DateFormat('EEEE, MMM d, yyyy')
                                  .format(_dueDate!)
                              : 'Set due date (optional)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _dueDate != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _dueDate = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Buttons ───
              AppButton(
                label: _isEditing ? 'Update Task' : 'Create Task',
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
