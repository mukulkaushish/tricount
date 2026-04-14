# 04 - App Bootstrap & main.dart

> Environment names, URLs, and module names in this document are examples of the pattern, not fixed values for this repository.

## Initialization Sequence

The app starts through a strict, ordered bootstrap sequence. This ensures all services are available before any widget renders.

```
main.dart
  └── bootstrap()
        ├── 1. WidgetsFlutterBinding.ensureInitialized()
        ├── 2. Load environment config (.env or compile-time)
        ├── 3. Initialize GetIt (injection_container.dart)
        │     ├── Register AppLogger (first - everything else may log)
        │     ├── Register SecureStore
        │     ├── Register Dio + Interceptors
        │     ├── Register HttpClient (DioHttpClient)
        │     ├── Register Drift Database
        │     ├── Register ConnectivityService
        │     ├── Register AnalyticsService
        │     ├── Register Repositories
        │     ├── Register Use Cases
        │     └── Register BLoCs
        ├── 4. Initialize analytics (Sentry.init, etc.)
        ├── 5. Set up global error handlers
        │     ├── FlutterError.onError → CrashReporter
        │     └── PlatformDispatcher.onError → CrashReporter
        ├── 6. Set Bloc.observer = AppBlocObserver()
        ├── 7. Register AppLifecycleObserver
        └── 8. runApp(App())
```

---

## main.dart Specification

**File**: `lib/main.dart`

**Responsibility**: Minimal entry point. Calls `bootstrap()` and runs the app.

**Behavior**:
- Calls `await bootstrap()` which initializes all DI and error handlers
- Calls `runApp()` with the root `App` widget

**Must NOT contain**: Business logic, DI setup, theme definitions, or route configuration.

### Complete Implementation

```dart
import 'package:flutter/material.dart';
import 'package:tricount/app.dart';
import 'package:tricount/bootstrap.dart';

void main() async {
  // Initialize all dependencies and error handlers
  await bootstrap();
  
  // Run the app
  runApp(const App());
}
```

**That's it.** All complexity is deferred to `bootstrap()` and `App()`. No error handling, no service setup, nothing. The entry point is maximally simple.

---

## bootstrap.dart Specification

**File**: `lib/bootstrap.dart`

**Responsibility**: Orchestrate all initialization in the correct order.

**Public API**:
- `Future<void> bootstrap()` - the single entry point

**Initialization Order**:
1. **Logger** - first, so all subsequent init can log
2. **Environment** - determines API URLs, feature flags
3. **Secure Storage** - needed for token retrieval
4. **Network** - Dio instance with all interceptors
5. **Database** - Drift database connection
6. **Connectivity** - start monitoring network state
7. **Analytics** - Sentry/Mixpanel/Firebase SDK init
8. **Feature Dependencies** - repositories, use cases, BLoCs
9. **BLoC Observer** - `Bloc.observer = AppBlocObserver()` for global state logging/error reporting
10. **App Lifecycle Observer** - `WidgetsBinding.instance.addObserver(AppLifecycleObserver())` for resume/pause handling

**Error Strategy**: If any init step fails, log the error and throw. The app must never start in a partially initialized state.

```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sl = GetIt.instance;
  try {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    await initDependencies(environment: env);           // all GetIt registrations
    final logger = sl<AppLogger>();
    Bloc.observer = AppBlocObserver(logger: logger);    // global BLoC logging
    FlutterError.onError = (details) =>
        logger.error(details.exceptionAsString(), stackTrace: details.stack);
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.error('$error', stackTrace: stack);
      return true;
    };
    WidgetsBinding.instance.addObserver(AppLifecycleObserver(logger: logger));
  } catch (e, st) {
    sl.isRegistered<AppLogger>()
        ? sl<AppLogger>().error('Bootstrap failed', stackTrace: st)
        : debugPrint('Bootstrap failed: $e');
    rethrow;
  }
}
```

`AppLifecycleObserver` is a `WidgetsBindingObserver` that logs and handles `resumed` / `paused` / `detached` lifecycle transitions (refresh tokens, save progress, cancel requests).

### initDependencies Function

Lives in `lib/core/di/injection_container.dart` and handles all GetIt registration.

---

## Environment Configuration

**File**: `lib/core/constants/api_constants.dart`

Three environments are supported:

| Environment | Base URL | Logging | Analytics |
|-------------|----------|---------|-----------|
| `development` | `https://dev-api.<domain>/v1` | Verbose | NoOp |
| `staging` | `https://staging-api.<domain>/v1` | Debug | Sentry only |
| `production` | `https://api.<domain>/v1` | Error only | All providers |

**Selection**: Via `--dart-define=ENV=production` at build time.

**Access**: `const String.fromEnvironment('ENV', defaultValue: 'development')`

---

## injection_container.dart Specification

**File**: `lib/core/di/injection_container.dart`

**Responsibility**: Single file that registers ALL dependencies with GetIt.

**Access pattern**:
```
final sl = GetIt.instance;  // 'sl' = service locator
```

**Registration order matters** - dependencies must be registered before dependents.

### Complete Implementation

```dart
import 'package:get_it/get_it.dart';
import 'package:tricount/core/logging/app_logger.dart';
import 'package:tricount/core/network/network_module.dart';
import 'package:tricount/core/storage/storage_module.dart';
import 'package:tricount/core/di/app_bloc_observer.dart';
import 'package:tricount/features/auth/di/auth_module.dart';
import 'package:tricount/features/bills/di/bills_module.dart';

/// Initialize all dependencies
Future<void> initDependencies({required String environment}) async {
  final sl = GetIt.instance;

  // Step 1: Register Logger first (everything else may log)
  // Use PrettyAppLogger in development, SilentAppLogger in production
  sl.registerSingleton<AppLogger>(
    environment == 'production'
        ? SilentAppLogger()
        : PrettyAppLogger(),
  );

  // Step 2: Register networking layer (uses logger)
  registerNetworkModule(sl);

  // Step 3: Register storage layer (database, secure storage, preferences)
  // This is async if using Drift
  await registerStorageModule(sl);

  // Step 4: Register feature modules
  // Each module registers its repositories, use cases, and BLoCs
  registerAuthModule(sl);
  registerBillsModule(sl);
  // Add more feature modules as needed

  // Step 5: Theme, Connectivity, Analytics (global services)
  // These are typically registered in feature modules or here as global
  // sl.registerLazySingleton<ThemeBloc>(() => ThemeBloc(theme Provider));
  // sl.registerLazySingleton<ConnectivityBloc>(() => ConnectivityBloc(...));
}
```

### Registration Modules

Each module is a separate file with a `void register()` or `Future<void> register()` function:

| Module | Registers |
|--------|-----------|
| `network_module.dart` | Dio, interceptors, HttpClient (DioHttpClient) |
| `storage_module.dart` | Drift DB, SecureStore, SharedPreferences |
| `auth_module.dart` | AuthRepository, LoginUseCase, AuthBloc |
| `bills_module.dart` | BillsRepository, BillsBloc |

#### Example: network_module.dart

```dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:tricount/core/network/dio_http_client.dart';
import 'package:tricount/core/network/http_client.dart';
import 'package:tricount/core/network/interceptors/auth_interceptor.dart';
import 'package:tricount/core/network/interceptors/retry_interceptor.dart';
import 'package:tricount/core/logging/app_logger.dart';

void registerNetworkModule(GetIt sl) {
  // Create Dio instance with base config
  final dio = Dio()
    ..options = BaseOptions(
      baseUrl: 'https://api.example.com/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );

  // Add Dio's built-in LogInterceptor
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ),
  );

  // Add custom interceptors (order matters)
  dio.interceptors.add(
    AuthInterceptor(
      tokenProvider: sl<TokenProvider>(),
    ),
  );

  dio.interceptors.add(
    RetryInterceptor(
      logger: sl<AppLogger>(),
    ),
  );

  // Register Dio
  sl.registerLazySingleton<Dio>(() => dio);

  // Register HttpClient implementation
  sl.registerLazySingleton<HttpClient>(
    () => DioHttpClient(
      dio: sl<Dio>(),
      logger: sl<AppLogger>(),
    ),
  );
}
```

#### Example: auth_module.dart

```dart
import 'package:get_it/get_it.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';
import 'package:tricount/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:tricount/features/auth/domain/usecases/login_use_case.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';

void registerAuthModule(GetIt sl) {
  // Register repository (interface in domain, impl in data)
  sl.registerLazySingleton<AuthRepository>(
    () => RemoteAuthRepository(
      httpClient: sl<HttpClient>(),
      secureStore: sl<SecureStore>(),
    ),
  );

  // Register use cases
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(repository: sl<AuthRepository>()),
  );

  sl.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(repository: sl<AuthRepository>()),
  );

  // Register BLoC (factory, not singleton - new instance per screen)
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
    ),
  );
}
```

### Singleton vs Factory

| Type | When | Use Case |
|------|------|----------|
| `registerLazySingleton` | Expensive-to-create services that should be reused | HttpClient, Database, Repository, Logger |
| `registerFactory` | New instance per request | BLoCs, Cubits (each screen gets a fresh BLoC) |
| `registerSingletonAsync` | Services requiring async init | Drift Database, Analytics initialization |

**Rule**: Repositories and Services → Singleton. BLoCs → Factory.

---

## app.dart Specification

**File**: `lib/app.dart`

**Responsibility**: Root widget providing global BLoCs, theme, and router.

**Structure**:
```
MultiBlocProvider
  ├── ThemeBloc (global - manages theme mode, palette, font scale)
  ├── ConnectivityBloc (global - monitors network state)
  └── AuthBloc (global - manages authentication state)
      └── BlocBuilder<ThemeBloc, ThemeState>
            └── MaterialApp.router
                  ├── theme: ThemeState → ThemeData (light)
                  ├── darkTheme: ThemeState → ThemeData (dark)
                  ├── themeMode: ThemeState → ThemeMode
                  ├── routerConfig: AppRouter().config()
                  └── builder: (context, child) →
                        ConnectivityBanner(child: child)
```

**Rules**:
- `MaterialApp.router` is used (not `MaterialApp`) because go_router provides the router config
- Theme is built from `ThemeState`, never hardcoded
- `ConnectivityBanner` wraps the entire app as a `builder` overlay
- No inline `ThemeData` construction - always delegate to `AppTheme.build()`
- Locale and localization delegates are configured here

---

## Global Error Handling Setup

Two global error handlers are set in `main.dart`:

### FlutterError.onError
- Catches framework errors (layout, rendering, gestures)
- Logs to `AppLogger.error()`
- Reports to `CrashReporter.recordError()`
- In debug mode: also prints to console

### PlatformDispatcher.instance.onError
- Catches uncaught async errors
- Same handling as above
- Returns `true` to indicate the error was handled

### BLoC Observer
- A custom `AppBlocObserver` is set via `Bloc.observer`
- Logs all state transitions in debug mode
- Reports BLoC errors to `CrashReporter`
