import 'package:dio/dio.dart';

import 'package:tricount/core/network/network.dart';
import 'package:tricount/features/auth/data/auth_repository.dart';
import 'package:tricount/features/auth/data/models/auth_token_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthToken.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<void>(
        '/v1/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
