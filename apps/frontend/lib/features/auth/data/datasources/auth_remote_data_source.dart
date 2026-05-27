import 'package:frontend/core/error/exceptions.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/config/supabase_config.dart';



abstract interface class AuthRemoteDataSource {
  Session? get currentUserSession;
  Future<UserModel> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    String? fullName,
  });
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserModel?> getCurrentUserData();
  Future<void> sendPasswordResetEmail({required String email});
  Future<UserModel> signInWithGoogle();
  Future<void> logout();
}


class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {



  final SupabaseClient supabaseClient;
  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Session? get currentUserSession => supabaseClient.auth.currentSession;

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user == null) {
        throw const ServerException('User is null!');
      }
      return await _getUserModelWithRole(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await supabaseClient.auth.signUp(
        password: password,
        email: email,
        data: {
          'username': username,
          'full_name': fullName,
        },
      );
      if (response.user == null) {
        throw const ServerException('User is null!');
      }
      return await _getUserModelWithRole(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUserSession != null) {
        final userData = await supabaseClient.auth.getUser();
        if (userData.user != null) {
          return await _getUserModelWithRole(userData.user!);
        }
      }
      return null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> _getUserModelWithRole(User user) async {
    final profileData = await supabaseClient
        .from('profiles')
        .select('role, pro_expires_at')
        .eq('id', user.id)
        .single();
    
    final role = profileData['role'] as String? ?? 'free';
    final proExpiresAt = profileData['pro_expires_at'] as String?;
    
    final userMap = user.toJson();
    userMap['role'] = role;
    userMap['pro_expires_at'] = proExpiresAt;
    
    return UserModel.fromJson(userMap);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleClientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const ServerException('Sign in aborted by user');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const ServerException('No ID Token found.');
      }

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw const ServerException('User is null!');
      }

      return await _getUserModelWithRole(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}


