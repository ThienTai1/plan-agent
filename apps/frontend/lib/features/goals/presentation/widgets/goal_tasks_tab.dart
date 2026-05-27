import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';
import 'package:frontend/features/goals/presentation/widgets/custom_properties_view.dart';
import 'package:frontend/features/goals/presentation/widgets/milestone_header.dart';
import 'package:frontend/features/goals/presentation/widgets/task_row_item.dart';

class GoalTasksTab extends StatefulWidget {
  final List<TaskModel> tasks;
  final List<Phase> phases;
  final Set<String> collapsedMilestones;
  final List<CustomProperty> goalFieldDefinitions;
  final ValueChanged<String> onToggleCollapse;
  final ValueChanged<Phase> onRenamePhase;
  final ValueChanged<Phase> onDeletePhase;
  final ValueChanged<TaskModel> onToggleTaskCompletion;
  final Future<bool?> Function(TaskModel) onConfirmDeleteTask;
  final ValueChanged<TaskModel> onAddSubtask;
  final ValueChanged<TaskModel> onDismissedTask;
  final VoidCallback onAddTask;

  const GoalTasksTab({
    super.key,
    required this.tasks,
    required this.phases,
    required this.collapsedMilestones,
    required this.goalFieldDefinitions,
    required this.onToggleCollapse,
    required this.onRenamePhase,
    required this.onDeletePhase,
    required this.onToggleTaskCompletion,
    required this.onConfirmDeleteTask,
    required this.onDismissedTask,
    required this.onAddSubtask,
    required this.onAddTask,
  });

  @override
  State<GoalTasksTab> createState() => _GoalTasksTabState();
}

class _GoalTasksTabState extends State<GoalTasksTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All'; // All, Active, Completed
  final Set<String> _collapsedTaskIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<TaskModel> filteredTasks = widget.tasks;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        final query = _searchQuery.toLowerCase();
        return task.title.toLowerCase().contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      filteredTasks = filteredTasks.where((task) {
        if (_selectedCategory == 'Active') return !task.isCompleted;
        if (_selectedCategory == 'Completed') return task.isCompleted;
        return true;
      }).toList();
    }

    // Top sections with default background
    final topSections = <Widget>[
      _buildSearchBar(),
      _buildCategoryChips(),
      _buildHeader(context),
    ];

    final taskListItems = <Widget>[];

    if (filteredTasks.isEmpty && widget.phases.isEmpty) {
      taskListItems.add(_buildEmptyState(context));
    } else if (widget.phases.isEmpty) {
      if (filteredTasks.isEmpty) {
        taskListItems.add(_buildNoSearchResults(context));
      } else {
        final flattened = _flattenTasksWithDepth(filteredTasks);
        for (final item in flattened) {
          taskListItems.add(_buildTaskRow(
            item.task, 
            item.depth, 
            item.hasChildren, 
            item.completedCount, 
            item.totalCount,
          ));
        }
      }
    } else {
      final Map<String?, List<TaskModel>> grouped = {};
      for (final task in filteredTasks) {
        grouped.putIfAbsent(task.phaseId, () => []).add(task);
      }

      final unassigned = grouped[null] ?? [];

      for (final phase in widget.phases) {
        final phaseTasks = grouped[phase.id] ?? [];
        final isCollapsed = widget.collapsedMilestones.contains(phase.id);

        taskListItems.add(
          MilestoneHeader(
            phase: phase,
            taskCount: phaseTasks.length,
            isCollapsed: isCollapsed,
            onToggleCollapse: () => widget.onToggleCollapse(phase.id),
            onRename: () => widget.onRenamePhase(phase),
            onDelete: () => widget.onDeletePhase(phase),
          ),
        );

        if (!isCollapsed) {
          if (phaseTasks.isEmpty && _searchQuery.isEmpty) {
            taskListItems.add(_buildEmptyMilestoneHint(context));
          } else {
            final flattened = _flattenTasksWithDepth(phaseTasks);
            for (final item in flattened) {
              taskListItems.add(_buildTaskRow(
                item.task, 
                item.depth, 
                item.hasChildren,
                item.completedCount,
                item.totalCount,
              ));
            }
          }
        }
      }

      if (unassigned.isNotEmpty) {
        taskListItems.add(_buildSectionDivider(context));
        final flattened = _flattenTasksWithDepth(unassigned);
        for (final item in flattened) {
          taskListItems.add(_buildTaskRow(
            item.task, 
            item.depth, 
            item.hasChildren,
            item.completedCount,
            item.totalCount,
          ));
        }
      }
    }

    final children = <Widget>[
      ...topSections,
      Container(
        color: Colors.white,
        child: Column(children: taskListItems),
      ),
      const SizedBox(height: 80), // FAB spacer
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  List<_TaskWithDepth> _flattenTasksWithDepth(List<TaskModel> allTasks) {
    final List<_TaskWithDepth> flattened = [];
    final Map<String?, List<TaskModel>> parentToChildren = {};

    String? normalize(String? id) {
      if (id == null) return null;
      final t = id.trim().toLowerCase();
      return t.isEmpty ? null : t;
    }

    for (final task in widget.tasks) {
      final pid = normalize(task.parentTaskId);
      parentToChildren.putIfAbsent(pid, () => []).add(task);
    }

    void traverse(String? parentId, int depth) {
      final pid = normalize(parentId);
      final children = parentToChildren[pid] ?? [];
      if (children.isEmpty) return;

      // Sort children
      children.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.createdAt.compareTo(b.createdAt);
      });

      // If parent is collapsed, we don't add children to the flattened list
      if (parentId != null && _collapsedTaskIds.contains(parentId)) return;

      for (final child in children) {
        final cid = normalize(child.id);
        final subChildren = parentToChildren[cid] ?? [];
        final hasSubChildren = subChildren.isNotEmpty;
        final completedSub = subChildren.where((t) => t.isCompleted).length;
        
        flattened.add(_TaskWithDepth(
          child, 
          depth, 
          hasSubChildren,
          completedCount: completedSub,
          totalCount: subChildren.length,
        ));
        traverse(cid, depth + 1);
      }
    }

    // Find root tasks
    final rootTasks = allTasks.where((t) {
      final pid = normalize(t.parentTaskId);
      final hasParentInList =
          pid != null && allTasks.any((p) => normalize(p.id) == pid);
      return !hasParentInList;
    }).toList();

    rootTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });

    for (final root in rootTasks) {
      if (!flattened.any((element) => element.task.id == root.id)) {
        final rid = normalize(root.id);
        final subChildren = parentToChildren[rid] ?? [];
        final hasSubChildren = subChildren.isNotEmpty;
        final completedSub = subChildren.where((t) => t.isCompleted).length;
        
        flattened.add(_TaskWithDepth(
          root, 
          0, 
          hasSubChildren,
          completedCount: completedSub,
          totalCount: subChildren.length,
        ));
        traverse(rid, 1);
      }
    }

    return flattened;
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Active', 'Completed'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = cat);
                },
                backgroundColor: AppPallete.getSurface(context),
                selectedColor: AppPallete.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppPallete.getPrimaryColor(context)
                      : AppPallete.getTextSecondary(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppPallete.getPrimaryColor(context)
                        : AppPallete.getBorderColor(
                            context,
                          ).withValues(alpha: 0.3),
                  ),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tasks & Milestones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
          TextButton.icon(
            onPressed: widget.onAddTask,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppPallete.getPrimaryColor(context),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppPallete.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppPallete.getBorderColor(
                    context,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(
                    color: AppPallete.getTextMuted(context),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: AppPallete.getTextMuted(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppPallete.getSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppPallete.getBorderColor(
                  context,
                ).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(TaskModel task, int depth, bool hasChildren, int completedCount, int totalCount) {
    return TaskRowItem(
      task: task,
      depth: depth,
      hasChildren: hasChildren,
      completedSubtasks: completedCount,
      totalSubtasks: totalCount,
      isCollapsed: _collapsedTaskIds.contains(task.id),
      onToggleCollapse: () {
        setState(() {
          if (_collapsedTaskIds.contains(task.id)) {
            _collapsedTaskIds.remove(task.id);
          } else {
            _collapsedTaskIds.add(task.id);
          }
        });
      },
      onAddSubtask: () => widget.onAddSubtask(task),
      goalFieldDefinitions: widget.goalFieldDefinitions,
      onToggleCompletion: () => widget.onToggleTaskCompletion(task),
      onConfirmDelete: () => widget.onConfirmDeleteTask(task),
      onDismissed: () => widget.onDismissedTask(task),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 40,
              color: AppPallete.getBorderColor(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 15,
                color: AppPallete.getTextMuted(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add a task',
              style: TextStyle(
                fontSize: 13,
                color: AppPallete.getTextMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'No tasks match "$_searchQuery"',
          style: TextStyle(
            fontSize: 14,
            color: AppPallete.getTextMuted(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMilestoneHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 46, bottom: 8, top: 2),
      child: Text(
        'No tasks yet',
        style: TextStyle(
          fontSize: 13,
          color: AppPallete.getTextMuted(context),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    return Divider(
      height: 24,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
    );
  }
}

class _TaskWithDepth {
  final TaskModel task;
  final int depth;
  final bool hasChildren;
  final int completedCount;
  final int totalCount;

  _TaskWithDepth(
    this.task, 
    this.depth, 
    this.hasChildren, {
    this.completedCount = 0,
    this.totalCount = 0,
  });
}
