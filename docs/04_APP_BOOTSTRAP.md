# 04 - App Bootstrap & main.dart

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
        └── 6. runApp(ReadingApp())
```

---

## main.dart Specification

**File**: `lib/main.dart`

**Responsibility**: Minimal entry point. Calls `bootstrap()` and runs the app.

**Behavior**:
- Calls `WidgetsFlutterBinding.ensureInitialized()`
- Calls `await bootstrap()` which sets up all DI
- Sets `FlutterError.onError` to report to analytics
- Sets `PlatformDispatcher.instance.onError` for async errors
- Calls `runApp()` with the root `ReadingApp` widget

**Must NOT contain**: Business logic, DI setup, theme definitions, or route configuration.

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

**Error Strategy**: If any init step fails, log the error and throw. The app should not start in a partially initialized state.

---

## Environment Configuration

**File**: `lib/core/constants/api_constants.dart`

Three environments are supported:

| Environment | Base URL | Logging | Analytics |
|-------------|----------|---------|-----------|
| `development` | `https://dev-api.readingapp.com/v1` | Verbose | NoOp |
| `staging` | `https://staging-api.readingapp.com/v1` | Debug | Sentry only |
| `production` | `https://api.readingapp.com/v1` | Error only | All providers |

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

### Registration Modules

Each module is a separate file with a `void register()` function:

| Module | Registers |
|--------|-----------|
| `network_module.dart` | Dio, interceptors, HttpClient (DioHttpClient) |
| `storage_module.dart` | Drift DB, SecureStore, SharedPreferences |
| `analytics_module.dart` | AnalyticsService + adapters |
| `feature_module.dart` | All feature repos, use cases, BLoCs |

### Singleton vs Factory

| Type | When |
|------|------|
| `registerLazySingleton` | Services: HttpClient, Database, Analytics, Repositories |
| `registerFactory` | BLoCs (new instance per screen) |
| `registerSingletonAsync` | Services requiring async init (Database) |

---

## app.dart (ReadingApp) Specification

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
- `MaterialApp.router` is used (not `MaterialApp`) because auto_route provides the router config
- Theme is built from `ThemeState`, never hardcoded
- `ConnectivityBanner` wraps the entire app as a `builder` overlay
- No inline `ThemeData` construction - always delegate to `AppTheme.fromPalette()`
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
