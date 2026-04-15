import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tricount/features/auth/data/datasources/social_auth_datasource.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

/// Remote-only implementation of [AuthRepository].
///
/// Maps data-layer DTOs to domain entities via `.toDomain()`.
/// Social sign-in methods orchestrate both the native SDK call
/// (via [SocialAuthDataSource]) and the backend exchange
/// (via [AuthRemoteDataSource]) in sequence.
final class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this._dataSource, this._socialAuth);

  final AuthRemoteDataSource _dataSource;
  final SocialAuthDataSource _socialAuth;

  @override
  Future<Either<AppException, AuthToken>> login({
    required final String email,
    required final String password,
  }) async {
    final result = await _dataSource.login(email: email, password: password);
    return result.map((model) => model.toDomain());
  }

  @override
  Future<Either<AppException, AuthToken>> register({
    required final String email,
    required final String password,
    required final String displayName,
  }) async {
    final result = await _dataSource.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    return result.map((model) => model.toDomain());
  }

  @override
  Future<Either<AppException, EmptyResponse>> forgotPassword({
    required final String email,
  }) => _dataSource.forgotPassword(email: email);

  @override
  Future<Either<AppException, EmptyResponse>> resetPassword({
    required final String email,
    required final String code,
    required final String newPassword,
  }) => _dataSource.resetPassword(
    email: email,
    code: code,
    newPassword: newPassword,
  );

  @override
  Future<Either<AppException, AuthToken>> refreshToken({
    required final String refreshToken,
  }) async {
    final result = await _dataSource.refreshToken(refreshToken: refreshToken);
    return result.map((model) => model.toDomain());
  }

  @override
  Future<Either<AppException, AuthToken>> loginWithGoogle() async {
    // Step 1: Run native Google Sign-In to get the idToken.
    final idTokenResult = await _socialAuth.getGoogleIdToken();
    // Step 2: Exchange idToken with the backend or propagate native error.
    return switch (idTokenResult) {
      Left(:final value) => left(value),
      Right(:final value) => (await _dataSource.loginWithGoogle(
        idToken: value,
      )).map((final model) => model.toDomain()),
    };
  }

  @override
  Future<Either<AppException, AuthToken>> loginWithApple() async {
    // Step 1: Run native Apple Sign-In to get the identityToken.
    final idTokenResult = await _socialAuth.getAppleIdToken();
    // Step 2: Exchange idToken with the backend or propagate native error.
    return switch (idTokenResult) {
      Left(:final value) => left(value),
      Right(:final value) => (await _dataSource.loginWithApple(
        idToken: value,
      )).map((final model) => model.toDomain()),
    };
  }
}
