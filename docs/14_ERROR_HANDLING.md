# 14 - Error Handling

> The code and event names used in examples are illustrative. Apply the same error-handling flow to your own features and entities.

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

> `DataMismatchException` is the JSON-specific subtype — see [07_JSON_PARSING_CODABLE.md](07_JSON_PARSING_CODABLE.md#datamismatchexception) for parse-failure context.

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

## fpdart Either API Reference

`Either<AppException, T>` is the standard return type across the data layer. fpdart provides these built-in methods — do not re-implement them:

| Method | Purpose | Use In |
|--------|---------|--------|
| `fold(onLeft, onRight)` | Pattern match both sides | BLoCs — map to states |
| `map(fn)` | Transform the Right value | Repository — convert DTO to entity |
| `flatMap(fn)` | Chain operations that return Either | Use cases — compose steps |
| `mapLeft(fn)` | Transform the Left value | Rare — remap exception types |
| `getOrElse(defaultFn)` | Extract Right or compute default | UI — provide fallback |
| `match(onLeft, onRight)` | Alias for `fold` | Same as fold |
| `isLeft()` / `isRight()` | Check which side | Guard clauses |
| `toOption()` | Discard error, keep `Option<T>` | When error details aren't needed |

### TaskEither (Optional Enhancement)

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
| `BadRequestException` / `ValidationException` | `Icons.error_outline` | No |
| `UnauthorizedException` / `ForbiddenException` | `Icons.lock_outline` | No (redirect or access flow) |
| `NotFoundException` | `Icons.search_off` | No |
| `RateLimitException` | `Icons.schedule` | Yes |
| `DataMismatchException` / `CacheException` / `StorageException` / `UnknownException` | `Icons.error_outline` | Yes |

Handle every subtype explicitly in the `switch`. If multiple subtypes share
the same icon/action, group them with pattern alternation rather than using a
`default` branch.

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

Set up in `main.dart` and `bootstrap.dart` -> [04_APP_BOOTSTRAP.md](04_APP_BOOTSTRAP.md#global-error-handling-setup)

| Handler | Catches |
|---------|---------|
| `FlutterError.onError` | Rendering errors, layout overflows, assertion failures |
| `PlatformDispatcher.instance.onError` | Uncaught Future errors, isolate errors |
| `AppBlocObserver.onError` | BLoC/Cubit errors |

All three log to `AppLogger.error()` and report to `CrashReporter.recordError()`.

BLoC observer hooks -> [08_STATE_MANAGEMENT.md](08_STATE_MANAGEMENT.md#bloc-observer)

---

## Production Crash Prevention

These are the patterns that prevent crashes and race conditions developers commonly miss during development but hit in production.

### SafeStateMixin — Async Callbacks After Dispose

**File**: `lib/shared/mixins/safe_state_mixin.dart`

When an async operation completes after a `StatefulWidget` is unmounted, calling `setState` crashes the app. `SafeStateMixin` guards against this:

```dart
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}
```

**When to use**: Any `StatefulWidget` that launches async work (timers, animations, manual futures). Not needed when using BLoC — `BlocBuilder` handles this automatically.

**Rule**: Prefer BLoC/Cubit over `StatefulWidget` + `setState`. Use `SafeStateMixin` only for the rare cases where ephemeral state requires async work (e.g., animation controllers with async triggers).

### App Lifecycle Handling

**File**: `lib/app.dart` or a dedicated `AppLifecycleObserver`

Use `WidgetsBindingObserver` for app lifecycle events:

| Lifecycle State | Action |
|----------------|--------|
| `resumed` | Refresh stale data, sync pending changes, re-check auth token |
| `paused` | Save reading progress, flush pending analytics |
| `detached` | Cancel non-critical network requests |
| `inactive` | No action (transient — app switcher, phone call overlay) |

```dart
class AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Trigger data refresh, sync queue processing
      case AppLifecycleState.paused:
        // Save progress, flush analytics
      case AppLifecycleState.detached:
        // Cancel non-critical requests
      case _:
        break;
    }
  }
}
```

Register in `bootstrap()` via `WidgetsBinding.instance.addObserver(observer)`.

### Race Conditions — Prevention Checklist

| Scenario | Prevention | Implemented In |
|----------|-----------|----------------|
| Concurrent token refresh | `QueuedInterceptorsWrapper` serializes requests | `AuthInterceptor` (Doc 06) |
| Double-tap on submit | `droppable()` transformer on write events | BLoC event handler (Doc 08) |
| Search-as-you-type floods | `restartable()` transformer cancels previous | BLoC event handler (Doc 08) |
| Stale callback after dispose | `SafeStateMixin` checks `mounted` | Stateful widgets |
| Orphaned network request | `CancelToken.cancel()` in BLoC `close()` | BLoC disposal (Doc 08) |
| Concurrent Drift writes | Drift's `transaction()` for atomic operations | Repository layer (Doc 10) |
| Multiple BLoCs refreshing same data | Shared use case pattern | BLoC-to-BLoC (Doc 08) |
| Deep link during cold start | `AuthGuard` + `AutoRedirectGuard` with deferred nav | Route guard (Doc 09) |

### Concurrent Drift Writes

When multiple sources write to the same table (e.g., sync queue + user action), wrap in a transaction:

```dart
Future<void> syncAndUpdate(List<Bookmark> remote) async {
  await database.transaction(() async {
    await bookmarkDao.deleteAll();
    await bookmarkDao.insertAll(remote);
  });
}
```

Drift serializes transactions automatically — concurrent transactions queue safely. No manual locking needed.

### Process Death (Android)

Android may kill the app process while it's in the background. When the user returns:

| What Survives | What Doesn't |
|--------------|-------------|
| Drift database | In-memory BLoC state |
| SharedPreferences | Active network requests |
| flutter_secure_storage | Stream subscriptions |
| Navigation stack (auto_route restores) | Ephemeral widget state |

**Strategy**: Persist critical state (reading progress, form drafts) to Drift or SharedPreferences immediately — don't rely on BLoC state surviving background. On `resumed`, re-hydrate BLoCs from local storage before fetching remote.
