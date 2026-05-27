import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/presentation/providers/filter_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class GoalFilterSheet extends ConsumerWidget {
  const GoalFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoalFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(goalFilterProvider);

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
                'Filter Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(goalFilterProvider.notifier).reset();
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
          Text(
            'STATUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextMuted(context),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterOption(
            context,
            ref,
            'All Statuses',
            GoalStatusFilter.all,
            isSelected: filter.status == GoalStatusFilter.all,
          ),
          _buildFilterOption(
            context,
            ref,
            'Active',
            GoalStatusFilter.active,
            isSelected: filter.status == GoalStatusFilter.active,
            color: Colors.blue,
          ),
          _buildFilterOption(
            context,
            ref,
            'Completed',
            GoalStatusFilter.completed,
            isSelected: filter.status == GoalStatusFilter.completed,
            color: Colors.green,
          ),
          _buildFilterOption(
            context,
            ref,
            'Archived',
            GoalStatusFilter.archived,
            isSelected: filter.status == GoalStatusFilter.archived,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
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
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    GoalStatusFilter value, {
    required bool isSelected,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          ref.read(goalFilterProvider.notifier).updateStatus(value);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppPallete.getSurfaceContainerLow(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppPallete.getPrimaryColor(context).withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppPallete.getTextPrimary(context)
                        : AppPallete.getTextSecondary(context),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: AppPallete.getPrimaryColor(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
