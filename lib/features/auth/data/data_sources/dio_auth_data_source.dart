import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/network/network.dart';
import 'package:tricount/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:tricount/features/auth/data/models/auth_models.dart';

class DioAuthDataSource implements AuthRemoteDataSource {
  const DioAuthDataSource({required HttpClient httpClient})
    : _httpClient = httpClient;

  final HttpClient _httpClient;

  @override
  Future<Either<AppException, AuthenticatedUserModel>> getCurrentUser() {
    return _httpClient.request(
      path: '/v1/auth/me',
      method: HttpMethod.get,
      decoder: AuthenticatedUserModel.fromJson,
    );
  }

  @override
  Future<Either<AppException, PasskeyOptionsModel>> getPasskeyOptions({
    required String email,
  }) {
    return _httpClient.request(
      path: '/v1/auth/passkeys/authenticate/options',
      method: HttpMethod.post,
      data: {'email': email},
      requiresAuth: false,
      decoder: PasskeyOptionsModel.fromJson,
    );
  }

  @override
  Future<Either<AppException, AuthTokensModel>> login({
    required String email,
    required String password,
  }) {
    return _httpClient.request(
      path: '/v1/auth/login',
      method: HttpMethod.post,
      data: {'email': email, 'password': password},
      requiresAuth: false,
      decoder: AuthTokensModel.fromJson,
    );
  }

  @override
  Future<Either<AppException, Unit>> requestPasswordResetOtp({
    required String email,
  }) {
    return _httpClient.requestEmpty(
      path: '/v1/auth/forgot-password',
      method: HttpMethod.post,
      data: {'email': email},
      requiresAuth: false,
    );
  }

  @override
  Future<Either<AppException, AuthTokensModel>> register({
    required String displayName,
    required String email,
    required String password,
  }) {
    return _httpClient.request(
      path: '/v1/auth/register',
      method: HttpMethod.post,
      data: {
        'displayName': displayName,
        'email': email,
        'password': password,
      },
      requiresAuth: false,
      decoder: AuthTokensModel.fromJson,
    );
  }

  @override
  Future<Either<AppException, Unit>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) {
    return _httpClient.requestEmpty(
      path: '/v1/auth/reset-password',
      method: HttpMethod.post,
      data: {
        'email': email,
        'code': otpCode,
        'newPassword': newPassword,
      },
      requiresAuth: false,
    );
  }

  @override
  Future<Either<AppException, AuthTokensModel>> signInWithApple({
    required String idToken,
  }) {
    return _httpClient.request(
      path: '/v1/auth/apple',
      method: HttpMethod.post,
      data: {'idToken': idToken},
      requiresAuth: false,
      decoder: AuthTokensModel.fromJson,
    );
  }

  @override
  Future<Either<AppException, AuthTokensModel>> signInWithGoogle({
    required String idToken,
  }) {
    return _httpClient.request(
      path: '/v1/auth/google',
      method: HttpMethod.post,
      data: {'idToken': idToken},
      requiresAuth: false,
      decoder: AuthTokensModel.fromJson,
    );
  }

  @override
  Future<Either<AppException, AuthTokensModel>> verifyPasskey({
    required Map<String, dynamic> payload,
  }) {
    return _httpClient.request(
      path: '/v1/auth/passkeys/authenticate/verify',
      method: HttpMethod.post,
      data: payload,
      requiresAuth: false,
      decoder: AuthTokensModel.fromJson,
    );
  }
}
