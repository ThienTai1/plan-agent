import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/entities/user.dart';
import 'package:frontend/core/usecases/usecase.dart';
import 'package:frontend/features/auth/domain/usecases/user_login.dart';
import 'package:frontend/features/auth/domain/usecases/user_sign_up.dart';

import 'package:frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:frontend/core/providers/core_providers.dart';

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return await _getCurrentUser();
  }

  Future<User?> _getCurrentUser() async {
    final getCurrentUser = ref.read(getCurrentUserProvider);
    final res = await getCurrentUser(NoParams());
    return res.fold((l) => null, (r) => r);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final userLogin = ref.read(userLoginProvider);
    final res = await userLogin(
      UserLoginParams(email: email, password: password),
    );
    state = res.fold(
      (l) => AsyncValue.error(l.message, StackTrace.current),
      (r) => AsyncValue.data(r),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    final userSignUp = ref.read(userSignUpProvider);
    final res = await userSignUp(
      UserSignUpParams(
        email: email,
        password: password,
        username: username,
        fullName: name,
      ),
    );
    state = res.fold(
      (l) => AsyncValue.error(l.message, StackTrace.current),
      (r) => AsyncValue.data(r),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final userLogout = ref.read(userLogoutProvider);
    final res = await userLogout(NoParams());
    res.fold(
      (l) => state = AsyncValue.error(l.message, StackTrace.current),
      (r) => state = const AsyncValue.data(null),
    );
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> sendPasswordResetEmail({required String email}) async {
    final useCase = ref.read(sendPasswordResetEmailProvider);
    final res = await useCase(email);
    return res.fold((failure) => failure.message, (_) => null);
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    final userGoogleLogin = ref.read(userGoogleLoginProvider);
    final res = await userGoogleLogin(NoParams());
    state = res.fold(
      (l) => AsyncValue.error(l.message, StackTrace.current),
      (r) => AsyncValue.data(r),
    );
  }

  /// Updates the user's password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> updatePassword({required String newPassword}) async {
    try {
      await ref.read(supabaseClientProvider).auth.updateUser(
            UserAttributes(password: newPassword),
          );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Updates User Profile (Full Name, etc.)
  Future<String?> updateProfile({required String fullName}) async {
    try {
      final response = await ref.read(supabaseClientProvider).auth.updateUser(
            UserAttributes(
              data: {'full_name': fullName},
            ),
          );
      if (response.user != null) {
        final updatedUser = User(
          id: response.user!.id,
          email: response.user!.email ?? '',
          fullName: response.user!.userMetadata?['full_name'],
          avatarUrl: response.user!.userMetadata?['avatar_url'],
          username: response.user!.userMetadata?['username'],
        );
        state = AsyncValue.data(updatedUser);
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Updates User Avatar
  Future<String?> updateAvatar({required String avatarUrl}) async {
    try {
      final response = await ref.read(supabaseClientProvider).auth.updateUser(
            UserAttributes(
              data: {'avatar_url': avatarUrl},
            ),
          );
      if (response.user != null) {
        final updatedUser = User(
          id: response.user!.id,
          email: response.user!.email ?? '',
          fullName: response.user!.userMetadata?['full_name'],
          avatarUrl: response.user!.userMetadata?['avatar_url'],
          username: response.user!.userMetadata?['username'],
        );
        state = AsyncValue.data(updatedUser);
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Uploads and Updates User Avatar
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = state.value;
      if (user == null) return 'User not found';

      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = fileName; // No prefix if bucket name is already 'avatars'

      await ref.read(supabaseClientProvider).storage.from('avatars').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = ref
          .read(supabaseClientProvider)
          .storage
          .from('avatars')
          .getPublicUrl(path);

      return await updateAvatar(avatarUrl: publicUrl);
    } on StorageException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
