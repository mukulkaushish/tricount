# 06 - Networking Layer

## Architecture

```
Widget → BLoC → UseCase → Repository → ApiClient (interface)
                                              │
                                        DioApiClient (impl)
                                              │
                                     Dio instance
                                              │
                                   ┌──────────┼──────────┐
                                   │          │          │
                              AuthInterceptor  │   CacheInterceptor
                                        RetryInterceptor
                                        LoggingInterceptor
```

---

## ApiClient Interface

**File**: `lib/core/network/api_client.dart`

Abstract class defining the HTTP contract:

| Method | Signature | Purpose |
|--------|-----------|---------|
| `get` | `Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? queryParams, T Function(Map<String, dynamic>)? fromJson})` | GET requests |
| `post` | `Future<ApiResponse<T>> post<T>(String path, {dynamic data, T Function(Map<String, dynamic>)? fromJson})` | POST requests |
| `put` | `Future<ApiResponse<T>> put<T>(String path, {dynamic data, T Function(Map<String, dynamic>)? fromJson})` | PUT requests |
| `patch` | `Future<ApiResponse<T>> patch<T>(String path, {dynamic data, T Function(Map<String, dynamic>)? fromJson})` | PATCH requests |
| `delete` | `Future<ApiResponse<T>> delete<T>(String path)` | DELETE requests |

### ApiResponse<T>

A generic wrapper:

| Field | Type | Description |
|-------|------|-------------|
| `data` | `T?` | Parsed response body |
| `statusCode` | `int` | HTTP status code |
| `headers` | `Map<String, String>` | Response headers |
| `isSuccess` | `bool` | `statusCode >= 200 && statusCode < 300` |

---

## DioApiClient Implementation

**File**: `lib/core/network/dio_client.dart`

### Dio Configuration

| Setting | Value | Reason |
|---------|-------|--------|
| `baseUrl` | From environment config | Per-environment API |
| `connectTimeout` | 15 seconds | Reasonable for mobile |
| `receiveTimeout` | 30 seconds | Large content payloads |
| `sendTimeout` | 15 seconds | Upload protection |
| `contentType` | `application/json` | Standard REST |
| `responseType` | `ResponseType.json` | Auto-parse |

### Interceptor Stack (Order Matters)

Interceptors execute in registration order for requests, reverse order for responses:

```
Request flow:  LoggingInterceptor → AuthInterceptor → CacheInterceptor → RetryInterceptor → Server
Response flow: Server → RetryInterceptor → CacheInterceptor → AuthInterceptor → LoggingInterceptor
```

| Order | Interceptor | Request Phase | Response Phase | Error Phase |
|-------|-------------|---------------|----------------|-------------|
| 1 | LoggingInterceptor | Log method, URL, headers | Log status, body size | Log error details |
| 2 | AuthInterceptor | Attach Bearer token | Pass through | Handle 401 |
| 3 | CacheInterceptor | Check cache, add ETag | Store cacheable responses | Serve stale if offline |
| 4 | RetryInterceptor | Pass through | Pass through | Retry on 5xx/timeout |

---

## Interceptor Specifications

### AuthInterceptor

**File**: `lib/core/network/interceptors/auth_interceptor.dart`

**Dependencies**: `TokenProvider`, `AuthBloc`

**Request Phase**:
1. Read access token from `TokenProvider`
2. If token exists, add header: `Authorization: Bearer <token>`
3. If token is null, let request proceed without auth header

**Error Phase (401 Handling)**:
1. Receive 401 response
2. Lock the Dio request queue (prevent concurrent refresh attempts)
3. Call `TokenProvider.refreshToken()`
4. If refresh succeeds:
   - Store new token via `TokenProvider.saveToken()`
   - Retry the original request with new token
   - Unlock queue
5. If refresh fails:
   - Emit `AuthBloc.add(SessionExpired())`
   - Unlock queue
   - Reject the error (propagate to caller)

**Edge Cases**:
- Multiple concurrent 401s: only the first triggers a refresh; others wait
- Refresh token also expired: logout the user
- Endpoints that don't require auth: marked with a custom `Options` extra flag

### RetryInterceptor

**File**: `lib/core/network/interceptors/retry_interceptor.dart`

**Dependencies**: `RetryStrategy`, `ConnectivityService`

**Retry Policy** (default `ExponentialBackoffStrategy`):

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

**Dependencies**: `CacheStrategy`, `LocalDatabase` or in-memory map

**Request Phase**:
1. Check if request is cacheable (GET only, not marked `no-cache`)
2. If cached response exists and is fresh (TTL not expired): resolve with cached data
3. If cached response exists but stale: add `If-None-Match: <etag>` or `If-Modified-Since` header

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

### LoggingInterceptor

**File**: `lib/core/network/interceptors/logging_interceptor.dart`

**Dependencies**: `AppLogger`

**Request Phase** (logged at `debug` level):
```
→ GET https://api.readingapp.com/v1/books?page=1
  Headers: {Authorization: Bearer ***}
  Query: {page: 1}
```

**Response Phase** (logged at `debug` level):
```
← 200 GET /v1/books (234ms)
  Size: 12.4 KB
```

**Error Phase** (logged at `error` level):
```
✗ 500 GET /v1/books (1204ms)
  Error: Internal Server Error
  Body: {"message": "..."}
```

**Privacy**: Authorization header values are masked. Request bodies with `password` fields are redacted.

---

## Error Mapping

Dio errors are mapped to `AppException` subtypes:

| Dio Error | Maps To | User Message |
|-----------|---------|-------------|
| `DioExceptionType.connectionTimeout` | `NetworkException` | "Connection timed out" |
| `DioExceptionType.receiveTimeout` | `NetworkException` | "Server took too long" |
| `DioExceptionType.connectionError` | `NetworkException` | "No internet connection" |
| Status 400 | `BadRequestException` | "Invalid request" |
| Status 401 | `UnauthorizedException` | (handled by AuthInterceptor) |
| Status 403 | `ForbiddenException` | "Access denied" |
| Status 404 | `NotFoundException` | "Content not found" |
| Status 422 | `ValidationException` | Field-specific errors from body |
| Status 429 | `RateLimitException` | "Too many requests" |
| Status 500+ | `ServerException` | "Something went wrong" |
| Unknown | `UnknownApiException` | "Unexpected error" |
