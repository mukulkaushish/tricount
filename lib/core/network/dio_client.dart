import 'package:dio/dio.dart';

import 'package:tricount/core/network/app_exception.dart';

/// Base URL for the Tricount backend.
///
/// Override at build time via `--dart-define=BASE_URL=https://...`
/// Defaults to localhost for simulator development.
const _defaultBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Creates a pre-configured [Dio] instance for the Tricount backend.
///
/// All feature repositories receive this instance via their constructor.
/// Swap the instance in tests to point at a mock server.
Dio createDio({String baseUrl = _defaultBaseUrl}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

/// Maps a [DioException] to a typed [AppException].
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return AppException.timeout();
    case DioExceptionType.connectionError:
      return AppException.network();
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        return AppException.unauthorized();
      }
      final detail = _extractDetail(e.response?.data);
      return AppException.server(statusCode, detail);
    case DioExceptionType.cancel:
      return const AppException(message: 'Request cancelled.');
    case DioExceptionType.unknown:
    case DioExceptionType.badCertificate:
      return AppException.network();
  }
}

String? _extractDetail(dynamic data) {
  if (data is Map<String, dynamic>) {
    final reason = data['reason'] ?? data['message'] ?? data['error'];
    if (reason is String && reason.isNotEmpty) return reason;
  }
  return null;
}
