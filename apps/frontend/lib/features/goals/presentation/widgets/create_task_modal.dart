import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/features/goals/presentation/providers/tasks_notifier.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart' as domain_providers;
import 'package:frontend/features/goals/presentation/widgets/custom_properties_view.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/core/common/widgets/app_date_picker_sheet.dart';
import 'package:frontend/features/goals/presentation/widgets/task_phase_option.dart';

class CreateTaskModal extends ConsumerStatefulWidget {
  final bool initialIsEvent;
  final String? initialGoalId;
  final List<CustomProperty> goalFieldDefinitions;
  final List<TaskPhaseOption> phaseOptions;
  final String? initialPhaseId;
  final String? initialParentTaskId;

  const CreateTaskModal({
    super.key,
    this.initialIsEvent = false,
    this.initialGoalId,
    this.goalFieldDefinitions = const [],
    this.phaseOptions = const [],
    this.initialPhaseId,
    this.initialParentTaskId,
  });

  @override
  ConsumerState<CreateTaskModal> createState() => _CreateTaskModalState();
}

class _CreateTaskModalState extends ConsumerState<CreateTaskModal> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEvent;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTimeRange? _selectedRange;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late final List<CustomProperty> _goalFields;
  final Map<String, dynamic> _goalFieldValues = {};
  String? _selectedPhaseId;
  String? _priority = 'medium';

  @override
  void initState() {
    super.initState();
    _isEvent = widget.initialIsEvent;
    _selectedRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    _goalFields = widget.goalFieldDefinitions
        .map(
          (field) => CustomProperty(
            id: field.id,
            name: field.name,
            type: field.type,
            value: null,
            options: field.options == null
                ? null
                : List<String>.from(field.options!),
          ),
        )
        .toList();
    _selectedPhaseId = widget.initialPhaseId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await AppDatePickerSheet.showRange(
      context: context,
      title: 'Schedule',
      subtitle: 'When should this be completed?',
      initialRange: _selectedRange,
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      if (_isEvent && (_startTime == null || _endTime == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end time')),
        );
        return;
      }

      final range = _selectedRange ?? DateTimeRange(start: now, end: now);
      final startDate = range.start;
      final endDate = range.end;

      DateTime? endDateTime;

      if (_isEvent) {
        endDateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      } else {
        endDateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
        );
      }

      Map<String, dynamic>? custom = _serializeCustomProperties();
      if (!_isEvent) {
        custom ??= {};
        custom['start_time'] = startDate.toIso8601String();
      }

      final task = Task(
        id: const Uuid().v4(),
        userId: ref.read(appUserNotifierProvider)?.id ?? '',
        goalId: widget.initialGoalId,
        phaseId: _selectedPhaseId,
        parentTaskId: widget.initialParentTaskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: endDateTime,
        isCompleted: false,
        priority: _priority,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customProperties: custom,
      );

      await ref.read(tasksNotifierProvider.notifier).createTask(task);
      
      final taskState = ref.read(tasksNotifierProvider);
      
      if (taskState.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(taskState.error.toString()),
              backgroundColor: AppPallete.errorColor,
            ),
          );
        }
        return;
      }

      ref.invalidate(allTasksProvider);
      if (widget.initialGoalId != null) {
        ref.invalidate(tasksByGoalProvider(widget.initialGoalId!));
        ref.invalidate(goalTaskStatsProvider(widget.initialGoalId!));
      }
      ref.invalidate(domain_providers.allTasksProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_isEvent ? "Event" : "Task"} created successfully!',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(tasksNotifierProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppPallete.getBackgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEvent ? 'New Event' : 'New Task',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: AppPallete.getTextPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'What needs to be done?',
                      hintStyle: TextStyle(
                        color: AppPallete.getTextMuted(context),
                      ),
                      filled: true,
                      fillColor: AppPallete.getSecondarySurface(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: AppPallete.getTextPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Add details...',
                      hintStyle: TextStyle(
                        color: AppPallete.getTextMuted(context),
                      ),
                      filled: true,
                      fillColor: AppPallete.getSecondarySurface(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppPallete.getSecondarySurface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppPallete.getBorderColor(context).withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: AppPallete.getPrimaryColor(context),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppPallete.getTextSecondary(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedRange == null
                                      ? 'Select Schedule'
                                      : "${DateFormat.yMMMd().format(_selectedRange!.start)} - ${DateFormat.yMMMd().format(_selectedRange!.end)}",
                                  style: TextStyle(
                                    color: AppPallete.getTextPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isEvent) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppPallete.getBorderColor(context),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 20,
                                    color: AppPallete.getTextSecondary(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _startTime == null
                                          ? 'Start'
                                          : _startTime!.format(context),
                                      style: TextStyle(
                                        color: AppPallete.getTextPrimary(context),
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                            onTap: () => _selectTime(context, false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppPallete.getBorderColor(context),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 20,
                                    color: AppPallete.getTextSecondary(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _endTime == null
                                          ? 'End'
                                          : _endTime!.format(context),
                                      style: TextStyle(
                                        color: AppPallete.getTextPrimary(context),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  if (widget.phaseOptions.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      value: _selectedPhaseId,
                      decoration: InputDecoration(
                        labelText: 'Milestone',
                        filled: true,
                        fillColor: AppPallete.getSecondarySurface(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No milestone'),
                        ),
                        ...widget.phaseOptions.map(
                          (phase) => DropdownMenuItem<String?>(
                            value: phase.id,
                            child: Text(phase.title),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPhaseId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  _buildPriorityRow(),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.getPrimaryColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEvent ? 'Create Event' : 'Create Task',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppPallete.getTextMuted(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPriorityRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppPallete.getSecondarySurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag_rounded,
            size: 18,
            color: AppPallete.getTextSecondary(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Priority',
              style: TextStyle(
                color: AppPallete.getTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _priority,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (value) {
                setState(() {
                  _priority = value == 'none' ? null : value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _serializeCustomProperties() {
    if (_goalFieldValues.isEmpty) {
      return null;
    }

    final data = <String, dynamic>{};
    for (final field in _goalFields) {
      final key = field.name.trim();
      if (key.isEmpty) continue;
      final raw = _goalFieldValues[field.id];
      if (raw == null) continue;
      data[key] = _serializePropertyValue(field.type, raw);
    }
    return data.isEmpty ? null : data;
  }

  dynamic _serializePropertyValue(PropertyType type, dynamic value) {
    if (value == null) return null;

    switch (type) {
      case PropertyType.number:
        if (value is num) return value;
        return num.tryParse(value.toString());
      case PropertyType.checkbox:
        if (value is bool) return value;
        final lower = value.toString().toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      case PropertyType.date:
        if (value is DateTime) return value.toIso8601String();
        return value.toString();
      case PropertyType.select:
      case PropertyType.text:
        return value.toString();
    }
  }
}
