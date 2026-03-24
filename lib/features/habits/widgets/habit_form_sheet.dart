import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/utils/haptic_utils.dart';
import 'package:atlas_flutter_app/core/utils/validators.dart';
import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/habit.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_text_field.dart';

import 'package:atlas_flutter_app/features/habits/providers/habits_provider.dart';

/// Opens a modal bottom sheet with the habit creation/edit form.
void showHabitFormSheet(
  BuildContext context, {
  required WidgetRef ref,
  Habit? habit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HabitFormSheet(habit: habit, ref: ref),
  );
}

class _HabitFormSheet extends StatefulWidget {
  final Habit? habit;
  final WidgetRef ref;

  const _HabitFormSheet({this.habit, required this.ref});

  @override
  State<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<_HabitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late HabitCategory _selectedCategory;
  late HabitFrequency _selectedFrequency;
  late double _difficulty;
  TimeOfDay? _reminderTime;
  bool _isSaving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _titleController = TextEditingController(text: habit?.title ?? '');
    _descriptionController =
        TextEditingController(text: habit?.description ?? '');
    _selectedCategory = habit?.category ?? HabitCategory.custom;
    _selectedFrequency = habit?.frequency ?? HabitFrequency.daily;
    _difficulty = (habit?.difficulty ?? 5).toDouble();
    _reminderTime = _parseReminderTime(habit?.reminderTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseReminderTime(String? time) {
    if (time == null || time.isEmpty) return null;
    try {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  String _habitCategoryApiValue(HabitCategory category) {
    return switch (category) {
      HabitCategory.health => 'health',
      HabitCategory.fitness => 'fitness',
      HabitCategory.learning => 'learning',
      HabitCategory.mindfulness => 'mindfulness',
      HabitCategory.productivity => 'productivity',
      HabitCategory.social => 'social',
      HabitCategory.creative => 'creative',
      HabitCategory.custom => 'custom',
    };
  }

  String _habitFrequencyApiValue(HabitFrequency frequency) {
    return switch (frequency) {
      HabitFrequency.daily => 'daily',
      HabitFrequency.weekly => 'weekly',
      HabitFrequency.weekdays => 'weekdays',
      HabitFrequency.weekends => 'weekends',
      HabitFrequency.custom => 'custom',
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
      'category': _habitCategoryApiValue(_selectedCategory),
      'frequency': _habitFrequencyApiValue(_selectedFrequency),
      'difficulty': _difficulty.round(),
      if (_reminderTime != null)
        'reminder_time':
            '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}',
    };

    bool success;
    if (_isEditing) {
      success =
          await widget.ref.read(habitsProvider.notifier).updateHabit(
                widget.habit!.id,
                data,
              );
    } else {
      success =
          await widget.ref.read(habitsProvider.notifier).createHabit(data);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        HapticUtils.successVibrate();
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
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
                _isEditing ? 'Edit Habit' : 'New Habit',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Habit Title ───
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'What habit do you want to build?',
                prefixIcon: Icons.loop_rounded,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    Validators.validateRequired(v, fieldName: 'Title'),
              ),
              const SizedBox(height: 16),

              // ─── Description ───
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your habit (optional)',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
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
              DropdownButtonFormField<HabitCategory>(
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
                items: HabitCategory.values.map((cat) {
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

              // ─── Frequency Selector ───
              Text(
                'Frequency',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<HabitFrequency>(
                  segments: const [
                    ButtonSegment(
                      value: HabitFrequency.daily,
                      label: Text('Daily'),
                      icon: Icon(Icons.today_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: HabitFrequency.weekly,
                      label: Text('Weekly'),
                      icon: Icon(Icons.date_range_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: HabitFrequency.custom,
                      label: Text('Custom'),
                      icon: Icon(Icons.tune_rounded, size: 18),
                    ),
                  ],
                  selected: {_selectedFrequency},
                  onSelectionChanged: (s) =>
                      setState(() => _selectedFrequency = s.first),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Difficulty Slider ───
              Text(
                'Difficulty',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
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

              // ─── Reminder Time Picker ───
              InkWell(
                onTap: _pickReminderTime,
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
                        Icons.alarm_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _reminderTime != null
                              ? 'Reminder at ${_reminderTime!.format(context)}'
                              : 'Set reminder time (optional)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _reminderTime != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_reminderTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () =>
                              setState(() => _reminderTime = null),
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
                label: _isEditing ? 'Update Habit' : 'Create Habit',
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
