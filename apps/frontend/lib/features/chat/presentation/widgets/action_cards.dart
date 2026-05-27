import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/features/chat/presentation/widgets/charts/bar_chart_view.dart';
import 'package:frontend/features/chat/presentation/widgets/charts/line_chart_view.dart';
import 'package:frontend/features/chat/presentation/widgets/charts/pie_chart_view.dart';


import 'package:frontend/features/chat/presentation/widgets/breakdown_action_card.dart';
import 'package:frontend/features/chat/presentation/widgets/insight_action_card.dart';
import 'package:frontend/features/chat/presentation/widgets/focus_action_card.dart';
import 'package:frontend/features/chat/presentation/widgets/reschedule_action_card.dart';
import 'package:frontend/features/chat/presentation/widgets/reflection_action_card.dart';

/// A factory widget that returns the appropriate Action Card based on the action type.
class ActionCardFactory extends StatelessWidget {
  final Map<String, dynamic> action;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;
  final bool isCompact;
  final Function(String taskId, bool isCompleted)? onToggleTask;
  final String? sourceMessageId;
  final Function(List<Map<String, dynamic>>, String sourceMessageId)? onBatchAction;
  final VoidCallback? onNavigate;

  const ActionCardFactory({
    super.key,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
    this.isCompact = false,
    this.onToggleTask,
    this.sourceMessageId,
    this.onBatchAction,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final type = (action['type'] ?? action['action'] ?? '').toString().toUpperCase();
    
    // Robust data extraction with defensive parsing for stringified JSON
    Map<String, dynamic> _parseData(dynamic val) {
      if (val == null) return {};
      if (val is Map<String, dynamic>) return val;
      if (val is String && val.trim().isNotEmpty) {
        try {
          return Map<String, dynamic>.from(jsonDecode(val));
        } catch (e) {
          debugPrint('❌ ActionCardFactory: Failed to decode string data: $e');
        }
      }
      return {};
    }

    final rawData = action['data'] ?? 
                    action['breakdown_data'] ?? 
                    action['insight_data'] ?? 
                    action['focus_data'] ?? 
                    action['reschedule_data'] ?? 
                    action['reflection_data'] ?? 
                    action['chart_data'] ?? 
                    action;
                    
    final data = _parseData(rawData);

    if (type.contains('BREAKDOWN')) {
      return BreakdownActionCard(
        data: data,
        sourceMessageId: sourceMessageId,
        onAddAll: (actions) {
          if (onBatchAction != null && sourceMessageId != null) {
            onBatchAction!(actions, sourceMessageId!);
          } else {
            onConfirm(action);
          }
        },
      );
    } else if (type.contains('INSIGHT')) {
      return InsightActionCard(data: data);
    } else if (type.contains('FOCUS')) {
      return FocusActionCard(
        data: data,
        onToggle: onToggleTask ?? (taskId, isCompleted) {},
      );
    } else if (type.contains('RESCHEDULE')) {
      return RescheduleActionCard(
        data: data,
        sourceMessageId: sourceMessageId,
        onAcceptAll: (actions) {
          if (onBatchAction != null && sourceMessageId != null) {
            onBatchAction!(actions, sourceMessageId!);
          } else {
            onConfirm(action);
          }
        },
      );
    } else if (type.contains('REFLECTION')) {
      return ReflectionActionCard(
        data: data,
        onNavigate: onNavigate,
      );
    } else if (type.contains('TASK')) {
      return TaskActionCard(
        action: action,
        data: data,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isCompact: isCompact,
      );
    } else if (type.contains('GOAL')) {
      return GoalActionCard(
        action: action,
        data: data,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isCompact: isCompact,
      );
    } else if (type.contains('EVENT')) {
      return EventActionCard(
        action: action,
        data: data,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isCompact: isCompact,
      );
    } else if (type.contains('INSIGHT_PRODUCTIVITY')) {
      return ProductivityInsightCard(data: data);
    } else if (type.contains('CHART') || type.contains('ANALYTICS')) {
      return DynamicChartWidget(data: data);
    }

    // Fallback to a generic card if type is unknown
    return GenericActionCard(
      action: action,
      data: data,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Helpers to identify if a card type is purely informational (non-mutating).
  static bool isInformational(String type) {
    final t = type.toUpperCase();
    return t.contains('CHART') ||
        t.contains('ANALYTICS') ||
        t.contains('INSIGHT') ||
        t.contains('FOCUS') ||
        t.contains('REFLECTION') ||
        t.contains('BREAKDOWN') ||
        t.contains('RESCHEDULE');
  }



}

// --- Standardized Base Card ---

class ChatActionCard extends StatelessWidget {
  final String category;
  final String title;
  final IconData icon;
  final Color? accentColor;
  final Widget child;
  final List<Widget>? actions;
  final bool showCategory;

  const ChatActionCard({
    super.key,
    required this.category,
    required this.title,
    required this.icon,
    this.accentColor,
    required this.child,
    this.actions,
    this.showCategory = true,
  });


  @override
  Widget build(BuildContext context) {
    final themeAccent = accentColor ?? AppPallete.getPrimaryColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(AppPallete.cardRadius),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.8),
        ),
        boxShadow: AppPallete.getDynamicSoftShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                if (showCategory) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 14, color: themeAccent),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showCategory) ...[
                        Text(
                          category.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppPallete.getTextMuted(context),
                          ),
                        ),
                        const SizedBox(height: 1),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppPallete.getTextSecondary(context),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),

          // Action Buttons
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Specialized Cards ---

class TaskActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;
  final bool isCompact;

  const TaskActionCard({
    super.key,
    required this.action,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled Task';
    final priority = (data['priority'] ?? 'medium').toString().toLowerCase();
    final dueDate = data['due_date'] != null ? DateTime.tryParse(data['due_date']) : null;
    final priorityColor = AppPallete.getPriorityColor(priority);

    return ChatActionCard(
      category: 'New Task',
      title: 'AI Suggested Task',
      icon: LucideIcons.list_todo,
      accentColor: priorityColor,
      showCategory: false,
      actions: isCompact ? null : [
        TextButton(
          onPressed: onCancel,
          child: Text("Dismiss", style: TextStyle(color: AppPallete.getTextMuted(context))),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onConfirm(action),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPallete.getPrimaryColor(context),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text("Create Task"),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetaTag(
                context, 
                priority.toUpperCase(), 
                priorityColor,
                LucideIcons.flag,
              ),
              if (dueDate != null) ...[
                const SizedBox(width: 8),
                _buildMetaTag(
                  context, 
                  DateFormat('MMM dd, HH:mm').format(dueDate), 
                  AppPallete.getTextMuted(context),
                  LucideIcons.calendar,
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMetaTag(BuildContext context, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class GoalActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;
  final bool isCompact;

  const GoalActionCard({
    super.key,
    required this.action,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled Goal';
    final progress = (data['progress'] ?? 0.0) as double;
    final themeColor = AppPallete.getPrimaryColor(context);

    return ChatActionCard(
      category: 'Goal Update',
      title: 'Current Progress',
      icon: LucideIcons.target,
      accentColor: themeColor,
      showCategory: false,
      actions: isCompact ? null : [
        TextButton(
          onPressed: onCancel,
          child: Text("Cancel", style: TextStyle(color: AppPallete.getTextMuted(context))),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onConfirm(action),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Update Goal"),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeColor, themeColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "${(progress * 100).toInt()}%",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class EventActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;
  final bool isCompact;

  const EventActionCard({
    super.key,
    required this.action,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled Event';
    final startTime = data['start_time'] != null ? DateTime.tryParse(data['start_time']) : null;
    final endTime = data['end_time'] != null ? DateTime.tryParse(data['end_time']) : null;
    final themeColor = const Color(0xFFEC4899); // Pink for events

    return ChatActionCard(
      category: 'Event',
      title: 'Calendar Suggestion',
      icon: LucideIcons.calendar_plus,
      accentColor: themeColor,
      showCategory: false,
      actions: isCompact ? null : [
        TextButton(
          onPressed: onCancel,
          child: Text("Dismiss", style: TextStyle(color: AppPallete.getTextMuted(context))),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onConfirm(action),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Schedule"),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                _buildTimeBox(context, "FROM", startTime, themeColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(LucideIcons.arrow_right, size: 14, color: themeColor.withValues(alpha: 0.4)),
                ),
                _buildTimeBox(context, "UNTIL", endTime, themeColor),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTimeBox(BuildContext context, String label, DateTime? time, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time != null ? DateFormat('HH:mm').format(time) : '--:--',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            time != null ? DateFormat('MMM dd').format(time) : '',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppPallete.getTextMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward-compatible alias — now delegates to DynamicChartWidget with STAT_CARD config.
class ProductivityInsightCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProductivityInsightCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Convert legacy format to new chart data format
    final completed = data['completed'] ?? 0;
    final consistency = (data['consistency'] ?? 0.0) as double;
    final isPositive = data['is_positive'] ?? true;

    final chartData = {
      'title': 'Performance Summary',
      'config': {'type': 'STAT_CARD', 'options': {'layout': 'row'}},
      'series': [
        {'label': 'Done', 'data': [{'x': 'value', 'y': completed}, {'x': 'trend', 'y': 0}]},
        {'label': 'Steadiness', 'data': [{'x': 'value', 'y': (consistency * 100).toInt()}, {'x': 'trend', 'y': 0}]},
        {'label': 'Trend', 'data': [{'x': 'value', 'y': isPositive ? 1 : 0}, {'x': 'trend', 'y': isPositive ? 10 : -10}]},
      ],
    };

    return DynamicChartWidget(data: chartData);
  }
}

/// Dynamic chart router — delegates to specific chart view widgets based on config.type.
class DynamicChartWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const DynamicChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Analytics';
    final config = data['config'] as Map<String, dynamic>? ?? {};
    final type = config['type']?.toString().toUpperCase() ?? 'BAR';

    return ChatActionCard(

      category: _categoryForType(type),
      title: title,
      icon: _iconForType(type),
      showCategory: false,
      child: _buildChartView(type),
    );

  }

  Widget _buildChartView(String type) {
    switch (type) {
      case 'BAR':
      case 'RADIAL':
      case 'STAT_CARD':
      case 'PROGRESS':
        return BarChartView(data: data);

      case 'LINE':
      case 'SPARKLINE':
        return LineChartView(data: data);
      case 'AREA':
        return LineChartView(data: data, isArea: true);
      case 'PIE':
        return PieChartView(data: data);


      default:
        return BarChartView(data: data);
    }
  }
  String _categoryForType(String type) {
    switch (type) {
      case 'BAR':
      case 'RADIAL':
      case 'STAT_CARD':
      case 'PROGRESS':
        return 'Performance';

      case 'LINE':
      case 'SPARKLINE':
      case 'AREA':
        return 'Trend';
      case 'PIE':
        return 'Distribution';
      default:
        return 'Analytics';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'LINE':
      case 'SPARKLINE':
      case 'AREA':
        return LucideIcons.trending_up;
      case 'PIE':
        return LucideIcons.chart_pie;
      case 'BAR':
      case 'RADIAL':
      case 'STAT_CARD':
      case 'PROGRESS':

      default:
        return LucideIcons.chart_bar;
    }
  }
}


class GenericActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;

  const GenericActionCard({
    super.key,
    required this.action,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final type = (action['type'] ?? action['action'] ?? '').toString();
    final isInfo = ActionCardFactory.isInformational(type);
    final title = data['title'] ?? action['type'] ?? action['action'] ?? 'Action Required';

    return ChatActionCard(
      category: isInfo ? 'Insight' : 'System Action',
      title: title,
      icon: isInfo ? LucideIcons.info : LucideIcons.circle_alert,
      accentColor: isInfo ? null : const Color(0xFFF59E0B), // Amber for alerts
      showCategory: false,
      actions: isInfo ? null : [
        TextButton(
          onPressed: onCancel,
          child: Text("Later", style: TextStyle(color: AppPallete.getTextMuted(context))),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => onConfirm(action),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPallete.getPrimaryColor(context),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Proceed"),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['description'] ?? (isInfo ? 'Viewing details.' : 'Confirm this action to proceed.'),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
