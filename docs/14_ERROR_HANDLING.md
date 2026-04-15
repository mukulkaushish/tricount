# 14 — Error Handling

> Examples are illustrative.

## Design: single error type, no mapping

Previous over-engineered pattern: `AppException` hierarchy + `Failure` sealed class + `ErrorMapper`. Triple handling.

**Simplified:** one `sealed class AppException` used directly as `Left` in `Either<AppException, T>`. **No `Failure` class. No `ErrorMapper`.**

## Error flow

```
DioHttpClient catches error
    ↓ Either<AppException, T> via fpdart
Repository passes Either through (no catch, no mapping)
    ↓
Use Case passes Either through
    ↓
BLoC folds Either → emit Loaded or Error
    ↓
UI renders based on AppException type
```

**Key:** repos + use cases just pass Either through. No try/catch, no mapping. Typed from source to UI.

## `AppException` (sealed) — `lib/core/error/app_exception.dart`

```dart
sealed class AppException {
  String get message;      // technical, for logs
  String get userMessage;  // safe to display
}
```

### Subtypes

| Type | When | userMessage |
|---|---|---|
| `NetworkException` | no connectivity, timeout, DNS | "Please check your internet connection." |
| `ServerException(int statusCode)` | 5xx | "Something went wrong. Please try again later." |
| `BadRequestException` | 400 | "Invalid request." |
| `UnauthorizedException` | 401 (usually interceptor handles) | "Session expired. Please log in again." |
| `ForbiddenException` | 403 | "You don't have access to this content." |
| `NotFoundException` | 404 | "Content not found." |
| `ValidationException(Map<String, List<String>> fieldErrors)` | 422 | "Please check your input." |
| `RateLimitException(Duration? retryAfter)` | 429 | "Too many requests. Please wait." |
| `DataMismatchException(String fieldName)` | JSON parse failure | "We received unexpected data." |
| `CacheException` | local storage errors | "Unable to load saved data." |
| `StorageException` | Drift / secure storage errors | "Unable to access storage." |
| `UnknownException` | catch-all | "An unexpected error occurred." |

> `DataMismatchException` is the JSON-specific subtype → `07_JSON_PARSING_CODABLE.md#datamismatchexception`.

### Removed
| Removed | Why |
|---|---|
| `Failure` sealed class | duplicated `AppException` 1:1 |
| `failure.dart` | deleted |
| `ErrorMapper` | no mapping needed |
| `AppException` → `Failure` conversion in every repo | zero boilerplate now |

## How errors are created

### In `DioHttpClient`
`DioException` → `AppException` subtype via factory:
```dart
static AppException fromDioError(DioException e) → AppException
```
The **only** place network errors are created. Lives on `AppException` itself (or static on `DioHttpClient`).

### In Drift / local storage
Repo catches Drift exceptions locally and wraps in `CacheException`:
```dart
try {
  return right(await dao.getBooks());
} on Exception catch (e) {
  return left(CacheException(message: e.toString()));
}
```
The **only** try/catch in the entire data flow. Network errors are already `Either` from `DioHttpClient`.

## BLoC error handling

```dart
final result = await getBooks(page: event.page);
result.fold(
  (exception) => emit(LibraryError(exception: exception)),
  (books) => emit(LibraryLoaded(books: books)),
);
```

**Error state:**
```dart
final class LibraryError extends LibraryState {
  const LibraryError({required this.exception});
  final AppException exception;
}
```
UI uses `exception.userMessage` for display and `exception` type for icon/action.

## fpdart `Either` API reference

Do not re-implement:

| Method | Purpose | Use in |
|---|---|---|
| `fold(onLeft, onRight)` | pattern match | BLoCs → map to states |
| `map(fn)` | transform Right | repo — DTO → entity |
| `flatMap(fn)` | chain Either-returning ops | use case composition |
| `mapLeft(fn)` | transform Left | rare — remap types |
| `getOrElse(defaultFn)` | extract Right or default | UI fallback |
| `match` | alias for `fold` | same |
| `isLeft()` / `isRight()` | check which side | guards |
| `toOption()` | discard error → `Option<T>` | when details don't matter |

### `TaskEither` (optional)

For purely async repository methods, `TaskEither` can clean up composition:
```dart
// Standard:
Future<Either<AppException, Book>> getBook(String id) async =>
    httpClient.request<BookModel>(...);

// TaskEither:
TaskEither<AppException, Book> getBook(String id) =>
    TaskEither(() => httpClient.request<BookModel>(...));
```

**Rule:** `TaskEither` when composing 2+ async Either ops; plain `Future<Either>` for simple single calls.

## Error page (`lib/shared/widgets/app_error_page.dart`)

| Prop | Type | Default |
|---|---|---|
| `exception` | `AppException` | required |
| `onRetry` | `VoidCallback?` | `null` (hides retry) |

`switch` exhaustively on `AppException` — no `default`; group via pattern alternation if icon/action shared.

| Type | Icon | Retryable |
|---|---|---|
| `NetworkException` | `Icons.wifi_off` | ✓ |
| `ServerException` | `Icons.cloud_off` | ✓ |
| `BadRequestException` / `ValidationException` | `Icons.error_outline` | ✗ |
| `UnauthorizedException` / `ForbiddenException` | `Icons.lock_outline` | ✗ (redirect) |
| `NotFoundException` | `Icons.search_off` | ✗ |
| `RateLimitException` | `Icons.schedule` | ✓ |
| `DataMismatchException` / `CacheException` / `StorageException` / `UnknownException` | `Icons.error_outline` | ✓ |

Layout:
```
Center → Column
  ├── Icon(64×64, colorScheme.error)
  ├── gap AppDimensions.spacingL
  ├── Text(exception.userMessage, textTheme.bodyMedium)
  ├── gap AppDimensions.spacingL
  └── FilledButton('Try Again', onPressed: onRetry)  // if retryable
```

## Global error handlers

Setup in `main.dart` + `bootstrap.dart` → `04_APP_BOOTSTRAP.md#global-error-handling-setup`.

| Handler | Catches |
|---|---|
| `FlutterError.onError` | rendering, layout overflows, assertion failures |
| `PlatformDispatcher.instance.onError` | uncaught Future / isolate errors |
| `AppBlocObserver.onError` | BLoC/Cubit errors |

All three → `AppLogger.error()` + `CrashReporter.recordError()`.

BLoC observer hooks → `08_STATE_MANAGEMENT.md#bloc-observer`.

## Production crash prevention

### `SafeStateMixin` — async callbacks after dispose

`lib/shared/mixins/safe_state_mixin.dart`

```dart
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}
```

**When to use:** `StatefulWidget`s launching async work (timers, animations, manual futures). Not needed with BLoC — `BlocBuilder` handles this automatically.

**Rule:** prefer BLoC/Cubit over `StatefulWidget` + `setState`. Use `SafeStateMixin` only for the rare case where ephemeral state needs async work (e.g., animation controller with async trigger).

### App lifecycle (`WidgetsBindingObserver`)

| State | Action |
|---|---|
| `resumed` | refresh stale data, sync pending changes, re-check token |
| `paused` | save reading progress, flush pending analytics |
| `detached` | cancel non-critical network requests |
| `inactive` | none (transient — app switcher, call overlay) |

```dart
class AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:     /* refresh, sync queue */
      case AppLifecycleState.paused:      /* save progress, flush analytics */
      case AppLifecycleState.detached:    /* cancel non-critical requests */
      case _:                              break;
    }
  }
}
```
Register in `bootstrap()` via `WidgetsBinding.instance.addObserver(observer)`.

### Race condition prevention checklist

| Scenario | Prevention | Implemented in |
|---|---|---|
| Concurrent token refresh | `QueuedInterceptorsWrapper` | `AuthInterceptor` (Doc 06) |
| Double-tap submit | `droppable()` transformer on write events | BLoC handler (Doc 08) |
| Search-as-you-type flood | `restartable()` cancels previous | BLoC handler (Doc 08) |
| Stale callback after dispose | `SafeStateMixin.mounted` check | Stateful widgets |
| Orphaned network request | `CancelToken.cancel()` in BLoC `close()` | BLoC disposal (Doc 08) |
| Concurrent Drift writes | `transaction()` | Repository (Doc 10) |
| Multiple BLoCs refreshing same data | Shared use case pattern | BLoC comm (Doc 08) |
| Deep link during cold start | `AuthGuard` + deferred nav | Route guard (Doc 09) |

### Concurrent Drift writes

Wrap multi-source writes in a transaction:
```dart
Future<void> syncAndUpdate(List<Bookmark> remote) async {
  await database.transaction(() async {
    await bookmarkDao.deleteAll();
    await bookmarkDao.insertAll(remote);
  });
}
```
Drift serializes transactions automatically — concurrent transactions queue safely. No manual locking.

### Android process death

| Survives | Doesn't |
|---|---|
| Drift DB | in-memory BLoC state |
| SharedPreferences | active network requests |
| `flutter_secure_storage` | stream subs |
| nav stack (auto_route restores) | ephemeral widget state |

**Strategy:** persist critical state (reading progress, form drafts) to Drift/SharedPreferences immediately. On `resumed`, re-hydrate BLoCs from local storage before fetching remote.
