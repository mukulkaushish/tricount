# 13 - Logging System

## Architecture

```
AppLogger (interface)
    │
    ├── PrettyAppLogger      (development - colorful console output)
    └── ProductionAppLogger  (production - structured, feeds CrashReporter)
```

Naming follows the `HttpClient` → `DioHttpClient` convention: descriptive prefix on each variant, no `Impl` suffix.

---

## AppLogger Interface

**File**: `lib/core/logging/app_logger.dart`

| Method | Level | Use For |
|--------|-------|---------|
| `verbose(message, [error, stack])` | Verbose | Granular tracing (disabled in prod) |
| `debug(message, [error, stack])` | Debug | Development diagnostics |
| `info(message, [error, stack])` | Info | Noteworthy runtime events |
| `warning(message, [error, stack])` | Warning | Recoverable issues |
| `error(message, [error, stack])` | Error | Failures requiring attention |

### Log Level Enum

| Level | Value | Enabled In |
|-------|-------|-----------|
| `verbose` | 0 | Development only |
| `debug` | 1 | Development only |
| `info` | 2 | Development, Staging |
| `warning` | 3 | All environments |
| `error` | 4 | All environments |

### Level Filtering

The logger accepts a minimum level at construction. Messages below that level are silently dropped.

| Environment | Minimum Level |
|-------------|--------------|
| Development | `verbose` |
| Staging | `info` |
| Production | `warning` |

---

## PrettyAppLogger

Wraps the `logger` package for colorful, structured console output.

**Output format** (development):
```
┌───────────────────────────────────────
│ 🔵 DEBUG | DioHttpClient
│ ← 200 GET /v1/books (234ms)
│ Response size: 12.4 KB
└───────────────────────────────────────
```

---

## Where Logging Happens

| Component | What It Logs | Level |
|-----------|-------------|-------|
| `LogInterceptor` (Dio built-in) | HTTP requests/responses | debug |
| `LogInterceptor` (Dio built-in) | HTTP errors | error |
| AuthInterceptor | Token refresh attempts | info |
| AuthInterceptor | 401 handling flow | warning |
| RetryInterceptor | Retry attempts | warning |
| CacheInterceptor | Cache hits/misses | debug |
| BLoC (onError) | Unhandled BLoC errors | error |
| AppBlocObserver | State transitions | verbose |
| Bootstrap | Init step completion | info |
| Repository | Data source fallbacks | info |
| Use Cases | Business rule violations | warning |

---

## Integration with CrashReporter

For `warning` and `error` level logs:
1. Log to console via the active `AppLogger`
2. Additionally send to `CrashReporter.recordMessage()` as breadcrumb
3. For `error` with exception: also call `CrashReporter.recordError()`

This ensures crash reports in Sentry/Firebase have full context breadcrumbs.

---

## Sensitive Data Policy

Full policy with masking rules -> [20_SECURITY.md](20_SECURITY.md#sensitive-data-policy)

Quick reference:

| Never Log | Always Log |
|-----------|-----------|
| Auth tokens (mask as `Bearer ***`) | HTTP method and URL path |
| Passwords (redact entirely) | Response status codes |
| Personal user data (email, name) | Error messages and types |
| Full request bodies with sensitive fields | Timing and cache hit/miss |
