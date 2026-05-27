import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/common/entities/user.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/usecases/usecase.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class UserSignUp implements UseCase<User, UserSignUpParams> {
  final AuthRepository authRepository;
  const UserSignUp(this.authRepository);

  @override
  Future<Either<Failure, User>> call(UserSignUpParams params) async {
    return await authRepository.signUpWithEmailPassword(
      username: params.username,
      email: params.email,
      password: params.password,
      fullName: params.fullName,
    );
  }
}

class UserSignUpParams {
  final String username;
  final String email;
  final String password;
  final String? fullName;

  UserSignUpParams({
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
  });
}
