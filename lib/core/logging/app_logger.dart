import 'package:tricount/core/logging/log_level.dart';

/// Structured logger interface used throughout the app.
///
/// Inject the concrete implementation via DI. The default is
/// [PrettyAppLogger] which writes colorful output to the console.
abstract class AppLogger {
  void verbose(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  });

  void debug(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  });

  void info(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  });

  void warning(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  });

  void error(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  });

  void log(
    final LogLevel level,
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  });
}
