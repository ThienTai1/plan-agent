import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/config/supabase_config.dart';
import 'package:frontend/core/services/notification_service.dart';

/// A robust provider that handles the entire app backend initialization process
/// (Supabase, PowerSync). It is designed to be watched by the root Splash/App
/// widget to prevent the app from freezing on startup while allowing for a nice Loading UI.
final appInitializationProvider = FutureProvider<void>((ref) async {
  debugPrint('Initializing App Backend Services...');

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: kDebugMode,
  );


  debugPrint('Supabase initialized successfully');

  // 2. [REMOVED] PowerSync & Drift are no longer used for direct Supabase architecture
  // await openDatabase(); 
  debugPrint('Skipping PowerSync initialization (Architecture: Direct Supabase)');

  // 3. Initialize Notification Service
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.init();
  debugPrint('Notification Service initialized successfully');

  // Can add more bootstrap logic here if necessary.
});
