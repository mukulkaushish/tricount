import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

/// Runs the full Apple Sign-In flow (native SDK + backend exchange).
final class LoginWithAppleUseCase {
  const LoginWithAppleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AuthToken>> call() =>
      _repository.loginWithApple();
}
