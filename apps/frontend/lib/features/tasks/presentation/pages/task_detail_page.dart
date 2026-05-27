import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/common/domain/models/task.dart' as core_task;
import 'package:frontend/core/common/domain/models/repeat_rule.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/features/goals/presentation/widgets/custom_properties_view.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_item_widget.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/features/goals/presentation/widgets/create_task_modal.dart';
import 'package:frontend/core/common/widgets/app_card.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final TaskModel task;
  final List<CustomProperty> goalFieldDefinitions;

  const TaskDetailPage({
    super.key,
    required this.task,
    this.goalFieldDefinitions = const [],
  });

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  late Map<String, dynamic> _customPropertiesMap;
  late List<CustomProperty> _customPropertiesList;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime? _dueDate;
  late DateTime? _startTime;
  late bool _isCompleted;
  late String? _priority;
  RepeatRule? _repeatRule;
  bool _isSaving = false;
  bool _isEditingTitle = false;
  late FocusNode _titleFocusNode;

  @override
  void initState() {
    super.initState();
    _customPropertiesMap = Map.from(widget.task.customProperties ?? {});
    _titleFocusNode = FocusNode();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _dueDate = widget.task.dueDate;
    _startTime = widget.task.startTime;
    _isCompleted = widget.task.isCompleted;
    _priority = widget.task.priority;
    final rr = _customPropertiesMap['repeat_rule'];
    if (rr is Map) {
      _repeatRule = RepeatRule.fromJson(Map<String, dynamic>.from(rr));
    }
    _initCustomProperties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _initCustomProperties() {
    if (widget.goalFieldDefinitions.isEmpty) {
      _customPropertiesList = [];
      return;
    }

    _customPropertiesList = widget.goalFieldDefinitions.map((field) {
      final raw = _customPropertiesMap[field.name];
      final value = _normalizePropertyValue(raw);
      return CustomProperty(
        id: field.id,
        name: field.name,
        type: field.type,
        value: value,
        options: field.options,
      );
    }).toList();
  }

  dynamic _normalizePropertyValue(dynamic value) {
    if (value is String) {
      final date = DateTime.tryParse(value);
      if (date != null) return date;
      final number = num.tryParse(value);
      if (number != null) return number;
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return value;
  }

  Map<String, dynamic>? _serializeCustomProperties() {
    final data = Map<String, dynamic>.from(_customPropertiesMap);
    data.remove('repeat_rule');
    data.remove('start_time');

    for (final prop in _customPropertiesList) {
      final key = prop.name.trim();
      if (key.isEmpty) continue;
      final value = prop.value;
      if (value is DateTime) {
        data[key] = value.toIso8601String();
      } else {
        data[key] = value;
      }
    }
    return data.isEmpty ? null : data;
  }

  Map<String, dynamic>? _serializeCustomPropertiesWithRepeat() {
    Map<String, dynamic>? data = _serializeCustomProperties();
    if (_repeatRule != null) {
      data ??= <String, dynamic>{};
      final next = computeNextOccurrence(
        rule: _repeatRule!,
        now: DateTime.now(),
      );
      final withNext = _repeatRule!.copyWith(
        nextOccurrenceIso: next?.toIso8601String(),
      );
      data['repeat_rule'] = withNext.toJson();
    } else {
      data?.remove('repeat_rule');
    }
    return data;
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    Map<String, dynamic>? custom = _serializeCustomPropertiesWithRepeat();
    if (_startTime != null) {
      custom ??= <String, dynamic>{};
      custom['start_time'] = _startTime!.toIso8601String();
    }

    final payload = core_task.Task(
      id: widget.task.id,
      userId: ref.read(appUserNotifierProvider)?.id ?? widget.task.userId ?? '',
      goalId: widget.task.goalId,
      phaseId: widget.task.phaseId,
      title: title,
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      isCompleted: _isCompleted,
      priority: _priority,
      createdAt: widget.task.createdAt,
      updatedAt: DateTime.now(),
      customProperties: custom,
    );

    setState(() => _isSaving = true);
    final result = await ref.read(goalsRepositoryProvider).updateTask(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        // Updated successfully
      },
    );
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    final result = await ref
        .read(goalsRepositoryProvider)
        .deleteTask(widget.task.id);
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => Navigator.pop(context, true),
    );
  }

  void _showTaskActions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete task'),
              onTap: () {
                Navigator.pop(context);
                _deleteTask();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(),
                        const SizedBox(height: 24),
                        _buildPropertiesCard(),
                        const SizedBox(height: 16),
                        _buildGoalCard(),
                        const SizedBox(height: 16),
                        _buildDescriptionCard(),
                        const SizedBox(height: 24),
                        _buildSubtasksSection(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isSaving)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x55000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppPallete.getTextPrimary(context)),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.more_horiz, color: AppPallete.getTextPrimary(context)),
            onPressed: _showTaskActions,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    if (_isEditingTitle) {
      return TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        autofocus: true,
        onSubmitted: (_) {
          setState(() => _isEditingTitle = false);
          _saveTask();
        },
        onTapOutside: (_) {
          setState(() => _isEditingTitle = false);
          _saveTask();
        },
        style: GoogleFonts.jetBrainsMono(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppPallete.getTextPrimary(context),
          height: 1.2,
          letterSpacing: -1.0,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Task title',
          filled: true,
          fillColor: AppPallete.getCardColor(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppPallete.getBorderColor(context).withValues(alpha: 0.1)),
          ),
        ),
        maxLines: null,
        textInputAction: TextInputAction.done,
      );
    }

    final title = _titleController.text.trim();
    return InkWell(
      onTap: () {
        setState(() => _isEditingTitle = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _titleFocusNode.requestFocus();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          title.isEmpty ? 'Tap to add title' : title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: title.isEmpty
                ? AppPallete.getTextMuted(context)
                : AppPallete.getTextPrimary(context),
            height: 1.16,
            letterSpacing: -1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesCard() {
    return AppCard(
      child: Column(
        children: [
          _buildCompletionRow(),
          const Divider(height: 24),
          _buildPropertyRow(
            context,
            label: 'Priority',
            value: (_priority ?? 'None').toUpperCase(),
            valueColor: AppPallete.getPriorityColor(_priority),
            isPill: true,
            onTap: _showPriorityPicker,
          ),
          const SizedBox(height: 12),
          _buildPropertyRow(
            context,
            label: 'Schedule',
            value: _getFormattedSchedule(),
            onTap: _showSchedulePicker,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRow() {
    return InkWell(
      onTap: () {
        setState(() => _isCompleted = !_isCompleted);
        _saveTask();
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isCompleted
                    ? AppPallete.getPrimaryColor(context)
                    : AppPallete.getTextMuted(context).withValues(alpha: 0.5),
                width: 2,
              ),
              color: _isCompleted ? AppPallete.getPrimaryColor(context) : null,
            ),
            child: _isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            _isCompleted ? 'Completed' : 'Mark as completed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _isCompleted
                  ? AppPallete.getPrimaryColor(context)
                  : AppPallete.getTextPrimary(context),
            ),
          ),
          const Spacer(),
          if (_isCompleted)
            Icon(
              Icons.check_circle,
              size: 20,
              color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    final goalId = widget.task.goalId;
    if (goalId == null) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, child) {
        final goalAsync = ref.watch(goalByIdProvider(goalId));
        return goalAsync.when(
          data: (goal) => AppCard(
            onTap: () {
              // Navigation to goal could be added here
            },
            child: _buildPropertyRow(
              context,
              label: 'Goal',
              value: goal?['title'] ?? 'Unknown Goal',
              valueColor: AppPallete.getPrimaryColor(context),
            ),
          ),
          loading: () => const AppCard(child: Text('Loading goal...')),
          error: (_, __) => const AppCard(child: Text('Error loading goal')),
        );
      },
    );
  }

  Widget _buildDescriptionCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextMuted(context),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: AppPallete.getTextMuted(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: null,
            onChanged: (_) => _saveTask(),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppPallete.getTextPrimary(context),
            ),
            decoration: InputDecoration(
              hintText: 'Add more details...',
              hintStyle: TextStyle(color: AppPallete.getTextMuted(context)),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _showPriorityPicker() {
    final List<String> priorities = ['urgent', 'high', 'medium', 'low', 'none'];
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + 100,
        offset.dy + 150,
        offset.dx + 300,
        offset.dy + 500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: priorities.map((p) {
        return PopupMenuItem<String>(
          value: p,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: AppPallete.getPriorityColor(p),
              ),
              const SizedBox(width: 12),
              Text(p.toUpperCase()),
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null && selected != _priority) {
        setState(() => _priority = selected == 'none' ? null : selected);
        _saveTask();
      }
    });
  }

  Future<void> _showSchedulePicker() async {
    final start = _startTime ?? DateTime.now();
    final end = (_dueDate != null && !_dueDate!.isBefore(start))
        ? _dueDate!
        : start.add(const Duration(hours: 1));

    final result = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDateRangePickerSheet(
        initialRange: DateTimeRange(start: start, end: end),
        title: 'Select Schedule',
      ),
    );

    if (result != null) {
      setState(() {
        _startTime = result.start;
        _dueDate = result.end;
      });
      _saveTask();
    }
  }

  String _getFormattedSchedule() {
    final start = _startTime;
    final end = _dueDate;

    if (start == null && end == null) return 'No date';
    if (start != null && end == null) return _formatWesternDate(start);
    if (start == null && end != null) return _formatWesternDate(end);

    return _getFormattedDateRange(start!, end!);
  }

  String _formatWesternDate(DateTime date) {
    String suffix = _getDaySuffix(date.day);
    return DateFormat("MMMM d'$suffix', yyyy").format(date);
  }

  String _getFormattedDateRange(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return _formatWesternDate(start);
    }

    if (start.year == end.year) {
      final startPart = DateFormat("MMM d").format(start);
      String startSuffix = _getDaySuffix(start.day);

      final endPart = DateFormat("MMM d").format(end);
      String endSuffix = _getDaySuffix(end.day);

      return "$startPart$startSuffix - $endPart$endSuffix, ${start.year}";
    }

    return "${DateFormat("MMM d, yyyy").format(start)} - ${DateFormat("MMM d, yyyy").format(end)}";
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    return switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildPropertyRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isPill = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextMuted(context),
                ),
              ),
            ),
            isPill
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
                          fontWeight: FontWeight.w700,
                          color:
                              valueColor ?? AppPallete.getTextPrimary(context),
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            valueColor ?? AppPallete.getTextPrimary(context),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtasksSection(BuildContext context) {
    final subtasksAsync = ref.watch(tasksByParentProvider(widget.task.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
            TextButton.icon(
              onPressed: _addSubtask,
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
        const SizedBox(height: 12),
        subtasksAsync.when(
          data: (subtasks) {
            if (subtasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPallete.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppPallete.getBorderColor(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No subtasks yet',
                    style: TextStyle(
                      color: AppPallete.getTextMuted(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subtasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final dynamic subtask = subtasks[index];
                final TaskModel subtaskModel = subtask is TaskModel
                    ? subtask
                    : TaskModel(
                        id: subtask.id,
                        title: subtask.title,
                        userId: subtask.userId,
                        goalId: subtask.goalId,
                        phaseId: subtask.phaseId,
                        parentTaskId: subtask.parentTaskId,
                        dueDate: subtask.dueDate,
                        isCompleted: subtask.isCompleted,
                        priority: subtask.priority,
                        createdAt: subtask.createdAt,
                        customProperties: subtask.customProperties,
                        recurrenceRule: subtask.recurrenceRule,
                      );
                return TaskItemWidget(
                  task: subtaskModel,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          task: subtaskModel,
                          goalFieldDefinitions: widget.goalFieldDefinitions,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Text(
              'Error loading subtasks: $error',
              style: TextStyle(color: AppPallete.errorColor),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addSubtask() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskModal(
        initialGoalId: widget.task.goalId,
        initialParentTaskId: widget.task.id,
        goalFieldDefinitions: widget.goalFieldDefinitions,
      ),
    );
  }
}

class _TaskDateRangePickerSheet extends StatefulWidget {
  final DateTimeRange initialRange;
  final String title;

  const _TaskDateRangePickerSheet({
    required this.initialRange,
    this.title = 'Select Period',
  });

  @override
  State<_TaskDateRangePickerSheet> createState() =>
      _TaskDateRangePickerSheetState();
}

class _TaskDateRangePickerSheetState extends State<_TaskDateRangePickerSheet> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialRange.start;
    _rangeStart = widget.initialRange.start;
    _rangeEnd = widget.initialRange.end;
    if (_rangeStart == _rangeEnd) _rangeEnd = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppPallete.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define the schedule',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppPallete.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppPallete.getSurface(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppPallete.getTextPrimary(context),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              calendarStyle: CalendarStyle(
                rangeHighlightColor: AppPallete.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.08),
                rangeStartDecoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(context),
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(context),
                  shape: BoxShape.circle,
                ),
                withinRangeTextStyle: TextStyle(
                  color: AppPallete.getPrimaryColor(context),
                ),
                todayDecoration: BoxDecoration(
                  color: AppPallete.getSurface(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppPallete.getPrimaryColor(
                      context,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                todayTextStyle: TextStyle(
                  color: AppPallete.getPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
                weekendTextStyle: TextStyle(
                  color: AppPallete.getTextPrimary(
                    context,
                  ).withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppPallete.getSurface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppPallete.getTextSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rangeStart == null
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              DateTimeRange(
                                start: _rangeStart!,
                                end: _rangeEnd ?? _rangeStart!,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppPallete.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Range',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
