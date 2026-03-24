import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/data/models/goal.dart';
import 'package:atlas_flutter_app/features/goals/providers/goals_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';

/// Shows a bottom sheet for creating or editing a goal.
Future<void> showGoalFormSheet(
  BuildContext context, {
  Goal? goal,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GoalFormSheet(goal: goal),
  );
}

class _GoalFormSheet extends ConsumerStatefulWidget {
  final Goal? goal;

  const _GoalFormSheet({this.goal});

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late GoalCategory _category;
  late GoalPriority _priority;
  DateTime? _deadline;
  DateTime? _startDate;
  String? _parentGoalId;
  bool _isSaving = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.goal?.description ?? '');
    _category = widget.goal?.category ?? GoalCategory.personal;
    _priority = widget.goal?.priority ?? GoalPriority.medium;
    _deadline = widget.goal?.deadline;
    _startDate = widget.goal?.startDate;
    _parentGoalId = widget.goal?.parentGoalId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category.name,
      'priority': _priority.name,
      if (_deadline != null) 'deadline': _deadline!.toIso8601String(),
      if (_startDate != null) 'start_date': _startDate!.toIso8601String(),
      if (_parentGoalId != null) 'parent_goal_id': _parentGoalId,
    };

    final notifier = ref.read(goalsProvider.notifier);

    if (_isEditing) {
      await notifier.updateGoal(widget.goal!.id, data);
    } else {
      await notifier.createGoal(data);
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate({required bool isDeadline}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDeadline ? _deadline : _startDate) ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isDeadline) {
          _deadline = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goals = ref.watch(goalsProvider).goals;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  // Handle
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

                  // Title
                  Text(
                    _isEditing ? 'Edit Goal' : 'New Goal',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'What do you want to achieve?',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add details about this goal...',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),

                  // Category dropdown
                  DropdownButtonFormField<GoalCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: GoalCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(_categoryLabel(c)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Priority
                  Text(
                    'Priority',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<GoalPriority>(
                    segments: GoalPriority.values.map((p) {
                      return ButtonSegment(
                        value: p,
                        label: Text(
                          p.name[0].toUpperCase() + p.name.substring(1),
                        ),
                      );
                    }).toList(),
                    selected: {_priority},
                    onSelectionChanged: (s) =>
                        setState(() => _priority = s.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(
                        theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date row
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: 'Start Date',
                          date: _startDate,
                          onTap: () => _pickDate(isDeadline: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateButton(
                          label: 'Deadline',
                          date: _deadline,
                          onTap: () => _pickDate(isDeadline: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Parent goal
                  if (goals.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      initialValue: _parentGoalId,
                      decoration: const InputDecoration(
                        labelText: 'Parent Goal (optional)',
                        prefixIcon: Icon(Icons.account_tree_rounded),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ...goals
                            .where((g) => g.id != widget.goal?.id)
                            .map((g) => DropdownMenuItem(
                                  value: g.id,
                                  child: Text(
                                    g.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                      ],
                      onChanged: (v) => setState(() => _parentGoalId = v),
                    ),
                  const SizedBox(height: 28),

                  // Submit button
                  AppButton(
                    label: _isEditing ? 'Update Goal' : 'Create Goal',
                    icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _categoryLabel(GoalCategory cat) => switch (cat) {
        GoalCategory.health => 'Health',
        GoalCategory.fitness => 'Fitness',
        GoalCategory.mindfulness => 'Mindfulness',
        GoalCategory.learning => 'Learning',
        GoalCategory.career => 'Career',
        GoalCategory.financial => 'Financial',
        GoalCategory.relationships => 'Relationships',
        GoalCategory.personal => 'Personal',
        GoalCategory.custom => 'Custom',
      };
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardDark
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
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
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('MMM d, y').format(date!)
                        : 'Not set',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
