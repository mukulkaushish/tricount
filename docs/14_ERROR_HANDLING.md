# 14 - Error Handling

## Error Flow

```
Exception thrown (anywhere)
    │
    ▼
Caught at Repository layer
    │
    ▼
Mapped to Failure (sealed class)
    │
    ▼
Returned as Either<Failure, T> to Use Case
    │
    ▼
Passed to BLoC
    │
    ▼
BLoC emits Error state with Failure
    │
    ▼
UI renders AppErrorPage or inline error
```

---

## Exception Hierarchy

(Defined in `lib/core/error/app_exception.dart`)

```
AppException (abstract)
│   fields: String message, String? code, StackTrace? stackTrace
│
├── NetworkException              # No connectivity, timeout, DNS failure
├── ServerException               # 5xx responses
│     field: int statusCode
├── BadRequestException           # 400
├── UnauthorizedException         # 401 (usually handled by interceptor)
├── ForbiddenException            # 403
├── NotFoundException             # 404
├── ValidationException           # 422
│     field: Map<String, List<String>> fieldErrors
├── RateLimitException            # 429
│     field: Duration? retryAfter
├── DataMismatchException         # JSON parsing failures
│     field: String fieldName
├── CacheException                # Local cache read/write errors
├── StorageException              # Drift or secure storage errors
└── UnknownException              # Catch-all
```

---

## Failure Sealed Class

**File**: `lib/core/error/failure.dart`

Used as the `Left` type in `Either<Failure, T>`:

```
Failure (sealed)
│   fields: String message, String? userMessage
│
├── Failure.network(message)
├── Failure.server(message, statusCode)
├── Failure.auth(message)
├── Failure.notFound(message)
├── Failure.validation(message, fieldErrors)
├── Failure.parsing(message, fieldName)
├── Failure.cache(message)
├── Failure.storage(message)
└── Failure.unknown(message)
```

### Exception-to-Failure Mapping

**File**: `lib/core/error/error_mapper.dart`

| Exception | Failure |
|-----------|---------|
| `NetworkException` | `Failure.network()` |
| `ServerException` | `Failure.server()` |
| `UnauthorizedException` | `Failure.auth()` |
| `NotFoundException` | `Failure.notFound()` |
| `ValidationException` | `Failure.validation()` |
| `DataMismatchException` | `Failure.parsing()` |
| `CacheException` | `Failure.cache()` |
| `StorageException` | `Failure.storage()` |
| All others | `Failure.unknown()` |

### User-Facing Messages

**File**: `lib/core/error/error_mapper.dart`

Each `Failure` has a `userMessage` that is safe to display:

| Failure Type | User Message |
|-------------|-------------|
| `network` | "Please check your internet connection and try again." |
| `server` | "Something went wrong on our end. Please try again later." |
| `auth` | "Your session has expired. Please log in again." |
| `notFound` | "The content you're looking for could not be found." |
| `validation` | "Please check your input and try again." |
| `parsing` | "We received unexpected data. Please try again." |
| `cache` | "Unable to load saved data." |
| `unknown` | "An unexpected error occurred. Please try again." |

---

## Error State Page

**File**: `lib/shared/widgets/app_error_page.dart`

### Props

| Prop | Type | Required | Default |
|------|------|----------|---------|
| `failure` | `Failure` | Yes | - |
| `onRetry` | `VoidCallback?` | No | null (hides retry button) |
| `fullScreen` | `bool` | No | `true` |

### Layout

```
Center
└── Column
    ├── Icon (error icon, 64x64, colorScheme.error)
    ├── SizedBox(24)
    ├── Text (error title, titleLarge)
    ├── SizedBox(8)
    ├── Text (userMessage, bodyMedium, textSecondary)
    ├── SizedBox(24)
    └── ElevatedButton ("Try Again") [if onRetry != null]
```

### Failure-Specific Icons

| Failure Type | Icon |
|-------------|------|
| `network` | `Icons.wifi_off` |
| `server` | `Icons.cloud_off` |
| `notFound` | `Icons.search_off` |
| `auth` | `Icons.lock_outline` |
| Default | `Icons.error_outline` |

---

## Error Boundary Widget

**File**: `lib/shared/widgets/error_boundary.dart` (optional)

A widget that catches errors in its child tree and shows `AppErrorPage` instead of a red error screen.

| Prop | Type | Purpose |
|------|------|---------|
| `child` | `Widget` | The widget tree to protect |
| `onError` | `void Function(Object, StackTrace)?` | Error callback (for logging) |
| `fallback` | `Widget Function(Object)?` | Custom fallback widget |

---

## Repository Error Handling Pattern

Every repository method follows this pattern:

1. Wrap the entire body in a `try-catch`
2. Call data source methods
3. On success: return `Right(data)`
4. On `AppException`: map to `Failure`, return `Left(failure)`
5. On any other `Exception`: wrap in `UnknownException`, map to `Failure.unknown()`, return `Left(failure)`
6. Log all errors via `AppLogger`

### Either<Failure, T> Usage

- Repositories return `Either<Failure, T>`
- Use Cases pass through or compose `Either` values
- BLoCs fold the Either: `result.fold((failure) => emit(Error(failure)), (data) => emit(Loaded(data)))`

---

## Global Error Handlers

Set up in `main.dart`:

### FlutterError.onError
- Catches: rendering errors, layout overflows, assertion failures
- Action: Log + report to CrashReporter
- In debug: also shows red error screen (default Flutter behavior)

### PlatformDispatcher.instance.onError
- Catches: uncaught Future errors, isolate errors
- Action: Log + report to CrashReporter
- Returns: `true` (error handled)

### BLoC.observer (AppBlocObserver)
- `onError`: Log + report to CrashReporter
- `onTransition`: Log at verbose level (debug builds only)
