import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/common/entities/user.dart';
import 'package:frontend/core/error/exceptions.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  const AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User>> currentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUserData();
      if (user == null) {
        return left(Failure('User not logged in!'));
      }
      return right(user);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => await remoteDataSource.loginWithEmailPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _getUser(
      () async => await remoteDataSource.signUpWithEmailPassword(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return right(null); 
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }


  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    return _getUser(() async => await remoteDataSource.signInWithGoogle());
  }

  Future<Either<Failure, User>> _getUser(Future<User> Function() fn) async {
    try {
      final user = await fn();
      return right(user);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}


