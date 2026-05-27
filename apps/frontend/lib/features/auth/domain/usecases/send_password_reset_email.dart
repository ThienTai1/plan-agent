import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/usecases/usecase.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetEmail implements UseCase<void, String> {
  final AuthRepository authRepository;
  const SendPasswordResetEmail(this.authRepository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await authRepository.sendPasswordResetEmail(email: params);
  }
}
