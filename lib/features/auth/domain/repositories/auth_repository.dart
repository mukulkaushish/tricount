import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/core/network/network.dart';

abstract interface class AuthRepository {
  Future<Either<AppException, AuthenticatedUser>> getCurrentUser();

  Future<Either<AppException, AppSession>> login({
    required String email,
    required String password,
  });

  Future<Either<AppException, AppSession>> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<Either<AppException, AppSession>> signInWithApple();

  Future<Either<AppException, AppSession>> signInWithGoogle();

  Future<Either<AppException, AppSession>> signInWithPasskey({
    required String email,
  });

  Future<Either<AppException, Unit>> requestPasswordResetOtp({
    required String email,
  });

  Future<Either<AppException, Unit>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });
}
