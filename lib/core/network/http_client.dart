import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/core/network/request_method.dart';

/// Abstraction over the HTTP transport layer.
///
/// Repositories depend on this interface, not on Dio directly.
/// Swap implementations in tests by registering a mock in GetIt.
abstract interface class HttpClient {
  /// Makes a request that returns a single decoded object of type [T].
  Future<Either<AppException, T>> request<T>(
    final String path, {
    required final RequestMethod method,
    required final T Function(Map<String, dynamic>) fromJson,
    final Map<String, dynamic>? queryParameters,
    final dynamic body,
    final String? keyPath,
  });

  /// Makes a request that returns a list of [T].
  Future<Either<AppException, List<T>>> requestList<T>(
    final String path, {
    required final RequestMethod method,
    required final T Function(Map<String, dynamic>) fromJson,
    final Map<String, dynamic>? queryParameters,
    final dynamic body,
    final String? keyPath,
  });

  /// Makes a request that returns no meaningful body (e.g., DELETE, logout).
  Future<Either<AppException, EmptyResponse>> requestEmpty(
    final String path, {
    required final RequestMethod method,
    final Map<String, dynamic>? queryParameters,
    final dynamic body,
  });
}
