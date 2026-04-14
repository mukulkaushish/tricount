# 03 - Data Layer: Networking, Storage & Security

This document describes how the app fetches, parses, stores, and secures data.

---

## 1. Networking (Dio & HttpClient)

We use an abstract `HttpClient` interface to decouple repositories from Dio.

### Core Methods
- `request<T>`: Single object response.
- `requestList<T>`: List of objects.
- `requestEmpty`: No-body responses (204 No Content).

### Interceptor Stack (Order Matters)
1. **LogInterceptor**: Built-in Dio logger (Debug only).
2. **AuthInterceptor**: Handles Bearer tokens and 401/Refresh flow via `QueuedInterceptorsWrapper`.
3. **CacheInterceptor**: ETag validation and stale-while-revalidate fallback.
4. **RetryInterceptor**: Exponential backoff for 5xx and timeouts.

---

## 2. JSON Parsing (JsonParser)

No code generation. We use a `JsonParser` mixin with static methods for type-safe extraction.

### Patterns
- **JsonCodable**: Interface for all DTOs (`fromJson` + `toJson`).
- **Validation**: `JsonParser.validateRequiredFields` fails early if keys are missing.
- **Type Safety**: Methods like `parseString`, `parseInt`, `parseList<T>` throw `DataMismatchException` on type errors.
- **Serialization**: `JsonParser.toJson` strips nulls and handles nested objects recursively.

---

## 3. Local Storage (Drift & Secure Storage)

| Technology | Purpose | Implementation |
|------------|---------|----------------|
| **Drift (SQLite)** | Structured Data | DAOs for Books, Progress, Bookmarks. |
| **Secure Storage** | Secrets | Auth tokens and sensitive keys. |
| **SharedPrefs** | Preferences | Theme mode, font scale, flags. |

**Rule**: Drift is used directly via DAOs — no extra abstraction layer is needed as Drift already provides reactive streams and testing utilities.

---

## 4. Connectivity & Resilience

- **ConnectivityService**: Thin wrapper around `connectivity_plus`.
- **ConnectivityBanner**: Global slide-in overlay (top of screen) for offline states.
- **Offline-First**: Repositories check local cache first, return stale data, then refresh in background.

---

## 5. Error Handling (AppException)

We use a single `sealed class AppException`. No extra "Failure" or "ErrorMapper" classes.

### Flow
`DioHttpClient` → `AppException.fromDioError` → `Either<AppException, T>` → `Repository` → `BLoC` → `UI`.

### UI Integration
`AppErrorPage` uses a `switch` on `AppException` types to show appropriate icons and "Try Again" buttons.

---

## 6. Security

- **Tokens**: Stored **only** in `flutter_secure_storage`.
- **Refresh**: `AuthInterceptor` locks concurrent requests during token refresh to prevent race conditions.
- **Privacy**: `LogInterceptor` must have `requestBody: false` in production to avoid logging sensitive data.
- **HTTPS**: Enforced at the platform level (ATS on iOS, Network Security Config on Android).
