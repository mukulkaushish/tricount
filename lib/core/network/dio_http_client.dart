import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/network/app_exception.dart';
import 'package:tricount/core/network/http_client.dart';
import 'package:tricount/core/network/interceptors/auth_interceptor.dart';
import 'package:tricount/core/network/json_parser.dart';

class DioHttpClient implements HttpClient {
  DioHttpClient({
    required Dio dio,
    required AuthInterceptor authInterceptor,
    bool enableLogging = false,
  }) : _dio = dio {
    _dio.interceptors.add(authInterceptor);
    if (enableLogging) {
      // requestBody/responseBody intentionally false — never log sensitive data.
      _dio.interceptors.add(LogInterceptor());
    }
  }

  final Dio _dio;

  @override
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
  }) async {
    final responseResult = await _send(
      path: path,
      method: method,
      cancelToken: cancelToken,
      queryParameters: queryParameters,
      data: data,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return responseResult.match(
      left,
      (response) => _decodeObject(
        response: response,
        decoder: decoder,
        keyPath: keyPath,
      ),
    );
  }

  Either<AppException, T> _decodeObject<T>({
    required Response<dynamic> response,
    required T Function(Map<String, dynamic> json) decoder,
    String? keyPath,
  }) {
    final body = response.data;
    if (body == null) {
      return left(
        const DataMismatchException(
          message: 'Expected a JSON object but received an empty response.',
        ),
      );
    }

    try {
      final extractedData = _extractData(body, keyPath);
      final jsonMap = JsonParser.castMap(
        extractedData,
        context: _keyPathContext(keyPath),
      );
      return right(decoder(jsonMap));
    } on AppException catch (error) {
      return left(error);
    } on Object catch (error) {
      return left(
        DataMismatchException(
          message: 'Failed to decode object response: $error',
        ),
      );
    }
  }

  @override
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
  }) async {
    final responseResult = await _send(
      path: path,
      method: method,
      cancelToken: cancelToken,
      queryParameters: queryParameters,
      data: data,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return responseResult.match(
      left,
      (response) => _decodeList(
        response: response,
        decoder: decoder,
        keyPath: keyPath,
      ),
    );
  }

  Either<AppException, List<T>> _decodeList<T>({
    required Response<dynamic> response,
    required T Function(Map<String, dynamic> json) decoder,
    String? keyPath,
  }) {
    final body = response.data;
    if (body == null) {
      return right(<T>[]);
    }

    try {
      final extractedData = _extractData(body, keyPath);
      final items = JsonParser.castList(
        extractedData,
        context: _keyPathContext(keyPath),
      );

      final decodedItems = items
          .asMap()
          .entries
          .map(
            (entry) => decoder(
              JsonParser.castMap(
                entry.value,
                context: '${_keyPathContext(keyPath)}[${entry.key}]',
              ),
            ),
          )
          .toList(growable: false);

      return right(decodedItems);
    } on AppException catch (error) {
      return left(error);
    } on Object catch (error) {
      return left(
        DataMismatchException(
          message: 'Failed to decode list response: $error',
        ),
      );
    }
  }

  @override
  Future<Either<AppException, Unit>> requestEmpty({
    required String path,
    required HttpMethod method,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final responseResult = await _send(
      path: path,
      method: method,
      cancelToken: cancelToken,
      queryParameters: queryParameters,
      data: data,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return responseResult.match(left, (_) => right(unit));
  }

  Future<Either<AppException, Response<dynamic>>> _send({
    required String path,
    required HttpMethod method,
    required bool requiresAuth,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        cancelToken: cancelToken,
        data: data,
        queryParameters: queryParameters,
        options: _options(
          method: method,
          headers: headers,
          requiresAuth: requiresAuth,
        ),
      );

      if (_isHtmlResponse(response)) {
        return left(_toBadResponseException(response));
      }

      if (!_isSuccessStatusCode(response.statusCode)) {
        return left(_toBadResponseException(response));
      }

      return right(response);
    } on DioException catch (error) {
      return left(_handleDioException(error));
    } on AppException catch (error) {
      return left(error);
    } on Object catch (error) {
      return left(UnknownAppException(message: error.toString()));
    }
  }

  dynamic _extractData(dynamic body, String? keyPath) {
    if (keyPath == null || keyPath.trim().isEmpty) {
      return body;
    }

    return JsonParser.extractByKeyPath(body, keyPath);
  }

  AppException _handleDioException(DioException error) {
    final response = error.response;
    if (response != null && _isHtmlResponse(response)) {
      return _toBadResponseException(response);
    }

    return AppException.fromDioException(error);
  }

  bool _isHtmlResponse(Response<dynamic> response) {
    final contentType = response.headers.value('content-type')?.toLowerCase();
    if (contentType != null && contentType.contains('text/html')) {
      return true;
    }

    final data = response.data;
    if (data is! String) {
      return false;
    }

    final normalized = data.trim().toLowerCase();
    return normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html') ||
        normalized.contains('<head>') ||
        normalized.contains('<body>') ||
        normalized.contains('<title>');
  }

  bool _isSuccessStatusCode(int? statusCode) {
    final code = statusCode ?? 500;
    return code >= 200 && code < 300;
  }

  String _keyPathContext(String? keyPath) {
    if (keyPath == null || keyPath.trim().isEmpty) {
      return 'response body';
    }

    return 'keyPath "$keyPath"';
  }

  Options _options({
    required HttpMethod method,
    required bool requiresAuth,
    Map<String, String>? headers,
  }) {
    return Options(
      method: method.name.toUpperCase(),
      headers: headers,
      extra: {'requiresAuth': requiresAuth},
    );
  }

  AppException _toBadResponseException(Response<dynamic> response) {
    final sanitizedResponse = Response<dynamic>(
      data: _isHtmlResponse(response) ? null : response.data,
      headers: response.headers,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
    );

    return AppException.fromDioException(
      DioException(
        type: DioExceptionType.badResponse,
        requestOptions: response.requestOptions,
        response: sanitizedResponse,
      ),
    );
  }
}
