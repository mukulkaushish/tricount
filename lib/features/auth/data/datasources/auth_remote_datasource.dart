import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/constants/api_constants.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/core/network/http_client.dart';
import 'package:tricount/core/network/request_method.dart';
import 'package:tricount/features/auth/data/models/auth_token_model.dart';

/// Contract for the remote authentication data source.
abstract interface class AuthRemoteDataSource {
  Future<Either<AppException, AuthTokenModel>> login({
    required final String email,
    required final String password,
  });

  Future<Either<AppException, AuthTokenModel>> register({
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

  Future<Either<AppException, AuthTokenModel>> refreshToken({
    required final String refreshToken,
  });

  Future<Either<AppException, AuthTokenModel>> loginWithGoogle({
    required final String idToken,
  });

  Future<Either<AppException, AuthTokenModel>> loginWithApple({
    required final String idToken,
  });
}

/// Dio-backed implementation of [AuthRemoteDataSource].
final class DioAuthDataSource implements AuthRemoteDataSource {
  const DioAuthDataSource(this._client);

  final HttpClient _client;

  @override
  Future<Either<AppException, AuthTokenModel>> login({
    required final String email,
    required final String password,
  }) => _client.request(
    authLoginPath,
    method: RequestMethod.post,
    body: {'email': email, 'password': password},
    fromJson: AuthTokenModel.fromJson,
  );

  @override
  Future<Either<AppException, AuthTokenModel>> register({
    required final String email,
    required final String password,
    required final String displayName,
  }) => _client.request(
    authRegisterPath,
    method: RequestMethod.post,
    body: {
      'email': email,
      'password': password,
      'displayName': displayName,
    },
    fromJson: AuthTokenModel.fromJson,
  );

  @override
  Future<Either<AppException, EmptyResponse>> forgotPassword({
    required final String email,
  }) => _client.requestEmpty(
    authForgotPasswordPath,
    method: RequestMethod.post,
    body: {'email': email},
  );

  @override
  Future<Either<AppException, EmptyResponse>> resetPassword({
    required final String email,
    required final String code,
    required final String newPassword,
  }) => _client.requestEmpty(
    authResetPasswordPath,
    method: RequestMethod.post,
    body: {'email': email, 'code': code, 'newPassword': newPassword},
  );

  @override
  Future<Either<AppException, AuthTokenModel>> refreshToken({
    required final String refreshToken,
  }) => _client.request(
    authRefreshPath,
    method: RequestMethod.post,
    body: {'refreshToken': refreshToken},
    fromJson: AuthTokenModel.fromJson,
  );

  @override
  Future<Either<AppException, AuthTokenModel>> loginWithGoogle({
    required final String idToken,
  }) => _client.request(
    authGooglePath,
    method: RequestMethod.post,
    body: {'idToken': idToken},
    fromJson: AuthTokenModel.fromJson,
  );

  @override
  Future<Either<AppException, AuthTokenModel>> loginWithApple({
    required final String idToken,
  }) => _client.request(
    authApplePath,
    method: RequestMethod.post,
    body: {'idToken': idToken},
    fromJson: AuthTokenModel.fromJson,
  );
}
