import 'package:dio/dio.dart';

/// Unified sealed error type used across all layers.
///
/// Repositories and use cases return `Either<AppException, T>`.
/// The BLoC folds the Either and maps to failure states.
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  /// Human-readable message safe to show in the UI.
  final String message;

  /// HTTP status code when available.
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// A network or HTTP-transport level failure.
final class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});

  factory NetworkException.noConnection() => const NetworkException(
        message: 'No internet connection. Please try again.',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'Request timed out. Please try again.',
      );

  factory NetworkException.cancelled() =>
      const NetworkException(message: 'Request cancelled.');

  factory NetworkException.badCertificate() =>
      const NetworkException(message: 'SSL certificate error.');

  factory NetworkException.server(
    final int statusCode, [
    final String? detail,
  ]) =>
      NetworkException(
        message: detail ?? 'Something went wrong. Please try again.',
        statusCode: statusCode,
      );
}

/// The request was rejected because credentials are invalid or missing.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Invalid credentials. Please try again.',
    super.statusCode = 401,
  });
}

/// JSON shape did not match the expected model contract.
final class DataMismatchException extends AppException {
  const DataMismatchException(
    final String message, {
    this.fieldName,
  }) : super(message: message);

  final String? fieldName;
}

/// Catch-all for truly unexpected runtime failures.
final class UnexpectedException extends AppException {
  UnexpectedException(final String detail)
      : super(message: 'An unexpected error occurred: $detail');
}

/// Maps a [DioException] to the appropriate [AppException] subtype.
AppException mapDioException(final DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkException.timeout();
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return NetworkException.noConnection();
    case DioExceptionType.badCertificate:
      return NetworkException.badCertificate();
    case DioExceptionType.cancel:
      return NetworkException.cancelled();
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        return const UnauthorizedException();
      }
      final detail = _extractErrorDetail(error.response?.data);
      return NetworkException.server(statusCode, detail);
  }
}

String? _extractErrorDetail(final dynamic data) {
  if (data is Map<String, dynamic>) {
    final reason = data['reason'] ?? data['message'] ?? data['error'];
    if (reason is String && reason.isNotEmpty) return reason;
  }
  return null;
}
