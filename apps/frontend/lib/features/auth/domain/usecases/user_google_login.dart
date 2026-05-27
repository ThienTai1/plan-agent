import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/common/entities/user.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/usecases/usecase.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class UserGoogleLogin implements UseCase<User, NoParams> {
  final AuthRepository authRepository;
  const UserGoogleLogin(this.authRepository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await authRepository.signInWithGoogle();
  }
}
