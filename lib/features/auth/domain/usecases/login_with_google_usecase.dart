import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

final class LoginWithGoogleUseCase {
  const LoginWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AuthToken>> call({
    required final String idToken,
  }) =>
      _repository.loginWithGoogle(idToken: idToken);
}
