import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

/// Remote-only implementation of [AuthRepository].
///
/// Maps data-layer DTOs to domain entities via `.toDomain()`.
final class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Future<Either<AppException, AuthToken>> login({
    required final String email,
    required final String password,
  }) async {
    final result =
        await _dataSource.login(email: email, password: password);
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
  }) =>
      _dataSource.forgotPassword(email: email);

  @override
  Future<Either<AppException, EmptyResponse>> resetPassword({
    required final String email,
    required final String code,
    required final String newPassword,
  }) =>
      _dataSource.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

  @override
  Future<Either<AppException, AuthToken>> refreshToken({
    required final String refreshToken,
  }) async {
    final result =
        await _dataSource.refreshToken(refreshToken: refreshToken);
    return result.map((model) => model.toDomain());
  }

  @override
  Future<Either<AppException, AuthToken>> loginWithGoogle({
    required final String idToken,
  }) async {
    final result = await _dataSource.loginWithGoogle(idToken: idToken);
    return result.map((model) => model.toDomain());
  }

  @override
  Future<Either<AppException, AuthToken>> loginWithApple({
    required final String idToken,
  }) async {
    final result = await _dataSource.loginWithApple(idToken: idToken);
    return result.map((model) => model.toDomain());
  }
}
