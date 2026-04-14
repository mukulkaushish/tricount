# 03 - Data Layer: Networking, Storage & Security

This document describes how the app fetches, parses, stores, and secures data.

---

## 1. Networking (Dio & HttpClient)

We use an abstract `HttpClient` interface to decouple repositories from Dio.

### Core Methods
- `request<T>`: Single object response.
- `requestList<T>`: List of objects.
- `requestEmpty`: No-body responses (204 No Content).
- All methods accept an optional `CancelToken` for route-aware cancellation.
- `request<T>` and `requestList<T>` accept an optional dot-notation `keyPath`
  (for example `data.user` or `data.items`) so repositories can decode wrapped
  payloads without reaching into raw Dio responses.
- `DioHttpClient` rejects accidental HTML responses before JSON decoding and
  turns malformed payloads into `AppException`/`DataMismatchException` early.

### Interceptor Stack (Order Matters)
1. **LogInterceptor**: Built-in Dio logger (Debug only).
2. **AuthInterceptor**: Handles Bearer tokens and 401/Refresh flow via `QueuedInterceptorsWrapper`.
3. **CacheInterceptor**: ETag validation and stale-while-revalidate fallback.
4. **RetryInterceptor**: Exponential backoff for 5xx and timeouts.

---

## 2. JSON Parsing (JsonParser)

No code generation. We use `abstract final class JsonParser` with static methods for type-safe extraction.

### Naming Convention
- `parse<Type>` — **required** field; throws `DataMismatchException` if missing or wrong type.
- `parse<Type>Nullable` — **optional** field; returns `null` if absent.

### Full API Surface
| Method | Notes |
|--------|-------|
| `parseString` / `parseStringOptional` | String fields |
| `parseInt` / `parseIntOptional` | Coerces whole-number doubles and numeric strings |
| `parseDouble` / `parseDoubleOptional` | Coerces ints and numeric strings |
| `parseBool` / `parseBoolOptional` | Coerces int (0/non-zero) and strings ("true"/"1") |
| `parseStringList` / `parseStringListOptional` | List of strings |
| `parseIntList` / `parseIntListOptional` | List of ints, same coercion as `parseInt` |
| `parseDoubleList` / `parseDoubleListOptional` | List of doubles |
| `parseBoolList` / `parseBoolListOptional` | List of bools |
| `parseObject<T>` / `parseObjectOptional<T>` | Nested objects via `fromJson` callback |
| `parseList<T>` / `parseListOptional<T>` | Lists of objects, index-aware error messages |
| `parseMap` / `parseMapOptional` | Raw `Map<String, dynamic>` fields |
| `hasKey` / `getKeys` | Presence check and key enumeration |
| `validateRequiredFields` | Fast-fail at top of `fromJson` before field-level parsing |
| `toJson` | Strips nulls; recursively serializes `JsonCodable` objects |
| `castList` / `castMap` | Used by `DioHttpClient` to validate top-level response type |
| `extractByKeyPath` | Dot-notation path (e.g. `"data.user"`) for wrapped payloads |

### JsonCodable Contract
All DTOs must implement `JsonCodable` so the compiler enforces `toJson()`:

```dart
class UserModel implements JsonCodable {
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: JsonParser.parseString(json, 'id'),
    age: JsonParser.parseInt(json, 'age'),
    bio: JsonParser.parseStringOptional(json, 'bio'),
  );

  @override
  Map<String, dynamic> toJson() => JsonParser.toJson({
    'id': id, 'age': age, 'bio': bio,
  });
}
```

**Error surfacing**: Every parse failure throws `DataMismatchException` with `fieldName` populated, so stack traces pinpoint the exact broken field.

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

### Android: No-Internet in Release Builds

**Problem**: Android merges `debug/`, `profile/`, and `main/` manifests. If `INTERNET` permission is only in `debug/AndroidManifest.xml`, release builds have no network access.

**Fix — step 1**: Add to `android/app/src/main/AndroidManifest.xml` (above `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**Fix — step 2 (Android emulator only)**: Android 9+ blocks cleartext HTTP by default. The emulator also maps the host machine to `10.0.2.2`, not `localhost`. The debug manifest at `android/app/src/debug/AndroidManifest.xml` references a `network_security_config.xml` that permits cleartext to `10.0.2.2`, `localhost`, and `127.0.0.1`.

Pass the correct base URL when running on emulator:
```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:8080
```

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
