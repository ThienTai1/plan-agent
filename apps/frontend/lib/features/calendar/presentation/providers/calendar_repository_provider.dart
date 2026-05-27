import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar/domain/repositories/event_repository.dart';
import 'package:frontend/features/calendar/data/repositories/supabase_event_repository_impl.dart';
import 'package:frontend/features/auth/presentation/providers/auth_providers.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return SupabaseEventRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
  );
});
