# 06 — Networking Layer

## Philosophy

Dependency Inversion — repositories depend on `HttpClient` (abstract), never on Dio. `DioHttpClient` registered via GetIt.

Three generic methods cover every API shape:
- `request<T>` — single object
- `requestList<T>` — list
- `requestEmpty` — no body (DELETE, logout)

`RequestMethod` enum replaces separate get/post/put/delete methods. `keyPath` handles nested JSON. All methods return `Either<AppException, T>` via `fpdart`.

## Architecture

```
Widget → BLoC → UseCase → Repository → HttpClient (iface)
                                        DioHttpClient (impl)
                                        Dio
                         Interceptors: LogInterceptor(built-in) → Auth → Cache → Retry
```

Repositories import only `HttpClient`. `DioHttpClient` bound to `HttpClient` in GetIt. Swappable — mock `HttpClient` in tests, no Dio leaks.

## `RequestMethod` (`lib/core/network/request_method.dart`)

Values: `get`, `post`, `put`, `delete`, `patch`. Extension getter `.name` returns uppercase for `Options(method:)`.

## `HttpClient` interface (`lib/core/network/http_client.dart`)

### `request<T>` — single object

| Param | Type | Req | Purpose |
|---|---|---|---|
| `path` | `String` | ✓ | endpoint |
| `method` | `RequestMethod` | ✓ | verb |
| `fromJson` | `T Function(Map<String, dynamic>)` | ✓ | model factory |
| `queryParameters` | `Map<String, dynamic>?` | – | query |
| `body` | `dynamic` | – | POST/PUT/PATCH |
| `keyPath` | `String?` | – | dot-notation to nested data |
| `cancelToken` | `CancelToken?` | – | cancellation |

Returns `Future<Either<AppException, T>>`.

### `requestList<T>`
Same params (incl. `cancelToken`). `fromJson` applied per item. Empty/null → `right(<T>[])` (graceful, not error). Returns `Future<Either<AppException, List<T>>>`.

### `requestEmpty`
No `fromJson`. Only validates 2xx. Params: `path`, `method`, `queryParameters?`, `body?`, `cancelToken?`. Returns `Future<Either<AppException, EmptyResponse>>`.

### `EmptyResponse` (`core/network/empty_response.dart`)
Const sentinel with no fields; type-safe "void" for `Either`. Lives in `core/network/` — part of `HttpClient` contract, not a shared presentation model.

## `DioHttpClient` impl (`lib/core/network/dio_http_client.dart`)

`final class DioHttpClient implements HttpClient`. Constructor takes a `Dio` (configured in DI with base URL + interceptors).

**Dio config (set in DI module, not in the class):**

| Setting | Value | Reason |
|---|---|---|
| `baseUrl` | env config | per-env API |
| `connectTimeout` | 15s | mobile |
| `receiveTimeout` | 30s | large payloads |
| `sendTimeout` | 15s | upload protection |
| `contentType` | `application/json` | REST |
| `responseType` | `ResponseType.json` | auto-parse |

### `request<T>` flow
1. `_dio.request()` with `Options(method: method.name)`, body, query.
2. Guard: HTML response detection.
3. Guard: 2xx.
4. Extract via `keyPath` if provided (dot-notation traversal).
5. Validate extracted data is `Map<String, dynamic>`.
6. `fromJson(extracted)`.
7. `right(parsed)` on success; `left(exception)` on any failure.
8. Catch `DioException` → `_handleDioException`.
9. Catch generic `Exception` → wrap `UnknownException`.

### `requestList<T>` flow
Same, but `keyPath` resolves to a `List`; each item cast to `Map<String, dynamic>` and `fromJson`'d. Empty/null body → `right(<T>[])`.

### `requestEmpty` flow
Execute → HTML guard + 2xx → `right(const EmptyResponse())`. No JSON parsing.

### `_extractByKeyPath(data, keyPath)`

| Response | keyPath | Extracted |
|---|---|---|
| `{"data": {"id": "1", ...}}` | `"data"` | `{"id": "1", ...}` |
| `{"response": {"user": {...}}}` | `"response.user"` | `{...}` |
| `{"id": "1", ...}` | `null` | whole response |
| `{"data": [...]}` | `"data"` | `[...]` (list form) |

Split by `.`, traverse key-by-key. Missing → `null` → triggers `DataMismatchException`.

### `_isHtmlResponse(Response)` — bad-gateway / proxy-error detection

Checks in order:
1. `Content-Type` contains `text/html`.
2. Body (if `String`) starts with `<!doctype html` or `<html`.
3. Body contains gateway patterns (`bad gateway`, `502:`).

On detection: log warning, create `NetworkException` with cleared response data (forces user-friendly error, not HTML dump), return `left`.

### Error helpers

**`_handleDioException(DioException e)`** — HTML → sanitized `NetworkException`; else `AppException.fromDioError(e)`; `left`.
**`_handleGenericException(Exception e)`** — `left(UnknownException(e.toString()))`.

## `AppException.fromDioError` (`core/error/app_exception.dart`)

| Dio error | Maps to |
|---|---|
| `connectionTimeout` | `NetworkException` (timeout) |
| `receiveTimeout` | `NetworkException` (timeout) |
| `connectionError` | `NetworkException` (no connection) |
| 400 | `BadRequestException` |
| 401 | `UnauthorizedException` (usually `AuthInterceptor` first) |
| 403 | `ForbiddenException` |
| 404 | `NotFoundException` |
| 422 | `ValidationException` (parses field errors from body) |
| 429 | `RateLimitException` |
| 500+ | `ServerException` |
| unknown | `UnknownException` |

## Interceptor stack (order matters)

Requests go down, responses come back up:
```
Req:  Log → Auth → Cache → Retry → Server
Resp: Server → Retry → Cache → Auth → Log
```

| # | Interceptor | Req | Resp | Error |
|---|---|---|---|---|
| 1 | `LogInterceptor` (Dio built-in) | log method/URL/headers | log status/body | log error |
| 2 | `AuthInterceptor` | attach Bearer | pass | handle 401 |
| 3 | `CacheInterceptor` | check cache, add ETag | store cacheable | serve stale if offline |
| 4 | `RetryInterceptor` | pass | pass | retry 5xx/timeout |

## Interceptor specs

### `AuthInterceptor` (`interceptors/auth_interceptor.dart`)

Base: **`QueuedInterceptorsWrapper`** — serializes all interceptor callbacks so concurrent 401s only trigger one refresh; waiting requests retry with the new token.

**Deps:** `TokenProvider`, `Future<bool> Function() onRefreshToken` callback (DI-provided), `Dio` (for retry).

**`onRequest`:**
1. Read `tokenProvider.accessToken` (sync — loaded at startup).
2. If present, add `Authorization: Bearer <token>`.
3. If null, proceed unauthenticated (login endpoint etc.).

**`onError`:**
1. If status 401 AND request not already a retry (`extra['isRetry'] != true`):
   a. Call `onRefreshToken()`.
   b. Success → update header, set `extra['isRetry'] = true`, `dio.fetch(requestOptions)`, resolve with new response.
   c. Failure → `tokenProvider.clearTokens()`, propagate original 401.
2. Else propagate.

**Refresh callback (defined in `injection_container.dart`):**
- Calls `authRefreshPath` via same Dio, `extra['isRetry'] = true`.
- Parses `AuthTokenModel.fromJson`.
- `tokenProvider.saveTokens(accessToken, refreshToken)`.
- Returns `true`/`false`.

**Why queued:** without it, 3 concurrent 401s → 3 parallel refreshes (race). Queue serializes `onError` so only the first refreshes; others wait and retry with the refreshed token.

### `RetryInterceptor` (`interceptors/retry_interceptor.dart`)

**Deps:** `ConnectivityService`.

**Policy (exponential backoff):**

| Attempt | Delay | Condition |
|---|---|---|
| 1 | 1s | 500/502/503/504 or `SocketException` |
| 2 | 2s | same |
| 3 | 4s | same |
| Max | 3 | give up |

**Does NOT retry:** 4xx (won't help), `DioExceptionType.cancel`, POST/PUT/PATCH without idempotency key.

**Connectivity integration:** if offline, skip retry delay, wait for connectivity (30s timeout).

### `CacheInterceptor` (`interceptors/cache_interceptor.dart`)

**Deps:** in-memory LRU + Drift `ApiCacheTable`.

**`onRequest`:**
1. Cacheable only if GET and not `no-cache`.
2. Cached fresh (TTL valid) → resolve with cached.
3. Cached stale → add `If-None-Match: <etag>`.

**`onResponse`:**
1. 304 → return cached body with 200 status.
2. 200 → store with ETag + timestamp.
3. Respect `Cache-Control` headers.

**`onError`:**
1. Network error + stale cache → return stale (offline fallback).
2. Else propagate.

**Storage:** in-memory LRU max 50 per session; Drift persistent for rarely-changing responses. **TTL:** 5 min lists, 30 min detail, 24 h static.

### `LogInterceptor` (Dio built-in — NO custom file)

Configured in `network_module.dart`:

| Param | Value | Purpose |
|---|---|---|
| `requestHeader` | `true` | log headers |
| `requestBody` | `false` | avoid logging sensitive POST bodies |
| `responseHeader` | `false` | too verbose |
| `responseBody` | `false` | avoid large payload logs |
| `error` | `true` | always log errors |
| `logPrint` | `appLogger.debug` | route through `AppLogger`, never `print()` |

**Privacy:** keep `requestBody: false` — avoid accidental password/token logging. Enable temporarily for debugging, never commit `true`.

**Removed:** custom `LoggingInterceptor` / `logging_interceptor.dart` — Dio's built-in does the same with less code.

## DI registration (`network_module.dart`)

1. Create `Dio` with `BaseOptions`.
2. Add interceptors in order: `LogInterceptor` → `Auth` → `Cache` → `Retry`.
3. `sl.registerLazySingleton<HttpClient>(() => DioHttpClient(dio))`.

Repositories get `HttpClient` from GetIt. They never see Dio.

## Repository usage

```dart
httpClient.request<BookModel>(
  '/v1/books/$id',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  keyPath: 'data',
);

httpClient.requestList<BookModel>(
  '/v1/books',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  keyPath: 'data',
  queryParameters: {'page': page},
);

httpClient.requestEmpty(
  '/v1/user/bookmarks/$id',
  method: RequestMethod.delete,
);
```

One statement each. No manual JSON extraction, try/catch, or status checking — handled inside `DioHttpClient`.

## Testability

| Target | How |
|---|---|
| Repository logic | Mock `HttpClient` with mocktail — return `right(model)` or `left(exception)` |
| `DioHttpClient` itself | Use Dio's `HttpClientAdapter` to mock responses |
| Interceptors | Test each in isolation with mock `RequestInterceptorHandler` |

Repository tests **never touch Dio** — just verify correct method + params + `Either` mapping.

## Dio built-in features reference

Do not re-implement:

| Feature | Dio API | Used for |
|---|---|---|
| Cancellation | `CancelToken` | search-as-you-type, page disposal |
| File upload | `FormData` + `MultipartFile` | multipart uploads |
| Download progress | `onReceiveProgress` | large file downloads |
| Upload progress | `onSendProgress` | tracking upload |
| Per-request config | `Options(extra: {...})` | interceptor metadata (e.g. skip-auth) |
| Response transformer | `Transformer` | custom transformation (rare) |
| Mock adapter | `HttpClientAdapter` | test transport |

### CancelToken usage

```dart
final cancelToken = CancelToken();
httpClient.requestList<BookModel>(
  '/v1/books',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  cancelToken: cancelToken,
);
// On dispose / new search:
cancelToken.cancel('Operation cancelled');
```

Cancelled requests return `Left(NetworkException)` with `DioExceptionType.cancel`. `RetryInterceptor` does NOT retry cancelled requests.
