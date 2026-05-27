import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/domain/models/habit.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/features/goals/presentation/providers/habits_notifier.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(allHabitsProvider);

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Habits',
          style: GoogleFonts.jetBrainsMono(
            color: AppPallete.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              return _HabitCard(habit: habits[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: AppPallete.getTextSecondary(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new habit to build consistency.',
            style: TextStyle(
              color: AppPallete.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isCompletedToday = habit.completions.contains(todayStr);
    final streak = habit.streak;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.8),
        ),
        boxShadow: AppPallete.getDynamicSoftShadow(context),
      ),
      child: InkWell(
        onTap: () {}, // Detail view could be added later
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Completion Button/Icon
              GestureDetector(
                onTap: () {
                  ref.read(habitsNotifierProvider.notifier).toggleHabit(habit.id, DateTime.now());
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompletedToday
                        ? AppPallete.getPrimaryColor(context)
                        : AppPallete.getSurfaceContainerLow(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompletedToday ? Icons.check : Icons.add,
                    color: isCompletedToday ? Colors.white : AppPallete.getPrimaryColor(context),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Habit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habit.recurrenceRule.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPallete.getTextSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak Info
              Column(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: streak > 0 ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  Text(
                    '$streak',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: streak > 0 ? Colors.orange : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
