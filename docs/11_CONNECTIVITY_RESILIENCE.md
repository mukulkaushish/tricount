# 11 - Connectivity & Resilience

## Connectivity Service

### Interface

**File**: `lib/core/connectivity/connectivity_service.dart`

| Method / Property | Returns | Purpose |
|-------------------|---------|---------|
| `isConnected` | `Future<bool>` | One-shot connectivity check |
| `onConnectivityChanged` | `Stream<bool>` | Real-time connectivity stream |

### Implementation

**File**: `lib/core/connectivity/connectivity_adapter.dart`

- Wraps `connectivity_plus` package
- Maps `ConnectivityResult` to simple `bool` (connected vs not)
- `ConnectivityResult.none` → `false`; all others → `true`
- Debounces rapid connectivity flips (500ms) to avoid UI flicker

---

## ConnectivityBloc

**File**: `lib/core/connectivity/connectivity_bloc/`

### Events

| Event | Source |
|-------|--------|
| `ConnectivityStarted` | App init - starts listening to stream |
| `ConnectivityChanged(bool isConnected)` | From connectivity stream |

### States

| State | Meaning |
|-------|---------|
| `ConnectivityInitial` | Not yet checked |
| `ConnectivityOnline` | Device has network |
| `ConnectivityOffline` | No network detected |

### Behavior

1. On `ConnectivityStarted`: subscribe to `ConnectivityService.onConnectivityChanged`
2. On each emission: emit `ConnectivityOnline` or `ConnectivityOffline`
3. On transition to `ConnectivityOnline` after being offline: trigger refresh events on other BLoCs (via inter-BLoC communication or event bus)

---

## Connectivity Banner

**File**: `lib/shared/widgets/connectivity_banner.dart`

### Placement

Wrapped around the entire app in `MaterialApp.router`'s `builder`:

```
MaterialApp.router(
  builder: (context, child) => ConnectivityBanner(child: child!),
)
```

### Behavior

| Connectivity State | Banner |
|-------------------|--------|
| Online | Hidden (zero height) |
| Offline | Animated slide-in from top, red/orange background |
| Reconnected | Brief green "Back online" banner, auto-dismiss after 3 seconds |

### Visual Specification

- **Offline banner**: Full-width, 44px height, `colorScheme.error` background, white text, Wi-Fi off icon
- **Text**: "No internet connection"
- **Animation**: `SlideTransition` + `SizeTransition`, 300ms duration, `Curves.easeOut`
- **Dismissal**: Cannot be dismissed by user while offline
- **Reconnected banner**: Same dimensions, green background, "Back online" text, auto-hides

### Accessibility

- Banner has `Semantics(liveRegion: true)` so screen readers announce connectivity changes
- Sufficient contrast ratio on both light and dark themes

---

## Offline-First Strategy

### Data Availability Matrix

| Feature | Offline Capable? | Data Source When Offline |
|---------|-----------------|------------------------|
| Library (cached books) | Yes | Drift (BooksTable) |
| Book Detail (cached) | Yes | Drift (BooksTable) |
| Reader (cached chapters) | Yes | Drift (ChaptersTable) |
| Reading Progress | Yes (local save) | Drift (ReadingProgressTable) |
| Bookmarks | Yes (local save) | Drift (BookmarksTable) |
| Search | No | Show offline message |
| Login | No | Show offline message |
| Sync | No | Queued until online |

### Stale-While-Revalidate Pattern

1. Repository checks local cache first
2. If cache exists: return cached data immediately
3. If online: fetch fresh data in background
4. If fresh data differs: update cache, emit new state
5. If offline and no cache: emit error state

### Sync Queue

For write operations (progress, bookmarks) made while offline:

1. Save to local Drift DB immediately
2. Add to sync queue (a Drift table with pending operations)
3. When connectivity restored: process queue in order
4. On success: remove from queue
5. On conflict: server wins (last-write-wins for progress)

---

## Retry Policies

### Network Request Retry

(See also: 06_NETWORKING_LAYER.md - RetryInterceptor)

| Scenario | Retry? | Strategy |
|----------|--------|----------|
| 5xx server error | Yes | Exponential backoff, max 3 |
| Timeout | Yes | Exponential backoff, max 3 |
| No connectivity | Wait | Pause until online, then retry once |
| 4xx client error | No | Immediate failure |
| SSL error | No | Immediate failure |

### BLoC-Level Retry

- Error states include the original event for retry
- UI shows "Retry" button on error pages
- Retry button re-dispatches the original event
- No automatic retry at BLoC level (user-initiated only)

---

## Graceful Degradation

| Component | When Offline | Behavior |
|-----------|-------------|----------|
| Book covers | Cached by `cached_network_image` | Shows cached image or placeholder |
| Chapter content | Cached in Drift | Shows cached content |
| Reading progress | Saved locally | Auto-syncs when back online |
| Theme changes | Local only | Already persisted via SharedPreferences |
| API calls | Interceptor serves cache | Stale data with "offline" indicator |
