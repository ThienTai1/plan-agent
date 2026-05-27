import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/theme_notifier.dart';
import 'package:frontend/core/repeat/repeat_scheduler_provider.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:provider/provider.dart';

import 'package:frontend/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:frontend/features/chat/presentation/providers/chat_provider.dart';
import 'package:frontend/features/chat/data/chat_providers.dart';

import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/auth/presentation/pages/register_page.dart';
import 'package:frontend/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:frontend/features/profile/presentation/pages/profile_page.dart';
import 'package:frontend/features/chat/presentation/pages/chat_page.dart';
import 'package:frontend/features/goals/presentation/pages/goals_list_page.dart';
import 'package:frontend/features/profile/presentation/pages/gallery_page.dart';
import 'package:frontend/features/auth/presentation/pages/reset_password_page.dart';
import 'package:frontend/features/profile/presentation/pages/personal_info_page.dart';
import 'package:frontend/features/profile/presentation/pages/notification_settings_page.dart';
import 'package:frontend/features/premium/presentation/pages/subscription_page.dart';
import 'package:frontend/features/premium/presentation/pages/dashboard_page.dart';
import 'package:frontend/features/premium/data/services/revenue_cat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/core/providers/app_initialization_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              ChatProvider(repository: ref.read(chatRepositoryProvider)),
        ),
      ],
      child: MaterialApp(
        title: AppPallete.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const BootWrapper(),
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
          ProfileScreen.routeName: (_) => const ProfileScreen(),
          ChatPage.routeName: (context) => const ChatPage(),
          GoalsListPage.routeName: (_) => const GoalsListPage(),
          GalleryPage.routeName: (_) => const GalleryPage(),
          ResetPasswordPage.routeName: (_) => const ResetPasswordPage(),
          PersonalInfoPage.routeName: (_) => const PersonalInfoPage(),
          NotificationSettingsPage.routeName: (_) => const NotificationSettingsPage(),
          SubscriptionPage.routeName: (_) => const SubscriptionPage(),
          DashboardPage.routeName: (_) => const DashboardPage(),
        },

      ),
    );
  }
}

class BootWrapper extends ConsumerWidget {
  const BootWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(appInitializationProvider);
    debugPrint('[BootWrapper] Building with initialization state: $initialization');

    return initialization.when(
      data: (_) => const AuthWrapper(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(appInitializationProvider);
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('[AuthWrapper] Password recovery event detected!');

        if (mounted) {
          Navigator.of(context).pushNamed(ResetPasswordPage.routeName);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    debugPrint('[AuthWrapper] Building with auth state: $authState');

    return authState.when(
      data: (user) {
        if (user != null) {
          // Initialize RevenueCat with Supabase UID
          ref.read(revenueCatServiceProvider).init(user.id);
          
          // Start in-app repeat scheduler (runs while app is open)
          ref.read(repeatSchedulerProvider);
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) {
        debugPrint('[AuthWrapper] Auth error: $error');
        return const LoginScreen();
      },
    );
  }
}
