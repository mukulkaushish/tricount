# 06 - Networking Layer

## Design Philosophy

The networking layer follows **Dependency Inversion**: repositories depend on `HttpClient` (abstract interface), not on Dio directly. `DioHttpClient` is the concrete implementation, registered via GetIt.

Three generic methods cover every API shape with zero boilerplate:
- `request<T>` - single object response
- `requestList<T>` - list response  
- `requestEmpty` - no-body responses (DELETE, logout, etc.)

A `RequestMethod` enum replaces separate get/post/put/delete methods. A `keyPath` parameter handles nested JSON extraction. All methods return `Either<AppException, T>` via `fpdart`.

---

## Architecture

```
Widget → BLoC → UseCase → Repository → HttpClient (interface)
                                              │
                                        DioHttpClient (impl)
                                              │
                                         Dio instance
                                              │
                                   ┌──────────┼──────────┐
                                   │          │          │
                              AuthInterceptor  │   CacheInterceptor
                                        RetryInterceptor
                                     Dio LogInterceptor (built-in)
```

- Repositories import only `HttpClient` (the interface)
- `DioHttpClient` is registered against `HttpClient` in GetIt
- Swappable for testing: mock `HttpClient` in repository tests, no Dio dependency leaks

---

## RequestMethod Enum

**File**: `lib/core/network/request_method.dart`

| Value | HTTP String |
|-------|-------------|
| `RequestMethod.get` | `GET` |
| `RequestMethod.post` | `POST` |
| `RequestMethod.put` | `PUT` |
| `RequestMethod.delete` | `DELETE` |
| `RequestMethod.patch` | `PATCH` |

Extension getter `name` returns the uppercase string for Dio's `Options(method:)`.

---

## HttpClient Interface

**File**: `lib/core/network/http_client.dart`

Abstract class defining the full HTTP contract. Three core methods plus optional parameters for Dio built-in features.

### `request<T>` - Single Object

| Parameter | Type | Required | Purpose |
|-----------|------|----------|---------|
| `path` | `String` | Yes | API endpoint path |
| `method` | `RequestMethod` | Yes | HTTP verb |
| `fromJson` | `T Function(Map<String, dynamic>)` | Yes | Model factory (e.g., `BookModel.fromJson`) |
| `queryParameters` | `Map<String, dynamic>?` | No | URL query params |
| `body` | `dynamic` | No | Request body (POST/PUT/PATCH) |
| `keyPath` | `String?` | No | Dot-notation path to extract nested data |
| `cancelToken` | `CancelToken?` | No | Dio `CancelToken` for request cancellation |

**Returns**: `Future<Either<AppException, T>>`

### `requestList<T>` - List Response

Same parameters as `request<T>` (including `cancelToken`). Differences:
- `fromJson` is applied to each item in the extracted list
- Empty/null response returns `right(<T>[])` (not an error)
- **Returns**: `Future<Either<AppException, List<T>>>`

### `requestEmpty` - No Response Body

| Parameter | Type | Required | Purpose |
|-----------|------|----------|---------|
| `path` | `String` | Yes | API endpoint path |
| `method` | `RequestMethod` | Yes | HTTP verb |
| `queryParameters` | `Map<String, dynamic>?` | No | URL query params |
| `body` | `dynamic` | No | Request body |
| `cancelToken` | `CancelToken?` | No | Dio `CancelToken` for request cancellation |

**Returns**: `Future<Either<AppException, EmptyResponse>>`

No `fromJson` needed. Only validates status code is 2xx.

### EmptyResponse

**File**: `lib/shared/models/empty_response.dart`

A `const` sentinel class with no fields. Type-safe "void" for `Either`.

---

## DioHttpClient Implementation

**File**: `lib/core/network/dio_http_client.dart`

`final class DioHttpClient implements HttpClient`

### Constructor

Takes a single `Dio` instance (already configured with base URL and interceptors via DI).

### Dio Configuration (set in DI module, not in DioHttpClient)

| Setting | Value | Reason |
|---------|-------|--------|
| `baseUrl` | From environment config | Per-environment API |
| `connectTimeout` | 15 seconds | Reasonable for mobile |
| `receiveTimeout` | 30 seconds | Large content payloads |
| `sendTimeout` | 15 seconds | Upload protection |
| `contentType` | `application/json` | Standard REST |
| `responseType` | `ResponseType.json` | Auto-parse |

### Implementation Details

#### request<T> Flow
1. Call `_dio.request()` with `Options(method: method.name)`, data, query params
2. Guard: check for HTML responses (bad gateway, proxy errors)
3. Guard: check status code is 2xx
4. Extract data via `keyPath` if provided (dot-notation traversal)
5. Validate extracted data is `Map<String, dynamic>`
6. Call `fromJson` on extracted data
7. Return `right(parsed)` on success, `left(exception)` on any failure
8. Catch `DioException` → delegate to `_handleDioException`
9. Catch generic `Exception` → wrap in `UnknownException`

#### requestList<T> Flow
Same as `request<T>`, except:
- `keyPath` resolves to a `List`, not a `Map`
- Cast each item to `Map<String, dynamic>`, apply `fromJson`
- Empty/null response body → `right(<T>[])` (graceful, not error)

#### requestEmpty Flow
- Execute request, check HTML guard and status code
- Return `right(const EmptyResponse())` on success
- No JSON parsing at all

### keyPath Extraction

Private helper `_extractByKeyPath(dynamic data, String keyPath)`:

| API Response | keyPath | Extracted Data |
|-------------|---------|----------------|
| `{ "data": { "id": "1", ... } }` | `"data"` | `{ "id": "1", ... }` |
| `{ "response": { "user": { ... } } }` | `"response.user"` | `{ ... }` |
| `{ "id": "1", "title": "..." }` | `null` | Entire response as-is |
| `{ "data": [ {...}, {...} ] }` | `"data"` | `[ {...}, {...} ]` (for `requestList`) |

Split keyPath by `.`, traverse one key at a time. Return `null` if any key is missing → triggers `DataMismatchException`.

### HTML Response Detection

Private helper `_isHtmlResponse(Response response)`:

**Detection checks** (in order):
1. `Content-Type` header contains `text/html`
2. Response body (if `String`) starts with `<!doctype html` or `<html`
3. Response body contains gateway-error patterns (`bad gateway`, `502:`)

**When HTML detected**:
- Log a warning
- Create a `NetworkException` with cleared response data (forces user-friendly error message instead of HTML dump)
- Return `left(exception)`

### Error Handling (Private Methods)

#### `_handleDioException(DioException e)`
1. Check if response is HTML → create sanitized `NetworkException`
2. Otherwise → `AppException.fromDioError(e)`
3. Return `left(exception)`

#### `_handleGenericException(Exception e)`
- `left(UnknownException(e.toString()))`

---

## AppException.fromDioError Factory

**File**: `lib/core/error/app_exception.dart`

`AppException.fromDioError(DioException e)` maps Dio errors to typed `AppException` subtypes:

| Dio Error | Maps To |
|-----------|---------|
| `DioExceptionType.connectionTimeout` | `NetworkException` (timeout) |
| `DioExceptionType.receiveTimeout` | `NetworkException` (timeout) |
| `DioExceptionType.connectionError` | `NetworkException` (no connection) |
| Status 400 | `BadRequestException` |
| Status 401 | `UnauthorizedException` (usually handled by AuthInterceptor first) |
| Status 403 | `ForbiddenException` |
| Status 404 | `NotFoundException` |
| Status 422 | `ValidationException` (parses field errors from body) |
| Status 429 | `RateLimitException` |
| Status 500+ | `ServerException` |
| Unknown | `UnknownException` |

---

## Interceptor Stack (Order Matters)

Interceptors execute in registration order for requests, reverse order for responses:

```
Request flow:  LogInterceptor → AuthInterceptor → CacheInterceptor → RetryInterceptor → Server
Response flow: Server → RetryInterceptor → CacheInterceptor → AuthInterceptor → LogInterceptor
```

| Order | Interceptor | Request Phase | Response Phase | Error Phase |
|-------|-------------|---------------|----------------|-------------|
| 1 | `LogInterceptor` (Dio built-in) | Log method, URL, headers | Log status, body | Log error details |
| 2 | AuthInterceptor | Attach Bearer token | Pass through | Handle 401 |
| 3 | CacheInterceptor | Check cache, add ETag | Store cacheable responses | Serve stale if offline |
| 4 | RetryInterceptor | Pass through | Pass through | Retry on 5xx/timeout |

---

## Interceptor Specifications

### AuthInterceptor (extends QueuedInterceptorsWrapper)

**File**: `lib/core/network/interceptors/auth_interceptor.dart`

**Base class**: `QueuedInterceptorsWrapper` (Dio built-in). This ensures requests are processed sequentially during token refresh — no race conditions. Concurrent requests are automatically queued until the lock is released.

**Dependencies**: `TokenProvider`, `AuthBloc`

**Request Phase** (`onRequest`):
1. Read access token from `TokenProvider`
2. If token exists, add header: `Authorization: Bearer <token>`
3. If token is null, let request proceed without auth header

**Error Phase** (`onError`, 401 Handling):
1. Receive 401 response
2. `QueuedInterceptorsWrapper` automatically locks — subsequent requests wait
3. Call `TokenProvider.refreshToken()`
4. If refresh succeeds:
   - Store new token via `TokenProvider.saveToken()`
   - Retry the original request with new token via `handler.resolve()`
5. If refresh fails:
   - Emit `AuthBloc.add(SessionExpired())`
   - Reject the error via `handler.reject()` (propagate to caller)

**Why QueuedInterceptorsWrapper**: Regular `Interceptor` would allow concurrent requests to all trigger refresh simultaneously. `QueuedInterceptorsWrapper` serializes interceptor execution, so only the first 401 triggers a refresh; subsequent requests wait and get the new token automatically.

**Edge Cases**:
- Multiple concurrent 401s: automatically handled by queue — only the first triggers refresh
- Refresh token also expired: logout the user
- Endpoints that don't require auth: marked with a custom `Options` extra flag

### RetryInterceptor

**File**: `lib/core/network/interceptors/retry_interceptor.dart`

**Dependencies**: `ConnectivityService`

**Retry Policy** (exponential backoff):

| Attempt | Delay | Condition |
|---------|-------|-----------|
| 1 | 1 second | Status 500, 502, 503, 504, or `SocketException` |
| 2 | 2 seconds | Same |
| 3 | 4 seconds | Same |
| Max | 3 attempts | Give up, propagate error |

**Does NOT retry**:
- 4xx errors (client errors - retrying won't help)
- Request cancellation (`DioExceptionType.cancel`)
- POST/PUT/PATCH without idempotency key (unsafe to retry)

**ConnectivityService integration**: If device is offline, skip retry delay and wait for connectivity restoration (up to 30s timeout).

### CacheInterceptor

**File**: `lib/core/network/interceptors/cache_interceptor.dart`

**Dependencies**: In-memory LRU map + Drift `ApiCacheTable`

**Request Phase**:
1. Check if request is cacheable (GET only, not marked `no-cache`)
2. If cached response exists and is fresh (TTL not expired): resolve with cached data
3. If cached response exists but stale: add `If-None-Match: <etag>` header

**Response Phase**:
1. If response is 304 Not Modified: return cached body with 200 status
2. If response is 200: store in cache with ETag and timestamp
3. Respect `Cache-Control` headers from server

**Error Phase**:
1. If network error and stale cache exists: return stale cache (offline fallback)
2. Otherwise: propagate error

**Cache Storage**:
- In-memory LRU cache for session (max 50 entries)
- Drift table for persistent cache (API responses that rarely change)
- TTL: 5 minutes for lists, 30 minutes for detail pages, 24 hours for static content

### LogInterceptor (Dio Built-in)

**No custom file needed.** Dio provides `LogInterceptor` out of the box. Configured in `network_module.dart` during DI setup.

**Configuration**:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `requestHeader` | `true` | Log request headers |
| `requestBody` | `false` | Avoid logging large/sensitive POST bodies by default |
| `responseHeader` | `false` | Too verbose for development |
| `responseBody` | `false` | Avoid logging large JSON payloads |
| `error` | `true` | Always log errors |
| `logPrint` | `appLogger.debug` | Route through `AppLogger` instead of `print()` |

**Why built-in**: Dio's `LogInterceptor` already handles request/response/error logging with configurable verbosity. Building a custom one would duplicate this behavior.

**Privacy note**: Set `requestBody: false` to avoid accidentally logging passwords or tokens in POST bodies. For development debugging, enable temporarily but never commit with `true`.

### What Was Removed

| Removed | Why |
|---------|-----|
| Custom `LoggingInterceptor` | Dio's built-in `LogInterceptor` provides identical functionality with less code |
| `logging_interceptor.dart` | Deleted — use `LogInterceptor()` directly in DI setup |

---

## DI Registration

In `network_module.dart`:

```
1. Create Dio instance with BaseOptions
2. Add interceptors in order: LogInterceptor (built-in) → Auth → Cache → Retry
3. Register: sl.registerLazySingleton<HttpClient>(() => DioHttpClient(dio))
```

Repositories receive `HttpClient` (the interface) from GetIt. They never know about Dio.

---

## Repository Usage Pattern

Repositories call `HttpClient` - no try-catch needed, `Either` handles it:

```
// Single object:
httpClient.request<BookModel>(
  '/v1/books/$id',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  keyPath: 'data',
)

// List:
httpClient.requestList<BookModel>(
  '/v1/books',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  keyPath: 'data',
  queryParameters: {'page': page},
)

// Empty (DELETE, logout):
httpClient.requestEmpty(
  '/v1/user/bookmarks/$id',
  method: RequestMethod.delete,
)
```

Each call is one statement. No manual JSON extraction, no try-catch, no status code checking. All handled inside `DioHttpClient`.

---

## Testability

| What to Test | How |
|-------------|-----|
| Repository logic | Mock `HttpClient` interface with `mocktail` - return `right(model)` or `left(exception)` |
| DioHttpClient itself | Use Dio's `HttpClientAdapter` to mock HTTP responses |
| Interceptors | Test each interceptor in isolation with mock `RequestInterceptorHandler` |

The interface boundary means **repository tests never touch Dio** - they only test that the repository calls the right method with the right parameters and maps the `Either` correctly.

---

## Dio Built-in Features Reference

These are Dio features used internally by `DioHttpClient` or available for advanced use. Do not re-implement them.

| Feature | Dio API | Used For |
|---------|---------|----------|
| Request cancellation | `CancelToken` | Cancel in-flight requests (e.g., search-as-you-type, page disposal) |
| File upload | `FormData` + `MultipartFile` | Multipart uploads when needed |
| Download progress | `onReceiveProgress` callback | Large file downloads with progress |
| Upload progress | `onSendProgress` callback | File upload progress tracking |
| Per-request config | `Options(extra: {...})` | Pass metadata to interceptors (e.g., skip-auth flag) |
| Response transformer | `Transformer` | Custom response transformation (rarely needed) |
| Mock adapter | `HttpClientAdapter` | Replace HTTP transport in tests |

### CancelToken Usage

Pass a `CancelToken` through `HttpClient` methods to cancel requests when a screen is disposed or a new search replaces the previous one:

```dart
final cancelToken = CancelToken();

// In BLoC or repository:
httpClient.requestList<BookModel>(
  '/v1/books',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  cancelToken: cancelToken,
);

// On dispose or new search:
cancelToken.cancel('Operation cancelled');
```

Cancelled requests return `Left(NetworkException)` with `DioExceptionType.cancel`. The `RetryInterceptor` does NOT retry cancelled requests.
