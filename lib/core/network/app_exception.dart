import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

sealed class AppException extends Equatable implements Exception {
  const AppException({this.message, this.statusCode});

  factory AppException.fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutAppException();
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const NetworkAppException();
      case DioExceptionType.cancel:
        return const CancelledAppException();
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        final message = _readMessage(exception.response?.data);

        if (statusCode == null) {
          return UnknownAppException(message: message);
        }
        if (statusCode == 400 || statusCode == 409 || statusCode == 422) {
          return ValidationAppException(message: message);
        }
        if (statusCode == 401 || statusCode == 403) {
          return UnauthorizedAppException(message: message);
        }
        if (statusCode == 404) {
          return NotFoundAppException(message: message);
        }
        if (statusCode >= 500) {
          return ServerAppException(
            message: message,
            statusCode: statusCode,
          );
        }
        return UnknownAppException(message: message);
      case DioExceptionType.unknown:
        return UnknownAppException(message: exception.message);
    }
  }

  final String? message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];

  static String? _readMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final value = data['message'] ?? data['error'] ?? data['reason'];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

final class CancelledAppException extends AppException {
  const CancelledAppException() : super();
}

final class ConfigurationAppException extends AppException {
  const ConfigurationAppException({super.message});
}

final class DataMismatchException extends AppException {
  const DataMismatchException({super.message, this.fieldName});

  /// The JSON field name that caused the mismatch, if known.
  ///
  /// Populated by `JsonParser` methods. Useful for debugging without
  /// exposing raw error details to the UI.
  final String? fieldName;

  @override
  List<Object?> get props => [message, statusCode, fieldName];
}

final class NetworkAppException extends AppException {
  const NetworkAppException() : super();
}

final class NotFoundAppException extends AppException {
  const NotFoundAppException({super.message, super.statusCode = 404});
}

final class ServerAppException extends AppException {
  const ServerAppException({required super.statusCode, super.message});
}

final class TimeoutAppException extends AppException {
  const TimeoutAppException() : super();
}

final class UnauthorizedAppException extends AppException {
  const UnauthorizedAppException({super.statusCode = 401, super.message});
}

final class UnknownAppException extends AppException {
  const UnknownAppException({super.message});
}

final class ValidationAppException extends AppException {
  const ValidationAppException({super.statusCode = 422, super.message});
}
