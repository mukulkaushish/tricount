import 'package:dio/dio.dart';

/// Unified sealed error type used across all layers.
///
/// Repositories and use cases return `Either<AppException, T>`.
/// The BLoC folds the Either and maps to failure states.
/// UI renders `exception.userMessage` for display text.
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  /// Technical detail, safe for logging.
  final String message;

  /// HTTP status code when available.
  final int? statusCode;

  /// Human-readable message safe to show in the UI.
  String get userMessage => message;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

// ── Network ──────────────────────────────────────────────────────────────────

/// A network or HTTP-transport level failure (timeout, no connection, SSL).
final class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});

  factory NetworkException.noConnection() =>
      const NetworkException(message: 'No internet connection.');

  factory NetworkException.timeout() =>
      const NetworkException(message: 'Request timed out.');

  factory NetworkException.cancelled() =>
      const NetworkException(message: 'Request cancelled.');

  factory NetworkException.badCertificate() =>
      const NetworkException(message: 'SSL certificate error.');

  @override
  String get userMessage => 'Please check your internet connection.';
}

// ── HTTP 4xx ─────────────────────────────────────────────────────────────────

/// 400 — Server rejected the request due to malformed input.
final class BadRequestException extends AppException {
  const BadRequestException([final String detail = 'Bad request.'])
    : super(message: detail, statusCode: 400);

  @override
  String get userMessage => 'Invalid request.';
}

/// 401 — Credentials invalid or session expired.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([final String detail = 'Unauthorised.'])
    : super(message: detail, statusCode: 401);

  @override
  String get userMessage => 'Session expired. Please log in again.';
}

/// 403 — Authenticated user lacks permission.
final class ForbiddenException extends AppException {
  const ForbiddenException([final String detail = 'Forbidden.'])
    : super(message: detail, statusCode: 403);

  @override
  String get userMessage => "You don't have access to this content.";
}

/// 404 — Requested resource not found.
final class NotFoundException extends AppException {
  const NotFoundException([final String detail = 'Not found.'])
    : super(message: detail, statusCode: 404);

  @override
  String get userMessage => 'Content not found.';
}

/// 422 — Server rejected due to semantic validation errors.
final class ValidationException extends AppException {
  const ValidationException({
    required this.fieldErrors,
    final String detail = 'Validation failed.',
  }) : super(message: detail, statusCode: 422);

  /// Per-field error lists, e.g. `{'email': ['Already taken']}`.
  final Map<String, List<String>> fieldErrors;

  @override
  String get userMessage => 'Please check your input.';
}

/// 429 — Too many requests; the server asks the client to back off.
final class RateLimitException extends AppException {
  const RateLimitException({this.retryAfter})
    : super(message: 'Rate limit exceeded.', statusCode: 429);

  /// How long to wait before retrying, if the server provided it.
  final Duration? retryAfter;

  @override
  String get userMessage => 'Too many requests. Please wait a moment.';
}

// ── HTTP 5xx ─────────────────────────────────────────────────────────────────

/// 5xx — The server encountered an unexpected error.
final class ServerException extends AppException {
  const ServerException({required final int statusCode, final String? detail})
    : super(
        message: detail ?? 'Internal server error.',
        statusCode: statusCode,
      );

  @override
  String get userMessage => 'Something went wrong. Please try again later.';
}

// ── Data / Parse ──────────────────────────────────────────────────────────────

/// JSON shape did not match the expected model contract.
final class DataMismatchException extends AppException {
  const DataMismatchException(final String message, {this.fieldName})
    : super(message: message);

  final String? fieldName;

  @override
  String get userMessage => 'We received unexpected data.';
}

// ── Storage ──────────────────────────────────────────────────────────────────

/// A local database (Drift) or DAO operation failed.
final class CacheException extends AppException {
  const CacheException({required final String detail}) : super(message: detail);

  @override
  String get userMessage => 'Unable to load saved data.';
}

/// A secure storage or SharedPreferences operation failed.
final class StorageException extends AppException {
  const StorageException({required final String detail})
    : super(message: detail);

  @override
  String get userMessage => 'Unable to access storage.';
}

// ── Catch-all ────────────────────────────────────────────────────────────────

/// Catch-all for truly unexpected runtime failures.
final class UnknownException extends AppException {
  UnknownException(final String detail)
    : super(message: 'Unexpected error: $detail');

  @override
  String get userMessage => 'An unexpected error occurred.';
}

// ── DioException → AppException mapper ───────────────────────────────────────

/// Maps a DioException to the appropriate AppException subtype.
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
      return _mapHttpStatus(error.response);
  }
}

AppException _mapHttpStatus(final Response<dynamic>? response) {
  final statusCode = response?.statusCode ?? 0;
  final data = response?.data;
  final detail = _extractDetail(data);

  if (statusCode == 400) return BadRequestException(detail ?? 'Bad request.');
  if (statusCode == 401) {
    return UnauthorizedException(detail ?? 'Unauthorised.');
  }
  if (statusCode == 403) return ForbiddenException(detail ?? 'Forbidden.');
  if (statusCode == 404) return NotFoundException(detail ?? 'Not found.');
  if (statusCode == 422) {
    return ValidationException(
      fieldErrors: _extractFieldErrors(data),
      detail: detail ?? 'Validation failed.',
    );
  }
  if (statusCode == 429) {
    return RateLimitException(retryAfter: _extractRetryAfter(response));
  }
  return ServerException(statusCode: statusCode, detail: detail);
}

String? _extractDetail(final dynamic data) {
  if (data is! Map<String, dynamic>) return null;
  final raw = data['reason'] ?? data['message'] ?? data['error'];
  return raw is String && raw.isNotEmpty ? raw : null;
}

Map<String, List<String>> _extractFieldErrors(final dynamic data) {
  if (data is! Map<String, dynamic>) return const {};
  final raw = data['errors'] ?? data['fieldErrors'] ?? data['field_errors'];
  if (raw is! Map) return const {};
  return Map.fromEntries(
    raw.entries.map((final entry) {
      final value = entry.value;
      final List<String> msgs;
      if (value is List) {
        msgs = value.map((final e) => e.toString()).toList();
      } else if (value is String) {
        msgs = [value];
      } else {
        msgs = const [];
      }
      return MapEntry(entry.key.toString(), msgs);
    }),
  );
}

Duration? _extractRetryAfter(final Response<dynamic>? response) {
  final header = response?.headers.value('Retry-After');
  if (header == null) return null;
  final seconds = int.tryParse(header);
  return seconds != null ? Duration(seconds: seconds) : null;
}
