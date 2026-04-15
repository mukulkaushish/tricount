import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';

/// Contract for all authentication operations.
///
/// Every method returns `Either<AppException, T>`. The BLoC folds the
/// result and emits the appropriate state — no throw-based error handling.
abstract interface class AuthRepository {
  Future<Either<AppException, AuthToken>> login({
    required final String email,
    required final String password,
  });

  Future<Either<AppException, AuthToken>> register({
    required final String email,
    required final String password,
    required final String displayName,
  });

  Future<Either<AppException, EmptyResponse>> forgotPassword({
    required final String email,
  });

  Future<Either<AppException, EmptyResponse>> resetPassword({
    required final String email,
    required final String code,
    required final String newPassword,
  });

  Future<Either<AppException, AuthToken>> refreshToken({
    required final String refreshToken,
  });

  /// Runs the native Google Sign-In flow then exchanges the idToken
  /// with the backend. Both steps are handled in the data layer.
  Future<Either<AppException, AuthToken>> loginWithGoogle();

  /// Runs the native Apple Sign-In flow then exchanges the idToken
  /// with the backend. Both steps are handled in the data layer.
  Future<Either<AppException, AuthToken>> loginWithApple();
}
