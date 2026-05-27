import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/common/widgets/app_empty_state.dart';
import 'package:frontend/core/common/widgets/app_scaffold.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/goal_model.dart';
import 'package:frontend/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_card.dart';
import 'package:frontend/features/goals/presentation/widgets/create_goal_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/presentation/providers/filter_providers.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_filter_sheet.dart';

class GoalsListPage extends ConsumerStatefulWidget {
  static const String routeName = '/goals';

  const GoalsListPage({super.key});

  @override
  ConsumerState<GoalsListPage> createState() => _GoalsListPageState();
}

class _GoalsListPageState extends ConsumerState<GoalsListPage> {
  String? _selectedGoalId;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(allGoalsProvider);
    final GoalFilterState filter = ref.watch(goalFilterProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    return AppScaffold(
      backgroundColor: Colors.transparent,
      safeAreaBottom: false,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      body: SafeArea(
        bottom: false,
        child: goalsAsync.when(
          data: (entries) {
            final allGoals = entries.map(_goalModelFromRow).toList();

            final normalizedQuery = _query.trim().toLowerCase();
            final filtered = allGoals.where((g) {
              final matchesQuery = normalizedQuery.isEmpty
                  ? true
                  : g.title.toLowerCase().contains(normalizedQuery);

              final matchesStatus = switch (filter.status) {
                GoalStatusFilter.active => g.status == 'active',
                GoalStatusFilter.completed =>
                  g.status == 'completed' || g.status == 'done',
                GoalStatusFilter.archived => g.status == 'archived',
                GoalStatusFilter.all => true,
              };

              return matchesQuery && matchesStatus;
            }).toList();

            final headerLabel = switch (filter.status) {
              GoalStatusFilter.active => 'Active',
              GoalStatusFilter.completed => 'Done',
              GoalStatusFilter.archived => 'Archived',
              GoalStatusFilter.all => 'Total',
            };

            final goals = filtered;
            if (goals.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GoalsHeader(count: goals.length, label: headerLabel),
                  _GoalsToolbar(
                    controller: _searchController,
                    onQueryChanged: (v) => setState(() => _query = v),
                  ),
                  Expanded(
                    child: AppEmptyState(
                      title: normalizedQuery.isEmpty
                          ? 'No goals on the horizon.'
                          : 'No matching goals found.',
                      subtitle: normalizedQuery.isEmpty
                          ? 'Start by creating a goal, then break it down into actionable tasks.'
                          : 'Try adjusting your search or filters.',
                    ),
                  ),
                ],
              );
            }

            if (!isDesktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GoalsHeader(count: goals.length, label: headerLabel),
                  _GoalsToolbar(
                    controller: _searchController,
                    onQueryChanged: (v) => setState(() => _query = v),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        140,
                      ), // Increased for nav bar clearance
                      itemCount: goals.length,
                      itemBuilder: (context, index) =>
                          GoalCard(goal: goals[index]),
                    ),
                  ),
                ],
              );
            }

            if (_selectedGoalId == null && goals.isNotEmpty) {
              _selectedGoalId = goals.first.id;
            }

            GoalModel? selectedGoal;
            if (_selectedGoalId != null) {
              for (final g in goals) {
                if (g.id == _selectedGoalId) {
                  selectedGoal = g;
                  break;
                }
              }
            }

            return Row(
              children: [
                SizedBox(
                  width: 360,
                  child: Column(
                    children: [
                      _GoalsHeader(count: goals.length, label: headerLabel),
                      _GoalsToolbar(
                        controller: _searchController,
                        onQueryChanged: (v) => setState(() => _query = v),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            final goal = goals[index];
                            return GoalCard(
                              goal: goal,
                              isSelected: goal.id == _selectedGoalId,
                              onTap: () {
                                setState(() => _selectedGoalId = goal.id);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: AppPallete.getBorderColor(
                    context,
                  ).withValues(alpha: 0.1),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: selectedGoal == null
                        ? _EmptyDetail()
                        : GoalDetailPage(goal: selectedGoal, embedded: true),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              AppEmptyState(title: 'Could not load goals', subtitle: '$err'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goals_list_fab',
        onPressed: () {
          CreateGoalModal.show(context);
        },
        backgroundColor: AppPallete.getPrimaryColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

GoalModel _goalModelFromRow(Map<String, dynamic> row) {
  return GoalModel(
    id: row['id'] as String,
    userId: row['user_id'] as String? ?? '',
    title: row['title'] as String,
    currentState: row['current_state'] as String?,
    startDate: DateTime.parse(row['start_date'] as String),
    endDate: parseOptionalDateTime(row['end_date'] as String?),
    status: row['status'] as String,
    icon: row['icon'] as String?,
    createdAt: row['created_at'] != null
        ? DateTime.parse(row['created_at'] as String)
        : DateTime.now(),
    updatedAt:
        parseOptionalDateTime(row['updated_at'] as String?) ?? DateTime.now(),
    customProperties: parseCustomProperties(row),
  );
}

class _GoalsHeader extends StatelessWidget {
  final int count;
  final String label;

  const _GoalsHeader({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'All Goals',
            style: GoogleFonts.jetBrainsMono(
              fontSize: AppFontSizes.heading,
              fontWeight: FontWeight.w800,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -1.0,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count $label',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppPallete.getPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsToolbar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  const _GoalsToolbar({required this.controller, required this.onQueryChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppPallete.getSurfaceContainerLow(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppPallete.getBorderColor(
                    context,
                  ).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search goals',
                  hintStyle: TextStyle(
                    color: AppPallete.getTextMuted(context),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.tune, color: AppPallete.getTextPrimary(context)),
            onPressed: () => GoalFilterSheet.show(context),
          ),
        ],
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.8),
        ),
      ),
      child: Center(
        child: Text(
          'Select a goal to view details',
          style: TextStyle(
            color: AppPallete.getTextSecondary(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
