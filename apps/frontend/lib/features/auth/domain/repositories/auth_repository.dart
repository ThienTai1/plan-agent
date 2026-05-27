import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/common/entities/user.dart';
import 'package:frontend/core/error/failures.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    String? fullName,
  });

  Future<Either<Failure, User>> currentUser();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});

  Future<Either<Failure, User>> signInWithGoogle();
}

