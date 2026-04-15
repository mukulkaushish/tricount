# 13 — Logging System

## Architecture

```
AppLogger (interface)
    ├── PrettyAppLogger      (dev — colorful console)
    └── ProductionAppLogger  (prod — structured, feeds CrashReporter)
```

Naming follows the `HttpClient` → `DioHttpClient` convention: descriptive prefix, no `Impl` suffix.

## `AppLogger` interface (`lib/core/logging/app_logger.dart`)

| Method | Level | Use for |
|---|---|---|
| `verbose(msg, [error, stack])` | Verbose | granular tracing (off in prod) |
| `debug(msg, [error, stack])` | Debug | dev diagnostics |
| `info(msg, [error, stack])` | Info | noteworthy runtime events |
| `warning(msg, [error, stack])` | Warning | recoverable issues |
| `error(msg, [error, stack])` | Error | failures needing attention |

### `LogLevel` enum

| Level | Value | Enabled in |
|---|---|---|
| `verbose` | 0 | dev only |
| `debug` | 1 | dev only |
| `info` | 2 | dev + staging |
| `warning` | 3 | all |
| `error` | 4 | all |

**Level filtering** — logger takes a minimum level at construction; messages below are silently dropped.

| Env | Min level |
|---|---|
| development | `verbose` |
| staging | `info` |
| production | `warning` |

## `PrettyAppLogger`

Wraps the `logger` package. Colorful structured console:
```
┌───────────────────────────────────────
│ 🔵 DEBUG | DioHttpClient
│ ← 200 GET /v1/books (234ms)
│ Response size: 12.4 KB
└───────────────────────────────────────
```

## Where logging happens

| Component | Logs | Level |
|---|---|---|
| Dio `LogInterceptor` | HTTP req/resp | debug |
| Dio `LogInterceptor` | HTTP errors | error |
| `AuthInterceptor` | token refresh attempts | info |
| `AuthInterceptor` | 401 flow | warning |
| `RetryInterceptor` | retry attempts | warning |
| `CacheInterceptor` | hits/misses | debug |
| BLoC `onError` | unhandled errors | error |
| `AppBlocObserver` | state transitions | verbose |
| Bootstrap | init step completion | info |
| Repository | data source fallbacks | info |
| Use cases | business rule violations | warning |

## Integration with `CrashReporter`

For `warning`/`error` level:
1. Log to console via active `AppLogger`.
2. Also send to `CrashReporter.recordMessage()` as breadcrumb.
3. `error` with exception → also `CrashReporter.recordError()`.

Ensures crash reports in Sentry/Firebase have full context breadcrumbs.

## Sensitive data policy

Full rules → `20_SECURITY.md#sensitive-data-policy`.

| Never log | Always log |
|---|---|
| Auth tokens (mask as `Bearer ***`) | HTTP method + URL path |
| Passwords (redact entirely) | Response status codes |
| Personal data (email, name) | Error messages + types |
| Full request bodies with sensitive fields | Timing + cache hit/miss |
