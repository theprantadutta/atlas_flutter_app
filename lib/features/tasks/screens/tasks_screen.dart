import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/models/enums.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';

import 'package:atlas_flutter_app/features/tasks/providers/tasks_provider.dart';
import 'package:atlas_flutter_app/features/tasks/widgets/task_card.dart';
import 'package:atlas_flutter_app/features/tasks/widgets/task_form_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  bool _showSearch = false;
  final _searchController = TextEditingController();

  static const _tabs = [
    (label: 'Daily', type: TaskType.daily),
    (label: 'Weekly', type: TaskType.weekly),
    (label: 'Long-Term', type: TaskType.longTerm),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(tasksProvider.notifier).setTab(_tabs[_tabController.index].type);
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(tasksProvider.notifier).setSearch(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ─── App Bar ───
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              'Tasks',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: 200.ms,
                  child: Icon(
                    _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                    key: ValueKey(_showSearch),
                  ),
                ),
                tooltip: 'Search tasks',
                onPressed: _toggleSearch,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_showSearch ? 120 : 56),
              child: Column(
                children: [
                  // ─── Search Bar ───
                  AnimatedContainer(
                    duration: 300.ms,
                    curve: Curves.easeInOut,
                    height: _showSearch ? 56 : 0,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => notifier.setSearch(v),
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    notifier.setSearch(null);
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? AppColors.cardDark
                              : AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── Tab Bar ───
                  TabBar(
                    controller: _tabController,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: theme.textTheme.labelLarge,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ─── Category Filter Chips ───
            _CategoryFilterBar(
              selectedCategory: state.selectedCategory,
              onSelected: (cat) => notifier.setCategory(cat),
              isDark: isDark,
            ),

            // ─── Body ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  return _TaskListBody(
                    tabType: tab.type,
                    isDark: isDark,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),

      // ─── FAB ───
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks_fab',
        onPressed: () => showTaskFormSheet(context, ref: ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Category Filter Bar
// ═══════════════════════════════════════════════════════════════════

class _CategoryFilterBar extends StatelessWidget {
  final TaskCategory? selectedCategory;
  final ValueChanged<TaskCategory?> onSelected;
  final bool isDark;

  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onSelected,
    required this.isDark,
  });

  static const _categoryMeta = <(TaskCategory, String, Color)>[
    (TaskCategory.work, 'Work', AppColors.categoryWork),
    (TaskCategory.health, 'Health', AppColors.categoryHealth),
    (TaskCategory.fitness, 'Fitness', AppColors.categoryFitness),
    (TaskCategory.learning, 'Learning', AppColors.categoryLearning),
    (TaskCategory.mindfulness, 'Mindfulness', AppColors.categoryMindfulness),
    (TaskCategory.personal, 'Personal', AppColors.info),
    (TaskCategory.social, 'Social', AppColors.categorySocial),
    (TaskCategory.creativity, 'Creativity', AppColors.categoryCreative),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // "All" chip
          _FilterChip(
            label: 'All',
            isSelected: selectedCategory == null,
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ..._categoryMeta.map((meta) {
            final (cat, label, color) = meta;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: label,
                isSelected: selectedCategory == cat,
                color: color,
                isDark: isDark,
                onTap: () => onSelected(
                  selectedCategory == cat ? null : cat,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Task List Body (per tab)
// ═══════════════════════════════════════════════════════════════════

class _TaskListBody extends ConsumerWidget {
  final TaskType tabType;
  final bool isDark;

  const _TaskListBody({
    required this.tabType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return AppErrorDisplay(
        message: state.error!,
        onRetry: () => notifier.loadTasks(),
      );
    }

    // Get filtered tasks for this specific tab
    final tasks = notifier.filteredTasks
        .where((t) => t.type == tabType)
        .toList();

    if (tasks.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TaskCard(task: task, isDark: isDark)
                .animate()
                .fadeIn(
                  delay: (index * 60).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                )
                .slideX(
                  begin: 0.06,
                  end: 0,
                  delay: (index * 60).ms,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LoadingShimmer.listItem(height: 80),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a task to start earning XP\nand leveling up your character!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }
}
