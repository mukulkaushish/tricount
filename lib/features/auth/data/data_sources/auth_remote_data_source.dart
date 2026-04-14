import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/network/network.dart';
import 'package:tricount/features/auth/data/models/auth_models.dart';

abstract interface class AuthRemoteDataSource {
  Future<Either<AppException, AuthTokensModel>> login({
    required String email,
    required String password,
  });

  Future<Either<AppException, AuthTokensModel>> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<Either<AppException, AuthTokensModel>> signInWithApple({
    required String idToken,
  });

  Future<Either<AppException, AuthTokensModel>> signInWithGoogle({
    required String idToken,
  });

  Future<Either<AppException, PasskeyOptionsModel>> getPasskeyOptions({
    required String email,
  });

  Future<Either<AppException, AuthTokensModel>> verifyPasskey({
    required Map<String, dynamic> payload,
  });

  Future<Either<AppException, AuthenticatedUserModel>> getCurrentUser();

  Future<Either<AppException, Unit>> requestPasswordResetOtp({
    required String email,
  });

  Future<Either<AppException, Unit>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });
}
