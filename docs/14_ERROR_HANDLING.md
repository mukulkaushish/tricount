# 14 - Error Handling

## Design: Single Error Type, No Mapping

Previous over-engineered pattern had `AppException` hierarchy + `Failure` sealed class + `ErrorMapper` to convert between them. That's triple handling.

**Simplified**: One `sealed class AppException`. Used directly as the `Left` type in `Either<AppException, T>`. No `Failure` class. No `ErrorMapper`.

---

## Error Flow

```
DioHttpClient catches error
    │
    ▼
Returns Either<AppException, T> via fpdart
    │
    ▼
Repository passes Either through (no catch, no mapping)
    │
    ▼
Use Case passes Either through
    │
    ▼
BLoC folds Either → emit Loaded or Error state
    │
    ▼
UI renders based on AppException type
```

**Key insight**: Repositories and Use Cases just pass `Either` through. No try-catch, no mapping layer. The error is typed from source to UI.

---

## AppException (Sealed Class)

**File**: `lib/core/error/app_exception.dart`

```
sealed class AppException {
  String get message;       // Technical detail for logging
  String get userMessage;   // Safe to display in UI
}
```

### Subtypes

| Type | When | userMessage |
|------|------|-------------|
| `NetworkException` | No connectivity, timeout, DNS | "Please check your internet connection." |
| `ServerException(int statusCode)` | 5xx responses | "Something went wrong. Please try again later." |
| `BadRequestException` | 400 | "Invalid request." |
| `UnauthorizedException` | 401 (usually interceptor handles) | "Session expired. Please log in again." |
| `ForbiddenException` | 403 | "You don't have access to this content." |
| `NotFoundException` | 404 | "Content not found." |
| `ValidationException(Map<String, List<String>> fieldErrors)` | 422 | "Please check your input." |
| `RateLimitException(Duration? retryAfter)` | 429 | "Too many requests. Please wait." |
| `DataMismatchException(String fieldName)` | JSON parse failures | "We received unexpected data." |
| `CacheException` | Local storage errors | "Unable to load saved data." |
| `StorageException` | Drift / secure storage errors | "Unable to access storage." |
| `UnknownException` | Catch-all | "An unexpected error occurred." |

> **Note**: The complete hierarchy is documented in [07_JSON_PARSING_CODABLE.md](07_JSON_PARSING_CODABLE.md#appexception-hierarchy). Both listings must stay in sync.

### What Was Removed

| Removed | Why |
|---------|-----|
| `Failure` sealed class | Duplicated `AppException` 1:1. `AppException` IS the failure type. |
| `failure.dart` | Deleted. |
| `ErrorMapper` / `error_mapper.dart` | No mapping needed when source and consumer use the same type. |
| `AppException` → `Failure` conversion in every repository | Repositories just pass `Either` through now. Zero boilerplate. |

---

## How Errors Are Created

### In DioHttpClient

`DioHttpClient` catches `DioException` and maps to `AppException` subtypes via a factory:

```
static AppException fromDioError(DioException e) → AppException
```

This is the **only place** where errors are created from network responses. The factory lives on `AppException` itself (or as a static method in `DioHttpClient`).

### In Drift / Local Storage

Repository catches Drift exceptions locally and wraps in `CacheException`:

```
try {
  return right(await dao.getBooks());
} on Exception catch (e) {
  return left(CacheException(message: e.toString()));
}
```

This is the **only** try-catch in the entire data flow. Network errors are already `Either` from `DioHttpClient`.

---

## BLoC Error Handling

BLoCs fold the Either directly:

```dart
final result = await getBooks(page: event.page);
result.fold(
  (exception) => emit(LibraryError(exception: exception)),
  (books) => emit(LibraryLoaded(books: books)),
);
```

### Error State

Every BLoC error state carries `AppException`:

```dart
final class LibraryError extends LibraryState {
  const LibraryError({required this.exception});
  final AppException exception;
}
```

The UI uses `exception.userMessage` for display and `exception` type for icon/action selection.

---

## fpdart TaskEither (Optional Enhancement)

For repository methods that are purely async + Either, fpdart's `TaskEither` can make composition cleaner:

```dart
// Without TaskEither (standard):
Future<Either<AppException, Book>> getBook(String id) async {
  return httpClient.request<BookModel>(...);
}

// With TaskEither (composable):
TaskEither<AppException, Book> getBook(String id) =>
  TaskEither(() => httpClient.request<BookModel>(...));
```

`TaskEither` is useful when chaining multiple async operations (e.g., fetch book then fetch chapters). For simple single-call repositories, plain `Future<Either>` is clearer.

**Rule**: Use `TaskEither` when composing 2+ async Either operations. Use `Future<Either>` for simple single calls.

---

## Error State Page

**File**: `lib/shared/widgets/app_error_page.dart`

### Props

| Prop | Type | Required | Default |
|------|------|----------|---------|
| `exception` | `AppException` | Yes | - |
| `onRetry` | `VoidCallback?` | No | null (hides retry button) |

### Behavior

Uses `switch` on `AppException` sealed type for exhaustive handling:

| Exception Type | Icon | Retryable |
|---------------|------|-----------|
| `NetworkException` | `Icons.wifi_off` | Yes |
| `ServerException` | `Icons.cloud_off` | Yes |
| `NotFoundException` | `Icons.search_off` | No |
| `UnauthorizedException` | `Icons.lock_outline` | No (redirect to login) |
| Default | `Icons.error_outline` | Yes |

Layout:
```
Center
└── Column
    ├── Icon (64x64, colorScheme.error)
    ├── SizedBox(AppDimensions.spacingL)
    ├── Text(exception.userMessage, style: textTheme.bodyMedium)
    ├── SizedBox(AppDimensions.spacingL)
    └── FilledButton("Try Again", onPressed: onRetry) [if retryable]
```

---

## Global Error Handlers

Set up in `main.dart`:

### FlutterError.onError
- Catches: rendering errors, layout overflows, assertion failures
- Logs to `AppLogger.error()`
- Reports to `CrashReporter.recordError()`

### PlatformDispatcher.instance.onError
- Catches: uncaught Future errors, isolate errors
- Same handling as above
- Returns `true` (error handled)

### BLoC Observer (AppBlocObserver)
- `onError`: Log + report to CrashReporter
- `onTransition`: Log at verbose level (debug only)
