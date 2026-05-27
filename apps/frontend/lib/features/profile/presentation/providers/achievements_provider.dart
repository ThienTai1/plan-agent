import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';
import 'package:intl/intl.dart';

class AchievementItem {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? emoji;
  final String type; // 'Goal' or 'Milestone'

  AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.emoji,
    required this.type,
  });
}

class AchievementGroup {
  final String title; // e.g., "APRIL 2024"
  final List<AchievementItem> items;

  AchievementGroup({required this.title, required this.items});
}

final achievementsProvider = Provider.autoDispose<AsyncValue<List<AchievementGroup>>>((ref) {
  final goalsAsync = ref.watch(allGoalsStreamProvider);
  final phasesAsync = ref.watch(allPhasesStreamProvider);

  // Combine multiple AsyncValues into one
  if (goalsAsync is AsyncError) return AsyncError(goalsAsync.error!, goalsAsync.stackTrace!);
  if (phasesAsync is AsyncError) return AsyncError(phasesAsync.error!, phasesAsync.stackTrace!);
  if (goalsAsync is AsyncLoading || phasesAsync is AsyncLoading) return const AsyncLoading();

  final goals = goalsAsync.value ?? [];
  final phases = phasesAsync.value ?? [];

  final List<AchievementItem> items = [];

  // Add Completed Goals
  for (final Goal g in goals) {
    if (g.status == 'completed') {
      items.add(AchievementItem(
        id: g.id,
        title: g.title,
        description: 'Successfully completed this master goal.',
        date: g.updatedAt,
        emoji: g.icon,
        type: 'Goal',
      ));
    }
  }

  // Add Completed Milestones (Phases)
  for (final Phase p in phases) {
    if (p.status == 'completed') {
      items.add(AchievementItem(
        id: p.id,
        title: p.title,
        description: 'Reached an important project milestone.',
        date: p.endDate,
        type: 'Milestone',
      ));
    }
  }

  // Sort by date descending
  items.sort((a, b) => b.date.compareTo(a.date));

  // Group by month/year
  final Map<String, List<AchievementItem>> groups = {};
  for (var item in items) {
    final key = DateFormat('MMMM yyyy').format(item.date).toUpperCase();
    groups.putIfAbsent(key, () => []).add(item);
  }

  final result = groups.entries
      .map((e) => AchievementGroup(title: e.key, items: e.value))
      .toList();

  return AsyncValue.data(result);
});
