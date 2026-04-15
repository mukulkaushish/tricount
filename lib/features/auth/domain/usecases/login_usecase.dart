import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

final class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AuthToken>> call({
    required final String email,
    required final String password,
  }) => _repository.login(email: email, password: password);
}
