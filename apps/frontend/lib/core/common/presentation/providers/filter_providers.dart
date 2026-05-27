import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GoalStatusFilter { all, active, completed, archived }

class GoalFilterState {
  final GoalStatusFilter status;

  const GoalFilterState({
    this.status = GoalStatusFilter.all,
  });

  GoalFilterState copyWith({
    GoalStatusFilter? status,
  }) {
    return GoalFilterState(
      status: status ?? this.status,
    );
  }
}

class GoalFilterNotifier extends Notifier<GoalFilterState> {
  @override
  GoalFilterState build() {
    return const GoalFilterState();
  }

  void updateStatus(GoalStatusFilter status) {
    state = state.copyWith(status: status);
  }

  void reset() {
    state = const GoalFilterState();
  }
}

final goalFilterProvider = NotifierProvider<GoalFilterNotifier, GoalFilterState>(() {
  return GoalFilterNotifier();
});

enum TaskStatusFilter { all, todo, inProgress, done }

enum TaskPriorityFilter { all, low, medium, high, urgent }

enum TaskDateFilter { all, today, overdue, upcoming }

class TaskFilterState {
  final TaskStatusFilter status;
  final TaskPriorityFilter priority;
  final TaskDateFilter date;

  const TaskFilterState({
    this.status = TaskStatusFilter.all,
    this.priority = TaskPriorityFilter.all,
    this.date = TaskDateFilter.all,
  });

  TaskFilterState copyWith({
    TaskStatusFilter? status,
    TaskPriorityFilter? priority,
    TaskDateFilter? date,
  }) {
    return TaskFilterState(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      date: date ?? this.date,
    );
  }
}

class TaskFilterNotifier extends Notifier<TaskFilterState> {
  @override
  TaskFilterState build() {
    return const TaskFilterState();
  }

  void updateStatus(TaskStatusFilter status) {
    state = state.copyWith(status: status);
  }

  void updatePriority(TaskPriorityFilter priority) {
    state = state.copyWith(priority: priority);
  }

  void updateDate(TaskDateFilter date) {
    state = state.copyWith(date: date);
  }

  void reset() {
    state = const TaskFilterState();
  }
}

final taskFilterProvider = NotifierProvider<TaskFilterNotifier, TaskFilterState>(() {
  return TaskFilterNotifier();
});
