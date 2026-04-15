import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

/// Revokes the current session on the server and clears local tokens.
final class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, EmptyResponse>> call() => _repository.logout();
}
