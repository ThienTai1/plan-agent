import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/premium/data/services/revenue_cat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:frontend/features/chat/domain/repositories/chat_repository.dart';

/// Provide the chat repository.
/// We use ChatRepositoryImpl (direct Supabase) for all users.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final isPro = ref.watch(isProProvider);

  return ChatRepositoryImpl(
    supabase: Supabase.instance.client,
    isPro: isPro,
  );
});
