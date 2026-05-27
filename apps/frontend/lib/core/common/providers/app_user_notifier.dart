import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/entities/user.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';

final appUserNotifierProvider = NotifierProvider<AppUserNotifier, User?>(() {
  return AppUserNotifier();
});

class AppUserNotifier extends Notifier<User?> {
  @override
  User? build() {
    // Automatically watch authNotifierProvider and sync state
    // This is the source of truth for the app user.
    return ref.watch(authNotifierProvider).value;
  }

  @Deprecated('Use authNotifierProvider to change user state instead')
  void updateUser(User? user) {
    state = user;
  }
}
