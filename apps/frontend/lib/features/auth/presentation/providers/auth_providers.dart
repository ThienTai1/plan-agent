import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/usecases/current_user.dart';
import 'package:frontend/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:frontend/features/auth/domain/usecases/user_login.dart';
import 'package:frontend/features/auth/domain/usecases/user_logout.dart';
import 'package:frontend/features/auth/domain/usecases/user_sign_up.dart';
import 'package:frontend/features/auth/domain/usecases/user_google_login.dart';


// Data Sources
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// Use Cases
final userSignUpProvider = Provider<UserSignUp>((ref) {
  return UserSignUp(ref.watch(authRepositoryProvider));
});

final userLoginProvider = Provider<UserLogin>((ref) {
  return UserLogin(ref.watch(authRepositoryProvider));
});

final userLogoutProvider = Provider<UserLogout>((ref) {
  return UserLogout(ref.watch(authRepositoryProvider));
});

final getCurrentUserProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailProvider = Provider<SendPasswordResetEmail>((ref) {
  return SendPasswordResetEmail(ref.watch(authRepositoryProvider));
});

final userGoogleLoginProvider = Provider<UserGoogleLogin>((ref) {
  return UserGoogleLogin(ref.watch(authRepositoryProvider));
});


