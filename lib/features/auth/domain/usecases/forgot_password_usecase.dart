import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

final class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, EmptyResponse>> call({
    required final String email,
  }) => _repository.forgotPassword(email: email);
}
