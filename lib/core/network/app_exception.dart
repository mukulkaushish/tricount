/// Typed error surfaced through the network and data layers.
///
/// Every repository method returns either a value or throws [AppException].
/// The BLoC catches it and maps it to a failure state with [message].
class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  factory AppException.network() => const AppException(
        message: 'No internet connection. Please try again.',
      );

  factory AppException.timeout() => const AppException(
        message: 'Request timed out. Please try again.',
      );

  factory AppException.unauthorized() => const AppException(
        message: 'Invalid email or password.',
        statusCode: 401,
      );

  factory AppException.server(int statusCode, [String? detail]) =>
      AppException(
        message: detail ?? 'Something went wrong. Please try again.',
        statusCode: statusCode,
      );

  /// Human-readable message safe to show in the UI.
  final String message;

  /// HTTP status code when available.
  final int? statusCode;

  @override
  String toString() => 'AppException($statusCode): $message';
}
