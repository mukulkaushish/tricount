import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/logging/logging.dart';
import 'package:tricount/core/network/empty_response.dart';
import 'package:tricount/core/network/http_client.dart';
import 'package:tricount/core/network/request_method.dart';

/// Dio-backed implementation of [HttpClient].
///
/// All three request methods share common response-processing helpers.
/// HTML/gateway-error responses are detected early and surfaced as
/// [NetworkException] before the JSON parsing stage runs.
final class DioHttpClient implements HttpClient {
  DioHttpClient(this._dio, {final AppLogger? appLogger})
    : _logger = appLogger ?? logger;

  final Dio _dio;
  final AppLogger _logger;

  @override
  Future<Either<AppException, T>> request<T>(
    final String path, {
    required final RequestMethod method,
    required final T Function(Map<String, dynamic>) fromJson,
    final Map<String, dynamic>? queryParameters,
    final dynamic body,
    final String? keyPath,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(method: method.verb),
      );
      if (_isHtmlResponse(response)) {
        _logger.warning('Received HTML response instead of JSON for $path');
        return left(_createBadResponseException(response, path));
      }
      if (!_isSuccess(response.statusCode)) {
        return left(_createBadResponseException(response, path));
      }
      return _processResponse<T>(response, fromJson, keyPath);
    } on DioException catch (e) {
      _logger.error('DioException on $path', error: e);
      return _handleDioException<T>(e);
    } on Exception catch (e) {
      _logger.error('Unexpected exception on $path', error: e);
      return _handleGenericException<T>(e);
    }
  }

  @override
  Future<Either<AppException, EmptyResponse>> requestEmpty(
    final String path, {
    required final RequestMethod method,
    final Map<String, dynamic>? queryParameters,
    final dynamic body,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(method: method.verb),
      );
      if (_isHtmlResponse(response)) {
        _logger.warning('Received HTML response instead of JSON for $path');
        return left(_createBadResponseException(response, path));
      }
      if (!_isSuccess(response.statusCode)) {
        return left(_createBadResponseException(response, path));
      }
      return right(const EmptyResponse());
    } on DioException catch (e) {
      _logger.error('DioException on $path', error: e);
      return _handleDioException<EmptyResponse>(e);
    } on Exception catch (e) {
      _logger.error('Unexpected exception on $path', error: e);
      return _handleGenericException<EmptyResponse>(e);
    }
  }

  @override
  Future<Either<AppException, List<T>>> requestList<T>(
    final String path, {
    required final RequestMethod method,
    required final T Function(Map<String, dynamic>) fromJson,
    final Map<String, dynamic>? queryParameters,
    final dynamic body,
    final String? keyPath,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(method: method.verb),
      );
      if (_isHtmlResponse(response)) {
        _logger.warning('Received HTML response instead of JSON for $path');
        return left(_createBadResponseException(response, path));
      }
      if (!_isSuccess(response.statusCode)) {
        return left(_createBadResponseException(response, path));
      }
      return _processListResponse<T>(response, fromJson, keyPath);
    } on DioException catch (e) {
      _logger.error('DioException on $path', error: e);
      return _handleDioException<List<T>>(e);
    } on Exception catch (e) {
      _logger.error('Unexpected exception on $path', error: e);
      return _handleGenericException<List<T>>(e);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  bool _isSuccess(final int? statusCode) {
    final code = statusCode ?? 500;
    return code >= 200 && code < 300;
  }

  bool _isHtmlResponse(final Response<dynamic> response) {
    final contentType = response.headers.value('content-type')?.toLowerCase();
    if (contentType != null && contentType.contains('text/html')) return true;
    final data = response.data;
    if (data is String) {
      final lower = data.trim().toLowerCase();
      return lower.startsWith('<!doctype html') ||
          lower.startsWith('<html') ||
          lower.contains('<title>') ||
          lower.contains('bad gateway') ||
          lower.contains('502:') ||
          lower.contains('<head>') ||
          lower.contains('<body>');
    }
    return false;
  }

  AppException _createBadResponseException(
    final Response<dynamic> response,
    final String path,
  ) {
    final sanitised = _isHtmlResponse(response)
        ? Response<dynamic>(
            requestOptions: response.requestOptions,
            statusCode: response.statusCode,
            statusMessage: response.statusMessage,
            headers: response.headers,
          )
        : response;

    return mapDioException(
      DioException(
        type: DioExceptionType.badResponse,
        response: sanitised,
        requestOptions: RequestOptions(path: path),
      ),
    );
  }

  Either<AppException, T> _processResponse<T>(
    final Response<dynamic> response,
    final T Function(Map<String, dynamic>) fromJson,
    final String? keyPath,
  ) {
    if (T == EmptyResponse) {
      return right(const EmptyResponse() as T);
    }
    final jsonResponse = response.data;
    if (jsonResponse == null) {
      return left(const DataMismatchException('Empty response body'));
    }
    if (jsonResponse is List && jsonResponse.isEmpty) {
      return left(
        const DataMismatchException('Unexpected empty list response'),
      );
    }
    final extracted = keyPath != null
        ? _extractByKeyPath(jsonResponse, keyPath)
        : jsonResponse;
    if (extracted is! Map<String, dynamic>) {
      return left(const DataMismatchException('Unexpected response format'));
    }
    try {
      return right(fromJson(extracted));
    } on Exception catch (e) {
      _logger.error('Failed to parse response', error: e);
      return left(DataMismatchException(e.toString()));
    }
  }

  Either<AppException, List<T>> _processListResponse<T>(
    final Response<dynamic> response,
    final T Function(Map<String, dynamic>) fromJson,
    final String? keyPath,
  ) {
    final jsonResponse = response.data;
    if (jsonResponse == null ||
        (jsonResponse is List && jsonResponse.isEmpty)) {
      return right(<T>[]);
    }
    final extracted = keyPath != null
        ? _extractByKeyPath(jsonResponse, keyPath)
        : jsonResponse;
    if (extracted is! List) {
      return left(const DataMismatchException('Unexpected response format'));
    }
    try {
      final list = extracted
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
      return right(list);
    } on Exception catch (e) {
      return left(DataMismatchException(e.toString()));
    }
  }

  Either<AppException, T> _handleDioException<T>(final DioException e) {
    final response = e.response;
    final path = e.requestOptions.path;
    if (response != null && _isHtmlResponse(response)) {
      _logger.warning(
        'Received HTML response instead of JSON for $path',
      );
      return left(_createBadResponseException(response, path));
    }
    return left(mapDioException(e));
  }

  Either<AppException, T> _handleGenericException<T>(final Exception e) =>
      left(UnknownException(e.toString()));

  dynamic _extractByKeyPath(final dynamic data, final String keyPath) {
    final keys = keyPath.split('.');
    dynamic result = data;
    for (final key in keys) {
      if (result is! Map<String, dynamic> || !result.containsKey(key)) {
        return null;
      }
      result = result[key];
    }
    return result;
  }
}
