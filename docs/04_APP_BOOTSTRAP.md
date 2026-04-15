# 04 — App Bootstrap & main.dart

> Env names and URLs below are pattern examples, not fixed values.

## Initialization sequence

```
main.dart → bootstrap()
  1. WidgetsFlutterBinding.ensureInitialized()
  2. Load environment config (.env or --dart-define)
  3. Initialize GetIt (injection_container.dart) — in dependency order:
       AppLogger → SecureStore → Dio + interceptors → HttpClient →
       Drift DB → ConnectivityService → AnalyticsService →
       Repositories → Use cases → BLoCs
  4. Initialize analytics SDKs (Sentry.init, etc.)
  5. Global error handlers:
       FlutterError.onError      → CrashReporter
       PlatformDispatcher.onError → CrashReporter
  6. Bloc.observer = AppBlocObserver()
  7. Register AppLifecycleObserver
  8. runApp(App())
```

## `main.dart`

Minimal. Calls `WidgetsFlutterBinding.ensureInitialized()`, `await bootstrap()`, sets `FlutterError.onError` + `PlatformDispatcher.instance.onError`, `runApp(App())`.

**Must NOT contain:** business logic, DI setup, themes, routes.

## `bootstrap.dart`

Single entry: `Future<void> bootstrap()`. Order:
1. Logger — first so subsequent init can log
2. Environment — URLs, feature flags
3. Secure storage — needed for tokens
4. Network — Dio + interceptors
5. Database — Drift connection
6. Connectivity — start monitoring
7. Analytics — SDK init
8. Feature deps — repos, use cases, BLoCs
9. `Bloc.observer = AppBlocObserver()` — global state logging + error reporting
10. `WidgetsBinding.instance.addObserver(AppLifecycleObserver())` — resume/pause

**Error strategy:** any init failure → log + throw. No partial-init startup.

## Environments

**File:** `lib/core/constants/api_constants.dart`

| Env | Base URL | Logging | Analytics |
|---|---|---|---|
| development | `https://dev-api.<domain>/v1` | Verbose | NoOp |
| staging | `https://staging-api.<domain>/v1` | Debug | Sentry only |
| production | `https://api.<domain>/v1` | Error only | All providers |

**Select:** `--dart-define=ENV=production`.
**Access:** `const String.fromEnvironment('ENV', defaultValue: 'development')`.

## `injection_container.dart`

**Access:** `final sl = GetIt.instance;` (sl = service locator).
**Registration order matters** — deps before dependents.

Split into modules, each exposing `void register()`:

| Module | Registers |
|---|---|
| `network_module.dart` | Dio, interceptors, `HttpClient` → `DioHttpClient` |
| `storage_module.dart` | Drift DB, `SecureStore`, `SharedPreferences` |
| `analytics_module.dart` | `AnalyticsService` + adapters |
| `feature_module.dart` | All feature repos, use cases, BLoCs |

| Type | When |
|---|---|
| `registerLazySingleton` | Services: HttpClient, DB, Analytics, Repositories |
| `registerFactory` | BLoCs (new instance per screen) |
| `registerSingletonAsync` | Services with async init (Database) |

## `app.dart`

Root widget = global providers + theme + router.

```
MultiBlocProvider
  ├── ThemeBloc          (global: mode + palette + font scale)
  ├── ConnectivityBloc   (global: network state)
  └── AuthBloc           (global: session state)
      └── BlocBuilder<ThemeBloc, ThemeState>
            └── MaterialApp.router
                  ├── theme / darkTheme  ← ThemeState → ThemeData via AppTheme.build
                  ├── themeMode          ← ThemeState.themeMode
                  ├── routerConfig       ← AppRouter().config()
                  └── builder            ← ConnectivityBanner(child: child)
```

Rules:
- `MaterialApp.router`, not `MaterialApp` (auto_route).
- `ThemeData` is **always** built via `AppTheme.build()` — never inline.
- `ConnectivityBanner` wraps via `builder` overlay.
- Locale + localization delegates configured here.

## Global error handlers

**`FlutterError.onError`** — framework errors (layout/render/gesture); `AppLogger.error()` + `CrashReporter.recordError()`; debug mode also prints.

**`PlatformDispatcher.instance.onError`** — uncaught async errors; same handling; return `true`.

**`AppBlocObserver`** — set via `Bloc.observer`; logs state transitions in debug; reports BLoC errors to `CrashReporter`.
