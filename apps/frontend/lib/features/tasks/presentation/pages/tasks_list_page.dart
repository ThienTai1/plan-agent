import 'package:flutter/material.dart';
import 'package:frontend/core/common/widgets/app_empty_state.dart';
import 'package:frontend/core/common/widgets/app_scaffold.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/tasks/presentation/widgets/detailed_task_item.dart';
import 'package:frontend/features/goals/presentation/widgets/create_task_modal.dart';
import 'package:frontend/core/common/presentation/providers/filter_providers.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_filter_sheet.dart';

class TasksListPage extends ConsumerStatefulWidget {
  static const String routeName = '/tasks-list';

  const TasksListPage({super.key});

  @override
  ConsumerState<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends ConsumerState<TasksListPage> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTasksAsync = ref.watch(allTasksProvider);
    final TaskFilterState filter = ref.watch(taskFilterProvider);

    return AppScaffold(
      backgroundColor: Colors.transparent,
      safeAreaBottom: false,
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks_list_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateTaskModal(initialIsEvent: false),
          );
        },
        backgroundColor: AppPallete.getPrimaryColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        bottom: false,
        child: allTasksAsync.when(
          data: (taskEntries) {
            final allTasks = taskEntries
                .map((row) => TaskModel.fromJson(row))
                .toList();

            final normalizedQuery = _query.trim().toLowerCase();
            final filteredTasks = allTasks.where((t) {
              // Search Query
              final matchesQuery =
                  normalizedQuery.isEmpty ||
                  t.title.toLowerCase().contains(normalizedQuery);

              // Status Filter
              final matchesStatus = switch (filter.status) {
                TaskStatusFilter.all => true,
                TaskStatusFilter.todo => t.status == 'todo' && !t.isCompleted,
                TaskStatusFilter.inProgress =>
                  t.status == 'in_progress' && !t.isCompleted,
                TaskStatusFilter.done => t.isCompleted || t.status == 'done',
              };

              // Priority Filter
              final matchesPriority = switch (filter.priority) {
                TaskPriorityFilter.all => true,
                TaskPriorityFilter.low => t.priority?.toLowerCase() == 'low',
                TaskPriorityFilter.medium =>
                  t.priority?.toLowerCase() == 'medium',
                TaskPriorityFilter.high => t.priority?.toLowerCase() == 'high',
                TaskPriorityFilter.urgent =>
                  t.priority?.toLowerCase() == 'urgent',
              };

              // Date Filter
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final matchesDate = switch (filter.date) {
                TaskDateFilter.all => true,
                TaskDateFilter.today =>
                  t.dueDate != null &&
                      DateTime(
                        t.dueDate!.year,
                        t.dueDate!.month,
                        t.dueDate!.day,
                      ).isAtSameMomentAs(today),
                TaskDateFilter.overdue =>
                  t.dueDate != null &&
                      t.dueDate!.isBefore(today) &&
                      !t.isCompleted,
                TaskDateFilter.upcoming =>
                  t.dueDate != null && t.dueDate!.isAfter(today),
              };

              return matchesQuery &&
                  matchesStatus &&
                  matchesPriority &&
                  matchesDate;
            }).toList();

            final pendingTasks = filteredTasks
                .where((t) => !t.isCompleted)
                .toList();
            final completedTasks = filteredTasks
                .where((t) => t.isCompleted)
                .toList();

            final overdueCount = allTasks
                .where(
                  (t) =>
                      !t.isCompleted &&
                      t.dueDate != null &&
                      t.dueDate!.isBefore(DateTime.now()),
                )
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  context,
                  allTasks.where((t) => !t.isCompleted).length,
                  overdueCount,
                ),
                const SizedBox(height: 8),
                _buildSearchBar(context),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (filteredTasks.isEmpty)
                        _buildEmptyState(context, allTasks.isEmpty),
                      if (pendingTasks.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'ACTIVE TASKS',
                          pendingTasks.length,
                        ),
                        const SizedBox(height: 12),
                        ...pendingTasks.map(
                          (t) => DetailedTaskItem(
                            task: t,
                            goalTitle: t.goalId == null ? 'General' : 'Goal',
                            progress: 0,
                          ),
                        ),
                      ],
                      if (completedTasks.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildCompletedTasksToggle(context, completedTasks),
                      ],
                      const SizedBox(height: 100), // Space for FAB/BottomNav
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              AppEmptyState(title: 'Could not load tasks', subtitle: '$err'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTotallyEmpty) {
    if (_query.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: AppEmptyState(
          title: 'No results for "$_query"',
          subtitle: 'Try a different keyword or check your filters.',
        ),
      );
    }

    if (isTotallyEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: AppEmptyState(
          title: 'No tasks yet',
          subtitle: 'Focus on what matters. Create your first task to get started.',
          ctaLabel: 'Create Task',
          onCta: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const CreateTaskModal(initialIsEvent: false),
            );
          },
        ),
      );
    }

    // This handles filters that result in no tasks
    return const Padding(
      padding: const EdgeInsets.only(top: 60),
      child: AppEmptyState(
        title: 'No matching tasks',
        subtitle: 'Try adjusting your filters to see more tasks.',
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int leftCount, int overdueCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'All Tasks',
            style: GoogleFonts.jetBrainsMono(
              fontSize: AppFontSizes.heading,
              fontWeight: FontWeight.w800,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -1.0,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$leftCount Tasks',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppPallete.getPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppPallete.getSurfaceContainerLow(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppPallete.getBorderColor(
                    context,
                  ).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  hintStyle: TextStyle(
                    color: AppPallete.getTextMuted(context),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppPallete.getTextMuted(context),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.tune, color: AppPallete.getTextPrimary(context)),
            onPressed: () => TaskFilterSheet.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppPallete.getTextPrimary(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppPallete.getTextSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksToggle(
    BuildContext context,
    List<TaskModel> completedTasks,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Completed (${completedTasks.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppPallete.getTextSecondary(context),
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_down,
          color: AppPallete.getTextMuted(context),
        ),
        children: completedTasks
            .map(
              (t) => DetailedTaskItem(
                task: t,
                goalTitle: t.goalId == null ? 'General' : 'Goal',
                progress: 1.0,
              ),
            )
            .toList(),
      ),
    );
  }
}
