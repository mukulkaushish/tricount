import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/core/network/network.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AuthenticatedUser>> call() =>
      _repository.getCurrentUser();
}

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AppSession>> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AppSession>> call({
    required String displayName,
    required String email,
    required String password,
  }) => _repository.register(
    displayName: displayName,
    email: email,
    password: password,
  );
}

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, Unit>> call({
    required String email,
    required String otpCode,
    required String newPassword,
  }) => _repository.resetPassword(
    email: email,
    otpCode: otpCode,
    newPassword: newPassword,
  );
}

class SendPasswordResetOtpUseCase {
  const SendPasswordResetOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, Unit>> call({required String email}) =>
      _repository.requestPasswordResetOtp(email: email);
}

class SignInWithAppleUseCase {
  const SignInWithAppleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AppSession>> call() =>
      _repository.signInWithApple();
}

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AppSession>> call() =>
      _repository.signInWithGoogle();
}

class SignInWithPasskeyUseCase {
  const SignInWithPasskeyUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppException, AppSession>> call({required String email}) =>
      _repository.signInWithPasskey(email: email);
}
