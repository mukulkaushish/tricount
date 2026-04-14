import 'package:logger/logger.dart';
import 'package:tricount/core/logging/app_logger.dart';
import 'package:tricount/core/logging/log_level.dart';

/// Development logger that writes colorful, human-readable output.
///
/// Uses the `logger` package's [PrettyPrinter] under the hood.
/// Register a production logger in release builds.
final class PrettyAppLogger implements AppLogger {
  PrettyAppLogger()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
          ),
        );

  final Logger _logger;

  @override
  void verbose(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _logger.t(message?.toString(), error: error, stackTrace: stackTrace);

  @override
  void debug(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _logger.d(message?.toString(), error: error, stackTrace: stackTrace);

  @override
  void info(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _logger.i(message?.toString(), error: error, stackTrace: stackTrace);

  @override
  void warning(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _logger.w(message?.toString(), error: error, stackTrace: stackTrace);

  @override
  void error(
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) =>
      _logger.e(message?.toString(), error: error, stackTrace: stackTrace);

  @override
  void log(
    final LogLevel level,
    final Object? message, {
    final Object? error,
    final StackTrace? stackTrace,
  }) {
    switch (level) {
      case LogLevel.verbose:
        verbose(message, error: error, stackTrace: stackTrace);
      case LogLevel.debug:
        debug(message, error: error, stackTrace: stackTrace);
      case LogLevel.info:
        info(message, error: error, stackTrace: stackTrace);
      case LogLevel.warning:
        warning(message, error: error, stackTrace: stackTrace);
      case LogLevel.error:
        this.error(message, error: error, stackTrace: stackTrace);
    }
  }
}
