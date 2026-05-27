import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class GoalDetailsTab extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController currentStateController;
  final TextEditingController statusController;
  final FocusNode titleFocusNode;
  final FocusNode descriptionFocusNode;
  final FocusNode currentStateFocusNode;
  final FocusNode statusFocusNode;

  final String title;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;

  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onCurrentStateChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback? onClearEndDate;

  final Widget? customPropertiesEditor; // hidden for MVP

  const GoalDetailsTab({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.currentStateController,
    required this.statusController,
    required this.titleFocusNode,
    required this.descriptionFocusNode,
    required this.currentStateFocusNode,
    required this.statusFocusNode,
    required this.title,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onCurrentStateChanged,
    required this.onStatusChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClearEndDate,
    this.customPropertiesEditor, // nullable — hidden for MVP
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Notion-Style Header: Large Title
        TextField(
          controller: titleController,
          focusNode: titleFocusNode,
          onChanged: onTitleChanged,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppPallete.getTextPrimary(context),
            letterSpacing: -0.8,
          ),
          decoration: InputDecoration(
            hintText: 'Untitled',
            hintStyle: TextStyle(
              color: AppPallete.getTextMuted(context).withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        const SizedBox(height: 12),
        // Property List Section
        _buildPropertyRow(
          context,
          icon: Icons.donut_large,
          label: 'Status',
          child: _buildMinimalSelectField(
            context,
            value: status,
            options: ['active', 'completed', 'archived', 'on_hold'],
            onChanged: onStatusChanged,
          ),
        ),
        const SizedBox(height: 8),
        _buildPropertyRow(
          context,
          icon: Icons.calendar_today_outlined,
          label: 'Start Date',
          child: _buildMinimalDateField(
            context,
            value: startDate,
            onTap: onPickStartDate,
          ),
        ),
        const SizedBox(height: 8),
        _buildPropertyRow(
          context,
          icon: Icons.event,
          label: 'End Date',
          child: _buildMinimalDateField(
            context,
            value: endDate,
            placeholder: 'Empty',
            onTap: onPickEndDate,
            onClear: onClearEndDate,
          ),
        ),
        const SizedBox(height: 16),
        Divider(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
        const SizedBox(height: 16),
        // Notes Section
        _buildPropertyRow(
          context,
          icon: Icons.description_outlined,
          label: 'Description',
          child: _buildMinimalTextField(
            context,
            controller: descriptionController,
            focusNode: descriptionFocusNode,
            hint: 'Add a description...',
            maxLines: null,
            onChanged: onDescriptionChanged,
          ),
        ),
        const SizedBox(height: 12),
        _buildPropertyRow(
          context,
          icon: Icons.notes_rounded,
          label: 'State',
          child: _buildMinimalTextField(
            context,
            controller: currentStateController,
            focusNode: currentStateFocusNode,
            hint: 'Current state summary...',
            maxLines: null,
            onChanged: onCurrentStateChanged,
          ),
        ),
        const SizedBox(height: 16),
        if (customPropertiesEditor != null) customPropertiesEditor!,
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPropertyRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppPallete.getTextMuted(context).withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPallete.getTextMuted(
                      context,
                    ).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 24),
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalTextField(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required ValueChanged<String> onChanged,
    int? maxLines = 1,
    TextStyle? style,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 1,
      maxLines: maxLines,
      onChanged: onChanged,
      style:
          style ??
          TextStyle(
            fontSize: 14,
            color: AppPallete.getTextPrimary(context),
            height: 1.4,
          ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppPallete.getTextMuted(context).withValues(alpha: 0.5),
        ),
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildMinimalDateField(
    BuildContext context, {
    DateTime? value,
    String placeholder = 'Empty',
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value != null
                  ? '${value.day}/${value.month}/${value.year}'
                  : placeholder,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value != null
                    ? AppPallete.getTextPrimary(context).withValues(alpha: 0.8)
                    : AppPallete.getTextMuted(context).withValues(alpha: 0.5),
              ),
            ),
            if (value != null && onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppPallete.getTextMuted(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalSelectField(
    BuildContext context, {
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return InkWell(
      onTap: () {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(Offset.zero);
        showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx + 100,
            offset.dy + 200,
            offset.dx + 300,
            offset.dy + 400,
          ),
          items: options
              .map(
                (opt) => PopupMenuItem(
                  value: opt,
                  child: _buildTagChip(opt, color: _getStatusColor(opt)),
                ),
              )
              .toList(),
        ).then((picked) {
          if (picked != null) onChanged(picked);
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: _buildTagChip(value),
    );
  }

  Widget _buildTagChip(String text, {Color? color}) {
    final bgColor = color ?? _getStatusColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: bgColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
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
      case 'on_hold':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
