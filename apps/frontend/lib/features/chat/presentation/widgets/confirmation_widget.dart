import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:intl/intl.dart';

class ConfirmationWidget extends StatefulWidget {
  final Map<String, dynamic> pendingAction;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;

  const ConfirmationWidget({
    super.key,
    required this.pendingAction,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ConfirmationWidget> createState() => _ConfirmationWidgetState();
}

class _ConfirmationWidgetState extends State<ConfirmationWidget> {
  late Map<String, dynamic> _editedData;
  late TextEditingController _titleController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    // Initialize with a copy of the pending action's original data
    _editedData = Map<String, dynamic>.from(widget.pendingAction['data'] ?? {});
    _titleController = TextEditingController(text: _editedData['title'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String action = widget.pendingAction['action'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.getSecondarySurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getActionIcon(action),
                color: AppPallete.getPrimaryColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getActionTitle(action),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppPallete.getPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          _buildActionDetails(context, action),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPallete.getTextSecondary(context),
                    side: BorderSide(color: AppPallete.getBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final modifiedAction = Map<String, dynamic>.from(
                      widget.pendingAction,
                    );
                    modifiedAction['data'] = _editedData;
                    widget.onConfirm(modifiedAction);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.getPrimaryColor(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    if (action.contains('CREATE')) return Icons.add_task;
    if (action.contains('UPDATE')) return Icons.edit_calendar;
    if (action.contains('DELETE')) return Icons.delete_outline;
    return Icons.info_outline;
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'CREATE_TASK':
        return 'Create new task';
      case 'UPDATE_TASK':
        return 'Update task';
      case 'DELETE_TASK':
        return 'Delete task';
      case 'CREATE_EVENT':
        return 'Create new event';
      case 'UPDATE_EVENT':
        return 'Update event';
      case 'DELETE_EVENT':
        return 'Delete event';
      default:
        return 'Confirm Action';
    }
  }

  Widget _buildActionDetails(BuildContext context, String action) {
    List<Widget> details = [];

    if (action.contains('TASK')) {
      final taskData = action == 'UPDATE_TASK'
          ? _editedData['update_fields']
          : _editedData;
      if (taskData != null) {
        if (taskData['title'] != null) {
          details.add(
            _editableTitleRow(
              context,
              Icons.title,
              'Title',
              taskData['title'],
              (newVal) {
                setState(() => taskData['title'] = newVal);
              },
            ),
          );
        }
        if (taskData['due_date'] != null) {
          details.add(
            _editableDateRow(
              context,
              Icons.event,
              'Deadline',
              taskData['due_date'],
              (newVal) {
                setState(() => taskData['due_date'] = newVal);
              },
            ),
          );
        }
        // TODO: priority dropdown if needed
        if (taskData['priority'] != null) {
          details.add(
            _detailRow(
              context,
              Icons.priority_high,
              'Priority',
              taskData['priority'],
            ),
          );
        }
      }
    } else if (action.contains('EVENT')) {
      final eventData = action == 'UPDATE_EVENT'
          ? _editedData['update_fields']
          : _editedData;
      if (eventData != null) {
        if (eventData['title'] != null) {
          details.add(
            _editableTitleRow(
              context,
              Icons.title,
              'Title',
              eventData['title'],
              (newVal) {
                setState(() => eventData['title'] = newVal);
              },
            ),
          );
        }
        if (eventData['start_time'] != null) {
          details.add(
            _editableDateRow(
              context,
              Icons.access_time,
              'Start',
              eventData['start_time'],
              (newVal) {
                setState(() => eventData['start_time'] = newVal);
              },
            ),
          );
        }
        if (eventData['end_time'] != null) {
          details.add(
            _editableDateRow(
              context,
              Icons.access_time_filled,
              'End',
              eventData['end_time'],
              (newVal) {
                setState(() => eventData['end_time'] = newVal);
              },
            ),
          );
        }
      }
    }

    if (action.contains('DELETE')) {
      details.add(
        Text(
          'Are you sure you want to delete this item?',
          style: TextStyle(
            color: AppPallete.getErrorColor(context),
            fontSize: 13,
          ),
        ),
      );
    }

    return Column(children: details);
  }

  Widget _editableTitleRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(
              icon,
              size: 14,
              color: AppPallete.getTextMuted(context),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppPallete.getTextSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _titleController,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 13,
                color: AppPallete.getTextPrimary(context),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppPallete.getBorderColor(context),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppPallete.getPrimaryColor(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableDateRow(
    BuildContext context,
    IconData icon,
    String label,
    String currentIsoString,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppPallete.getTextMuted(context)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                DateTime initialDate;
                try {
                  initialDate = DateTime.parse(currentIsoString);
                } catch (_) {
                  initialDate = DateTime.now();
                }

                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );

                if (pickedDate != null && context.mounted) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(initialDate),
                  );
                  if (pickedTime != null) {
                    final finalDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    onSelected(finalDateTime.toIso8601String());
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppPallete.getBackgroundColor(context),
                  border: Border.all(color: AppPallete.getBorderColor(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(currentIsoString),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppPallete.getTextPrimary(context),
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar,
                      size: 14,
                      color: AppPallete.getPrimaryColor(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppPallete.getTextMuted(context)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return _dateFormat.format(date);
    } catch (_) {
      return isoString;
    }
  }
}
