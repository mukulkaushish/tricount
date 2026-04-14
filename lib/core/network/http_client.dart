import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/network/app_exception.dart';

enum HttpMethod { get, post, put, patch, delete }

abstract interface class HttpClient {
  Future<Either<AppException, T>> request<T>({
    required String path,
    required HttpMethod method,
    required T Function(Map<String, dynamic> json) decoder,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    String? keyPath,
    bool requiresAuth = true,
  });

  Future<Either<AppException, List<T>>> requestList<T>({
    required String path,
    required HttpMethod method,
    required T Function(Map<String, dynamic> json) decoder,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    String? keyPath,
    bool requiresAuth = true,
  });

  Future<Either<AppException, Unit>> requestEmpty({
    required String path,
    required HttpMethod method,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    bool requiresAuth = true,
  });
}
