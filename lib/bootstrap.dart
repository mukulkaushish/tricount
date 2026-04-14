import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/app.dart';
import 'package:tricount/core/core.dart';

/// App entry point.
///
/// Initialization order (must be preserved):
/// 1. Flutter binding — required before any platform channel calls.
/// 2. Error handlers — set up before DI so failures during init are captured.
/// 3. DI — registers all singletons and factories.
/// 4. BLoC observer — debug-only, wires up state change logging.
/// 5. runApp — all infrastructure is ready.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  _setupErrorHandlers();
  await configureDependencies();

  if (kDebugMode) {
    Bloc.observer = _AppBlocObserver();
  }

  runApp(const App());
}

void _setupErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint(details.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('Unhandled platform error: $error\n$stack');
    return true;
  };
}

/// Debug-only BLoC observer that logs state changes and errors to the console.
///
/// Replace with a production crash reporter (e.g. Sentry) once the logging
/// infrastructure is in place.
class _AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    debugPrint('[${bloc.runtimeType}] → ${change.nextState.runtimeType}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('[${bloc.runtimeType}] Error: $error');
    super.onError(bloc, error, stackTrace);
  }
}
