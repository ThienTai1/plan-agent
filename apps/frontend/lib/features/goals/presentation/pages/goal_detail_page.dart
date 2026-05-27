import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/domain/models/task.dart' as core_task;
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/features/goals/presentation/widgets/create_task_modal.dart';
import 'package:frontend/features/goals/presentation/widgets/custom_properties_view.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_tasks_tab.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_icon_picker.dart';
import 'package:intl/intl.dart';
// custom_properties_editor.dart and goal_timeline_page.dart hidden for MVP
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/core/common/widgets/app_date_picker_sheet.dart';
import 'package:frontend/core/common/widgets/app_confirm_sheet.dart';
import 'package:frontend/features/goals/presentation/widgets/task_phase_option.dart';
import 'dart:convert';

class GoalDetailPage extends ConsumerStatefulWidget {
  final Goal goal;
  final bool embedded;

  const GoalDetailPage({super.key, required this.goal, this.embedded = false});

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage> {
  final List<CustomProperty> _customProperties = [];
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  bool _isEditingTitle = false;
  bool _isSaving = false;
  late DateTime _startDate;
  DateTime? _endDate;
  late String _status;
  String? _icon;
  late Map<String, dynamic> _goalCustomPropertiesBase;
  final Set<String> _collapsedMilestones = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _titleFocusNode = FocusNode();
    _status = widget.goal.status;
    _icon = widget.goal.icon;
    _startDate = widget.goal.startDate;
    _endDate = widget.goal.endDate;
    _goalCustomPropertiesBase = Map<String, dynamic>.from(
      widget.goal.customProperties ?? const {},
    );
    _loadGoalTaskFieldDefinitions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksByGoalProvider(widget.goal.id));
    final phasesAsync = ref.watch(phasesByGoalProvider(widget.goal.id));

    final body = tasksAsync.when(
      data: (entries) {
        final tasks = entries.map(_taskModelFromRow).toList()
          ..sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }
            final aTime = a.startTime ?? a.dueDate ?? DateTime(2100);
            final bTime = b.startTime ?? b.dueDate ?? DateTime(2100);
            return aTime.compareTo(bTime);
          });
        return _buildBody(
          tasks,
          phasesAsync.whenData((rows) => rows.map(_phaseFromRow).toList()),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not load tasks: $err'),
        ),
      ),
    );

    if (widget.embedded) {
      return Container(
        color: AppPallete.getBackgroundColor(context),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      body: Stack(
        children: [
          body,
          if (_isSaving)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildBody(
    List<TaskModel> tasks,
    AsyncValue<List<Phase>> phasesAsync,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppPallete.getBackgroundColor(context),
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: false,
            leading: widget.embedded
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppPallete.getTextPrimary(context),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: AppPallete.getTextPrimary(context),
                ),
                onPressed: _showGoalActions,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => GoalIconPicker.show(context, (emoji) {
                          _saveGoalWithIcon(emoji);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _icon ?? '🎯',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTitleSection()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPropertyRow(
                    context,
                    icon: Icons.info_outline,
                    label: 'Status',
                    value: _getDisplayStatus(
                      tasks,
                    ).toUpperCase().replaceAll('_', ' '),
                    valueColor: _getStatusColor(_getDisplayStatus(tasks)),
                    isPill: true,
                    onTap: () => _showStatusPicker(tasks),
                  ),
                  const SizedBox(height: 12),
                  _buildPropertyRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Deadline',
                    value: _getFormattedDateRange(),
                    onTap: _showDateRangePicker,
                  ),
                  const SizedBox(height: 12),
                  _buildProcessRow(context, tasks),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ];
      },
      body: phasesAsync.when(
        data: (phases) => GoalTasksTab(
          tasks: tasks,
          phases: phases,
          collapsedMilestones: _collapsedMilestones,
          goalFieldDefinitions: _customProperties,
          onToggleCollapse: (phaseId) {
            setState(() {
              if (_collapsedMilestones.contains(phaseId)) {
                _collapsedMilestones.remove(phaseId);
              } else {
                _collapsedMilestones.add(phaseId);
              }
            });
          },
          onRenamePhase: _showRenamePhaseDialog,
          onDeletePhase: _confirmDeletePhase,
          onToggleTaskCompletion: _toggleTaskCompletion,
          onConfirmDeleteTask: _confirmDeleteTask,
          onDismissedTask: (task) async {
            final result =
                await ref.read(goalsRepositoryProvider).deleteTask(task.id);
            result.fold((l) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete task: ${l.message}')),
              );
            }, (_) {});
          },
          onAddSubtask: (parent) => _showCreateTaskModal(
            phaseId: parent.phaseId,
            parentTaskId: parent.id,
          ),
          onAddTask: _showCreateTaskModal,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // ─── FAB ───

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _showAddMenu,
      backgroundColor: AppPallete.getPrimaryColor(context),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: AppPallete.getSecondarySurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('New Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateTaskModal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('New Milestone'),
                onTap: () {
                  Navigator.pop(context);
                  final phases =
                      ref
                          .read(phasesByGoalProvider(widget.goal.id))
                          .asData
                          ?.value ??
                      [];
                  _showCreateMilestoneDialog(phases.length);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTaskModal({String? phaseId, String? parentTaskId}) {
    final phaseRows =
        ref.read(phasesByGoalProvider(widget.goal.id)).asData?.value ?? [];
    final phaseOptions = phaseRows
        .map(_phaseFromRow)
        .map((phase) => TaskPhaseOption(id: phase.id, title: phase.title))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTaskModal(
        initialGoalId: widget.goal.id,
        goalFieldDefinitions: _customProperties,
        phaseOptions: phaseOptions,
        initialPhaseId: phaseId,
        initialParentTaskId: parentTaskId,
      ),
    );
  }

  // ─── Phase Actions ───

  void _showRenamePhaseDialog(Phase phase) {
    final controller = TextEditingController(text: phase.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Milestone'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != phase.title) {
                final newPhase = Phase(
                  id: phase.id,
                  goalId: phase.goalId,
                  title: newTitle,
                  description: phase.description,
                  orderIndex: phase.orderIndex,
                  startDate: phase.startDate,
                  endDate: phase.endDate,
                  status: phase.status,
                );
                await ref.read(goalsRepositoryProvider).updatePhase(newPhase);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePhase(Phase phase) async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Delete Milestone',
      message: 'Are you sure you want to delete "${phase.title}"? Associated tasks will be moved to "Unassigned".',
      confirmLabel: 'Delete',
      confirmColor: AppPallete.errorColor,
    );

    if (confirmed == true) {
      await ref.read(goalsRepositoryProvider).deletePhase(phase.id);
    }
  }

  Future<bool?> _confirmDeleteTask(TaskModel task) {
    return AppConfirmSheet.show(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete "${task.title}"?',
      confirmLabel: 'Delete',
      confirmColor: AppPallete.errorColor,
    );
  }

  // ─── Task toggle ───
  Future<void> _toggleTaskCompletion(TaskModel task) async {
    final payload = core_task.Task(
      id: task.id,
      userId: task.userId ?? widget.goal.userId,
      goalId: task.goalId,
      phaseId: task.phaseId,
      title: task.title,
      dueDate: task.dueDate,
      isCompleted: !task.isCompleted,
      priority: task.priority,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      customProperties: task.customProperties,
    );
    await ref.read(goalsRepositoryProvider).updateTask(payload);
  }

  // ─── Actions ───

  Future<void> _showGoalActions() async {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete goal'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteGoal();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGoal() async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Delete Goal',
      message: 'This will permanently remove "${widget.goal.title}" and all its tasks.',
      confirmLabel: 'Delete',
      confirmColor: AppPallete.errorColor,
    );
    if (confirmed != true) return;

    final res = await ref
        .read(goalsRepositoryProvider)
        .deleteGoal(widget.goal.id);
    if (!mounted) return;
    res.fold(
      (l) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.message))),
      (_) => Navigator.pop(context),
    );
  }

  Future<void> _showCreateMilestoneDialog(int currentCount) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime start = _startDate;
    DateTime end = _endDate ?? _startDate.add(const Duration(days: 14));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppPallete.getBackgroundColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppPallete.getTextMuted(context).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'New Milestone',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: AppPallete.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Milestone Title',
                    hintStyle: TextStyle(color: AppPallete.getTextMuted(context)),
                    filled: true,
                    fillColor: AppPallete.getSecondarySurface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: AppPallete.getTextPrimary(context)),
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(color: AppPallete.getTextMuted(context)),
                    filled: true,
                    fillColor: AppPallete.getSecondarySurface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await AppDatePickerSheet.showSingle(
                            context: context,
                            title: 'Start Date',
                            initialDate: start,
                          );
                          if (picked == null) return;
                          setDialogState(() => start = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppPallete.getSecondarySurface(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starts',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppPallete.getTextSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatWesternDate(start),
                                style: TextStyle(
                                  color: AppPallete.getTextPrimary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await AppDatePickerSheet.showSingle(
                            context: context,
                            title: 'End Date',
                            initialDate: end,
                          );
                          if (picked == null) return;
                          setDialogState(() => end = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppPallete.getSecondarySurface(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ends',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppPallete.getTextSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatWesternDate(end),
                                style: TextStyle(
                                  color: AppPallete.getTextPrimary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      final milestone = Phase(
                        id: '',
                        goalId: widget.goal.id,
                        title: title,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        orderIndex: currentCount,
                        startDate: start,
                        endDate: end,
                        status: 'active',
                      );
                      final result = await ref
                          .read(goalsRepositoryProvider)
                          .createPhase(milestone);
                      if (!mounted) return;
                      result.fold(
                        (failure) => ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(failure.message))),
                        (_) {
                          ref.invalidate(phasesByGoalProvider(widget.goal.id));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Milestone created')),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create Milestone',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _buildTitleSection() {
    if (_isEditingTitle) {
      return TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        autofocus: true,
        onSubmitted: (_) {
          setState(() => _isEditingTitle = false);
          _saveGoal();
        },
        onTapOutside: (_) {
          setState(() => _isEditingTitle = false);
          _saveGoal();
        },
        style: GoogleFonts.jetBrainsMono(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppPallete.getTextPrimary(context),
          letterSpacing: -1.0,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() => _isEditingTitle = true);
        _titleFocusNode.requestFocus();
      },
      child: Text(
        _titleController.text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppPallete.getTextPrimary(context),
          letterSpacing: -1.0,
        ),
      ),
    );
  }

  Future<void> _saveGoalWithIcon(String icon) async {
    setState(() {
      _icon = icon;
      _isSaving = true;
    });

    final payload = widget.goal.copyWith(icon: icon, updatedAt: DateTime.now());
    final res = await ref.read(goalsRepositoryProvider).updateGoal(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);

    res.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save Goal: ${l.message}')),
      ),
      (_) {
        // Updated locally
      },
    );
  }

  Widget _buildPropertyRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
    bool isPill = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppPallete.getTextMuted(context),
              ),
            ),
          ),
          Expanded(
            child: isPill
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (valueColor ?? AppPallete.getPrimaryColor(context))
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              valueColor ?? AppPallete.getTextPrimary(context),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? AppPallete.getTextPrimary(context),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessRow(BuildContext context, List<TaskModel> tasks) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            'Process',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppPallete.getTextMuted(context),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppPallete.getBorderColor(
                      context,
                    ).withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppPallete.getPrimaryColor(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDisplayStatus(List<TaskModel> tasks) {
    if (tasks.isEmpty) return _status;
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    if (completed == total) return 'done';
    if (completed > 0) return 'doing';
    return 'pending';
  }

  Future<void> _saveGoal() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final payload = widget.goal.copyWith(
      title: title,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    final res = await ref.read(goalsRepositoryProvider).updateGoal(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);

    res.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save Goal: ${l.message}')),
      ),
      (_) {
        // Updated locally
      },
    );
  }

  void _showStatusPicker(List<TaskModel> tasks) {
    final List<String> statuses = ['pending', 'doing', 'done'];
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + 20,
        offset.dy + 200,
        offset.dx + 200,
        offset.dy + 500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: statuses.map((s) {
        return PopupMenuItem<String>(
          value: s,
          child: Row(
            children: [
              Icon(Icons.circle, size: 12, color: _getStatusColor(s)),
              const SizedBox(width: 12),
              Text(s.toUpperCase().replaceAll('_', ' ')),
            ],
          ),
        );
      }).toList(),
    ).then((selected) async {
      if (selected != null && selected != _status) {
        if (selected == 'done') {
          final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
          if (pendingTasks.isNotEmpty) {
            // Ask to mark all as done
            final shouldMarkAll = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Complete Goal?'),
                content: Text(
                  'You have ${pendingTasks.length} pending tasks. Mark all as completed too?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Only mark Goal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Mark all Done'),
                  ),
                ],
              ),
            );

            if (shouldMarkAll == true) {
              for (final task in pendingTasks) {
                final payload = core_task.Task(
                  id: task.id,
                  userId: task.userId ?? '',
                  title: task.title,
                  dueDate: task.dueDate,
                  isCompleted: true,
                  priority: task.priority,
                  status: 'done',
                  createdAt: task.createdAt,
                  updatedAt: DateTime.now(),
                  customProperties: task.customProperties,
                );
                await ref.read(goalsRepositoryProvider).updateTask(payload);
              }
            }
          }
        }

        setState(() => _status = selected);
        _saveGoal();
      }
    });
  }

  Future<void> _showDateRangePicker() async {
    final picked = await AppDatePickerSheet.showRange(
      context: context,
      title: 'Goal Timeline',
      subtitle: 'Adjust your goal deadlines',
      initialRange: DateTimeRange(start: _startDate, end: _endDate ?? _startDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _saveGoal();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'doing':
        return Colors.blue;
      case 'completed':
      case 'done':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatWesternDate(DateTime date) {
    String suffix = 'th';
    final day = date.day;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    return DateFormat("MMMM d'$suffix', yyyy").format(date);
  }

  String _getFormattedDateRange() {
    if (_endDate == null || isSameDay(_startDate, _endDate)) {
      return _formatWesternDate(_startDate);
    }

    // For range, if same year, simplify
    if (_startDate.year == _endDate!.year) {
      final startPart = DateFormat("MMM d").format(_startDate);

      // Add suffix for start
      String startSuffix = 'th';
      final sd = _startDate.day;
      if (!(sd >= 11 && sd <= 13)) {
        switch (sd % 10) {
          case 1:
            startSuffix = 'st';
            break;
          case 2:
            startSuffix = 'nd';
            break;
          case 3:
            startSuffix = 'rd';
            break;
        }
      }

      final endPart = DateFormat("MMM d").format(_endDate!);
      String endSuffix = 'th';
      final ed = _endDate!.day;
      if (!(ed >= 11 && ed <= 13)) {
        switch (ed % 10) {
          case 1:
            endSuffix = 'st';
            break;
          case 2:
            endSuffix = 'nd';
            break;
          case 3:
            endSuffix = 'rd';
            break;
        }
      }

      return "$startPart$startSuffix - $endPart$endSuffix, ${_startDate.year}";
    }

    return "${DateFormat("MMM d").format(_startDate)} - ${DateFormat("MMM d, yyyy").format(_endDate!)}";
  }

  // ─── Field dialogs ───

  // _showAddFieldDialog and _showEditFieldDialog hidden for MVP (used only by custom properties editor)
  // void _showAddFieldDialog() => _showFieldDialog();
  // void _showEditFieldDialog(CustomProperty property) => _showFieldDialog(existing: property);

  // _showFieldDialog hidden for MVP — uncomment when custom properties UX is restored

  // ─── Serialization ───

  void _loadGoalTaskFieldDefinitions() {
    final rawList = _goalCustomPropertiesBase['task_fields'];
    if (rawList is! List) return;

    _customProperties.clear();
    for (final item in rawList) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final rawType = (map['type'] ?? 'text').toString();
      final type = PropertyType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => PropertyType.text,
      );
      _customProperties.add(
        CustomProperty(
          id: (map['id'] ?? DateTime.now().microsecondsSinceEpoch.toString())
              .toString(),
          name: (map['name'] ?? '').toString(),
          type: type,
          value: null,
          options: map['options'] is List
              ? (map['options'] as List).map((e) => e.toString()).toList()
              : null,
        ),
      );
    }
  }

  TaskModel _taskModelFromRow(Map<String, dynamic> row) {
    Map<String, dynamic>? custom;
    final raw = row['custom_properties'];
    if (raw != null) {
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) custom = decoded;
        } catch (_) {}
      } else if (raw is Map<String, dynamic>) {
        custom = raw;
      }
    }

    return TaskModel(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      goalId: row['goal_id'] as String?,
      phaseId: row['phase_id'] as String?,
      title: row['title'] as String,
      dueDate: parseOptionalDateTime(row['due_date'] as String?),
      isCompleted: (row['is_completed'] as int?) == 1,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      priority: row['priority'] as String?,
      customProperties: custom,
    );
  }

  Phase _phaseFromRow(Map<String, dynamic> row) {
    return Phase(
      id: row['id'] as String,
      goalId: row['goal_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      orderIndex: row['order_index'] as int? ?? 0,
      startDate: row['start_date'] != null
          ? DateTime.parse(row['start_date'] as String)
          : DateTime.now(),
      endDate: row['end_date'] != null
          ? DateTime.parse(row['end_date'] as String)
          : DateTime.now(),
      status: row['status'] as String? ?? 'active',
    );
  }
}
