import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/presentation/providers/filter_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class TaskFilterSheet extends ConsumerWidget {
  const TaskFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaskFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(taskFilterProvider.notifier).reset();
                  Navigator.pop(context);
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: AppPallete.getErrorColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'STATUS'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip<TaskStatusFilter>(
                  context,
                  label: 'All',
                  value: TaskStatusFilter.all,
                  selectedValue: filter.status,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateStatus(v),
                ),
                _buildChip<TaskStatusFilter>(
                  context,
                  label: 'Todo',
                  value: TaskStatusFilter.todo,
                  selectedValue: filter.status,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateStatus(v),
                ),
                _buildChip<TaskStatusFilter>(
                  context,
                  label: 'In Progress',
                  value: TaskStatusFilter.inProgress,
                  selectedValue: filter.status,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateStatus(v),
                ),
                _buildChip<TaskStatusFilter>(
                  context,
                  label: 'Done',
                  value: TaskStatusFilter.done,
                  selectedValue: filter.status,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateStatus(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'PRIORITY'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip<TaskPriorityFilter>(
                  context,
                  label: 'All',
                  value: TaskPriorityFilter.all,
                  selectedValue: filter.priority,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updatePriority(v),
                ),
                _buildChip<TaskPriorityFilter>(
                  context,
                  label: 'Low',
                  value: TaskPriorityFilter.low,
                  selectedValue: filter.priority,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updatePriority(v),
                ),
                _buildChip<TaskPriorityFilter>(
                  context,
                  label: 'Medium',
                  value: TaskPriorityFilter.medium,
                  selectedValue: filter.priority,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updatePriority(v),
                ),
                _buildChip<TaskPriorityFilter>(
                  context,
                  label: 'High',
                  value: TaskPriorityFilter.high,
                  selectedValue: filter.priority,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updatePriority(v),
                ),
                _buildChip<TaskPriorityFilter>(
                  context,
                  label: 'Urgent',
                  value: TaskPriorityFilter.urgent,
                  selectedValue: filter.priority,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updatePriority(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'DATE'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip<TaskDateFilter>(
                  context,
                  label: 'All Time',
                  value: TaskDateFilter.all,
                  selectedValue: filter.date,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateDate(v),
                ),
                _buildChip<TaskDateFilter>(
                  context,
                  label: 'Today',
                  value: TaskDateFilter.today,
                  selectedValue: filter.date,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateDate(v),
                ),
                _buildChip<TaskDateFilter>(
                  context,
                  label: 'Overdue',
                  value: TaskDateFilter.overdue,
                  selectedValue: filter.date,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateDate(v),
                ),
                _buildChip<TaskDateFilter>(
                  context,
                  label: 'Upcoming',
                  value: TaskDateFilter.upcoming,
                  selectedValue: filter.date,
                  onSelected: (v) =>
                      ref.read(taskFilterProvider.notifier).updateDate(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.getPrimaryColor(context),
                foregroundColor: AppPallete.getCardColor(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppPallete.getTextMuted(context),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildChip<T>(
    BuildContext context, {
    required String label,
    required T value,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    final isSelected = value == selectedValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppPallete.getPrimaryColor(context)
                : AppPallete.getTextSecondary(context),
          ),
        ),
        selected: isSelected,
        onSelected: (selected) => onSelected(value),
        backgroundColor: AppPallete.getCardColor(context),
        selectedColor: AppPallete.getPrimaryColor(context).withValues(alpha: 0.1),
        checkmarkColor: AppPallete.getPrimaryColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? AppPallete.getPrimaryColor(context)
                : AppPallete.getBorderColor(context).withValues(alpha: 0.3),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}
