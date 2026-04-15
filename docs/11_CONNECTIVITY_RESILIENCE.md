# 11 — Connectivity & Resilience

> Offline examples use a sample content domain.

## `ConnectivityService` (`lib/core/connectivity/connectivity_service.dart`)

Thin concrete wrapper around `connectivity_plus`. **No abstract interface** — unlikely to be swapped; in tests mock `ConnectivityService` itself via mocktail.

| Member | Returns | Purpose |
|---|---|---|
| `isConnected` | `Future<bool>` | one-shot check |
| `onConnectivityChanged` | `Stream<bool>` | real-time stream |

- Wraps `connectivity_plus`'s `Connectivity()` singleton.
- Maps `List<ConnectivityResult>` → `bool`. `ConnectivityResult.none` → `false`; all others → `true`.
- Debounces rapid flips (500 ms) to avoid banner flicker.

**Removed:** abstract interface + `ConnectivityAdapter`/`connectivity_adapter.dart` — over-abstraction.

## `ConnectivityBloc` (`lib/core/connectivity/connectivity_bloc/`)

**Events:** `ConnectivityStarted` (app init — subscribe), `ConnectivityChanged(bool isConnected)` (from stream).

**States:** `ConnectivityInitial`, `ConnectivityOnline`, `ConnectivityOffline`.

**Behavior:**
1. `ConnectivityStarted` → subscribe to `ConnectivityService.onConnectivityChanged`.
2. Each emission → emit `ConnectivityOnline` / `ConnectivityOffline`.
3. Transition offline→online → trigger refresh events on other BLoCs (inter-BLoC comm or event bus).

## Connectivity banner (`lib/shared/widgets/connectivity_banner.dart`)

Wrapped globally in `MaterialApp.router`'s `builder`:
```dart
MaterialApp.router(builder: (context, child) => ConnectivityBanner(child: child!))
```

| State | Banner |
|---|---|
| Online | hidden (zero height) |
| Offline | slide-in from top, `colorScheme.error` bg, white text, Wi-Fi off icon, 44px |
| Reconnected | brief green "Back online", auto-dismiss after 3s |

**Text:** "No internet connection". **Animation:** `SlideTransition` + `SizeTransition`, 300 ms, `Curves.easeOut`. **Not dismissible** by user while offline.

**Accessibility:** `Semantics(liveRegion: true)` so screen readers announce changes. Sufficient contrast light + dark.

## Offline-first strategy

| Feature | Offline? | Source |
|---|---|---|
| Library (cached) | ✓ | Drift BooksTable |
| Book detail | ✓ | Drift BooksTable |
| Reader (cached) | ✓ | Drift ChaptersTable |
| Reading progress | ✓ | Drift ReadingProgressTable |
| Bookmarks | ✓ | Drift BookmarksTable |
| Search | ✗ | offline message |
| Login | ✗ | offline message |
| Sync | ✗ | queued until online |

### Stale-while-revalidate
1. Repo checks local cache first.
2. Cache exists → return immediately.
3. Online → fetch fresh in background.
4. Fresh differs → update cache + emit new state.
5. Offline + no cache → emit error.

### Sync queue (writes while offline)
1. Save to local Drift immediately.
2. Append to sync queue table.
3. On connectivity restore, process in order.
4. On success, remove from queue.
5. On conflict → server wins (last-write-wins for progress).

## Retry policies

- **Network request retry** — handled by `RetryInterceptor` → `06_NETWORKING_LAYER.md#retryinterceptor`.
- **BLoC-level retry** — error states include original event; UI shows "Retry" button; re-dispatches. No auto retry (user-initiated).

## Graceful degradation

| Component | Offline behavior |
|---|---|
| Book covers | `cached_network_image` cached / placeholder |
| Chapter content | Drift cached |
| Reading progress | local, auto-sync on reconnect |
| Theme changes | local (SharedPreferences) |
| API calls | interceptor serves stale cache with "offline" indicator |
