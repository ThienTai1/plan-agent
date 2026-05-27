import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/chat/presentation/widgets/action_cards.dart';

/// Reschedule Action Card — Shows overdue tasks with suggested new dates.
/// User can "Accept all" to batch-reschedule.
class RescheduleActionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? sourceMessageId;
  final Function(List<Map<String, dynamic>>) onAcceptAll;

  const RescheduleActionCard({
    super.key,
    required this.data,
    required this.onAcceptAll,
    this.sourceMessageId,
  });

  @override
  State<RescheduleActionCard> createState() => _RescheduleActionCardState();
}

class _RescheduleActionCardState extends State<RescheduleActionCard> {
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    final overdueTasks = (widget.data['overdue_tasks'] as List?) ?? [];

    return ChatActionCard(
      category: 'Correction',
      title: '${overdueTasks.length} Overdue Items',
      icon: LucideIcons.refresh_ccw,
      accentColor: const Color(0xFF4C8CFF),
      showCategory: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...overdueTasks.map((t) => _buildRescheduleItem(context, t as Map<String, dynamic>)).toList(),
          const SizedBox(height: 16),
          if (!_isAccepted)
            _buildAcceptButton(context, overdueTasks)
          else
            _buildSuccessIndicator(context),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildAcceptButton(BuildContext context, List overdueTasks) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() => _isAccepted = true);
          final actions = overdueTasks.map((t) {
            final task = t as Map<String, dynamic>;
            return {
              'action': 'update_task',
              'data': {
                'task_id': task['task_id'],
                'due_date': task['suggested_due'],
              },
            };
          }).toList();
          widget.onAcceptAll(actions);
        },
        icon: const Icon(LucideIcons.calendar_check_2, size: 14),
        label: Text('Sync all ${overdueTasks.length} suggested dates'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C8CFF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIndicator(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Timeline corrected and synced',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescheduleItem(
    BuildContext context,
    Map<String, dynamic> task,
  ) {
    final title = task['title'] ?? '';
    final originalDue = task['original_due'] != null
        ? DateTime.tryParse(task['original_due'])
        : null;
    final suggestedDue = task['suggested_due'] != null
        ? DateTime.tryParse(task['suggested_due'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.getSurfaceContainerLow(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Use a more elegant side-by-side transition
              _buildDatePill(
                context, 
                originalDue, 
                isOld: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  LucideIcons.arrow_right_left,
                  size: 14,
                  color: AppPallete.getTextMuted(context).withValues(alpha: 0.5),
                ),
              ),
              _buildDatePill(
                context, 
                suggestedDue, 
                isOld: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePill(BuildContext context, DateTime? date, {required bool isOld}) {
    final color = isOld ? Colors.red : const Color(0xFF10B981);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              isOld ? "WAS" : "TO",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date != null ? DateFormat('MMM dd').format(date) : '--',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isOld ? FontWeight.w500 : FontWeight.w700,
                color: color,
                decoration: isOld ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

