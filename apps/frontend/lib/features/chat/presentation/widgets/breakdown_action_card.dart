import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/features/chat/presentation/widgets/action_cards.dart';

/// Breakdown Action Card — AI breaks down a goal into milestones with timeline.
/// User can "Add all" milestones as goals/tasks.
class BreakdownActionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? sourceMessageId;
  final Function(List<Map<String, dynamic>>) onAddAll;

  const BreakdownActionCard({
    super.key,
    required this.data,
    required this.onAddAll,
    this.sourceMessageId,
  });

  @override
  State<BreakdownActionCard> createState() => _BreakdownActionCardState();
}

class _BreakdownActionCardState extends State<BreakdownActionCard>
    with SingleTickerProviderStateMixin {
  bool _isAdded = false;

  @override
  Widget build(BuildContext context) {
    final goalTitle = widget.data['goal_title'] ?? 'Untitled Goal';
    final milestones = (widget.data['milestones'] as List?) ?? [];

    return ChatActionCard(
      category: 'Strategic Plan',
      title: goalTitle,
      icon: LucideIcons.target,
      showCategory: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(milestones.length, (index) {
            final milestone = milestones[index] as Map<String, dynamic>;
            final isLast = index == milestones.length - 1;

            return _buildMilestoneItem(
              context,
              milestone,
              index + 1,
              isLast,
              depth: 0,
            );
          }),
          const SizedBox(height: 16),
          if (!_isAdded)
            _buildAddButton(context, milestones, goalTitle)
          else
            _buildSuccessIndicator(context),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildAddButton(
    BuildContext context,
    List milestones,
    String goalTitle,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() => _isAdded = true);
          final allActions = <Map<String, dynamic>>[];

          // 🚀 Start by creating the parent Goal
          allActions.add({
            'action': 'create_goal',
            'data': {
              'title': goalTitle,
            },
          });

          void processMilestone(Map<String, dynamic> m) {
            allActions.add({
              'action': 'create_task',
              'data': {
                'title': m['title'],
                'description': 'Milestone for: $goalTitle',
                'due_date': m['deadline'],
              },
            });
            final subs = (m['subtasks'] as List?) ?? [];
            for (var s in subs) {
              processMilestone(s as Map<String, dynamic>);
            }
          }

          for (var m in milestones) {
            processMilestone(m as Map<String, dynamic>);
          }
          widget.onAddAll(allActions);
        },
        icon: const Icon(LucideIcons.plus, size: 14),
        label: Text('Add all ${milestones.length} milestones to Plan'),
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
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Plan has been synchronized',
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

  Widget _buildMilestoneItem(
    BuildContext context,
    Map<String, dynamic> milestone,
    int number,
    bool isLast, {
    int depth = 0,
  }) {
    final title = milestone['title'] ?? '';
    final deadline = milestone['deadline'] != null
        ? DateTime.tryParse(milestone['deadline'])
        : null;
    final subtasks = (milestone['subtasks'] as List?) ?? [];
    final isSubtask = depth > 0;
    final themeColor = const Color(0xFF4C8CFF);
    final dotSize = isSubtask ? 10.0 : 20.0;
    final leftPadding = 32.0;

    return Container(
      margin: EdgeInsets.only(left: depth * 16.0),
      child: Stack(
        children: [
          // 1. The vertical line (only if not last or has subtasks)
          if (!isLast || subtasks.isNotEmpty)
            Positioned(
              left: (leftPadding / 2) - 0.75, // Center of the dot column
              top: 10, // Start below the center of the first dot
              bottom: 0,
              child: Container(
                width: 1.5,
                color: AppPallete.getBorderColor(
                  context,
                ).withValues(alpha: 0.2),
              ),
            ),

          // 2. The Content
          Padding(
            padding: EdgeInsets.only(left: leftPadding, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSubtask ? 13 : 15,
                    fontWeight: isSubtask ? FontWeight.w500 : FontWeight.w700,
                    color: isSubtask
                        ? AppPallete.getTextSecondary(context)
                        : AppPallete.getTextPrimary(context),
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
                if (deadline != null && !isSubtask) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 11,
                        color: AppPallete.getTextMuted(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM dd').format(deadline),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ],
                // Render subtasks recursively
                if (subtasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...subtasks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final sub = entry.value as Map<String, dynamic>;
                    final isLastSub = i == subtasks.length - 1;
                    return _buildMilestoneItem(
                      context,
                      sub,
                      i + 1,
                      isLastSub,
                      depth: depth + 1,
                    );
                  }),
                ],
              ],
            ),
          ),

          // 3. The Dot (Layered on top)
          Positioned(
            left: (leftPadding / 2) - (dotSize / 2),
            top: 4, // Align with the first line of text
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isSubtask
                    ? AppPallete.getSurface(context)
                    : themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withValues(alpha: isSubtask ? 0.4 : 0.8),
                  width: isSubtask ? 1.5 : 2,
                ),
              ),
              child: !isSubtask
                  ? Center(
                      child: Text(
                        '$number',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: themeColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
