import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/core/providers/app_initialization_provider.dart';
import 'package:frontend/core/common/entities/user.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/goals/domain/models/habit.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/common/providers/theme_notifier.dart';

import 'package:frontend/core/database/local_queries_providers.dart' as local_queries;

class MockAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return User(
      id: 'test_user',
      email: 'test@example.com',
      fullName: 'Test User',
    );
  }
}

class MockAppUserNotifier extends AppUserNotifier {
  @override
  User? build() => User(
      id: 'test_user',
      email: 'test@example.com',
      fullName: 'Test User',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Navigation switches views correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appInitializationProvider.overrideWith((ref) async => null),
          authNotifierProvider.overrideWith(MockAuthNotifier.new),
          appUserNotifierProvider.overrideWith(MockAppUserNotifier.new),
          themeNotifierProvider.overrideWith(ThemeNotifier.new),
          
          // Mocking all database-dependent providers from local_queries_providers.dart
          local_queries.localUserIdProvider.overrideWithValue('test_user'),
          local_queries.allGoalsProvider.overrideWith((ref) => Stream.value([])),
          local_queries.activeGoalsProvider.overrideWith((ref) => Stream.value([])),
          local_queries.allTasksProvider.overrideWith((ref) => Stream.value([])),
          local_queries.todayPendingTasksProvider.overrideWith((ref) => Stream.value([])),
          local_queries.upcomingEventsProvider.overrideWith((ref) => Stream.value([])),
          
          // Mocking goals_providers.dart (if different)
          allTasksProvider.overrideWith((ref) => Stream.value(<Task>[])),
          allHabitsProvider.overrideWith((ref) => Stream.value(<Habit>[])),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Initial state: Today timeline
    await tester.pumpAndSettle();
    expect(find.textContaining('Good'), findsWidgets); // Greeting: Good Morning/Afternoon/Evening

    // Tap Goals
    await tester.tap(find.byIcon(LucideIcons.folder));
    await tester.pumpAndSettle();
    expect(find.text('All Goals'), findsWidgets);

    // Tap Tasks
    await tester.tap(find.byIcon(LucideIcons.clipboard_list));
    await tester.pumpAndSettle();
    expect(find.text('All Tasks'), findsWidgets);
    
    // Tap You (Profile)
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsWidgets);
  });
}
