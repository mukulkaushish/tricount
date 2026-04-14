import 'package:tricount/core/logging/app_logger.dart';
import 'package:tricount/core/logging/pretty_app_logger.dart';

export 'app_logger.dart';
export 'log_level.dart';
export 'pretty_app_logger.dart';

// ignore: avoid_global_state
AppLogger _globalLogger = PrettyAppLogger();

/// Global logger instance.
///
/// Defaults to [PrettyAppLogger]. Override via [setGlobalLogger] during
/// bootstrap (e.g., to swap in a production logger before [runApp]).
// ignore: avoid_global_state
AppLogger get logger => _globalLogger;

/// Replaces the global [logger] instance.
///
/// Call once during app bootstrap, before [runApp].
void setGlobalLogger(final AppLogger instance) => _globalLogger = instance;
