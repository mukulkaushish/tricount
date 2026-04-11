# 09 - Navigation & Deep Linking (auto_route)

## Overview

Navigation uses `auto_route` for:
- Declarative route definitions with code generation
- Type-safe route arguments
- Deep linking with path parameters
- Route guards for authentication
- Nested navigation (tabs)
- Custom page transitions

---

## Route Definitions

**File**: `lib/router/app_router.dart`

### Route Table

| Route Name | Path | Page | Guard | Deep Link |
|------------|------|------|-------|-----------|
| `SplashRoute` | `/` | `SplashPage` | None | No |
| `LoginRoute` | `/login` | `LoginPage` | None | No |
| `HomeRoute` | `/home` | `HomePage` (tab shell) | `AuthGuard` | No |
| `LibraryRoute` | `/home/library` | `LibraryPage` | `AuthGuard` | Yes |
| `BookDetailRoute` | `/home/library/:bookId` | `BookDetailPage` | `AuthGuard` | Yes: `readingapp://books/:bookId` |
| `ReaderRoute` | `/reader/:bookId/:chapterIndex` | `ReaderPage` | `AuthGuard` | Yes: `readingapp://read/:bookId/:chapterIndex` |
| `SettingsRoute` | `/home/settings` | `SettingsPage` | `AuthGuard` | No |
| `ErrorRoute` | `/error` | `AppErrorPage` | None | No |

### Nested Navigation (Tabs)

```
HomeRoute (AutoTabsRouter)
├── Tab 0: LibraryRoute
│   └── BookDetailRoute (pushed on top)
├── Tab 1: SearchRoute (future)
└── Tab 2: SettingsRoute
```

---

## Route Guards

### AuthGuard

**File**: `lib/router/guards/auth_guard.dart`

**Dependencies**: `TokenProvider`

**Logic**:
1. Check if valid access token exists via `TokenProvider.hasValidToken()`
2. If yes: allow navigation (return `null`)
3. If no: redirect to `LoginRoute`

**Applied to**: All routes except `SplashRoute`, `LoginRoute`, `ErrorRoute`

### ConnectivityGuard (Optional)

**File**: `lib/router/guards/connectivity_guard.dart`

**Dependencies**: `ConnectivityService`

**Logic**:
1. Check if device is online
2. If online: allow navigation
3. If offline AND route requires network (no cached data): show offline notice
4. If offline AND cached data available: allow navigation with stale-data indicator

---

## Deep Link Configuration

### URI Scheme

| Platform | Scheme | Example |
|----------|--------|---------|
| Both | `readingapp://` | `readingapp://books/abc123` |
| Android | `https://readingapp.com/` | `https://readingapp.com/books/abc123` |
| iOS | `https://readingapp.com/` | Universal link |

### Supported Deep Links

| Pattern | Resolves To | Parameters |
|---------|-------------|------------|
| `readingapp://books/:bookId` | `BookDetailRoute` | `bookId: String` |
| `readingapp://read/:bookId/:chapterIndex` | `ReaderRoute` | `bookId: String, chapterIndex: int` |
| `readingapp://library` | `LibraryRoute` | None |

### Platform Configuration

**Android**: `AndroidManifest.xml` intent filters for both custom scheme and app links
**iOS**: Associated Domains entitlement + `apple-app-site-association` file on server

---

## Page Transitions

### Default Transitions

| Platform | Transition | Duration |
|----------|-----------|----------|
| Android | `SharedAxisTransition` (horizontal) | 300ms |
| iOS | `CupertinoPageTransition` (slide from right) | 350ms |

### Custom Transitions

| Route | Transition | Reason |
|-------|-----------|--------|
| `ReaderRoute` | `FadeTransition` | Seamless content entry, no directional distraction |
| Modal dialogs | `SlideTransition` (bottom-up) | Platform convention |
| Tab switches | `FadeTransition` (100ms) | Instant feel |

### Configuration

Custom transitions are defined per-route in the `@RoutePage` annotation using `transitionsBuilder` and `durationInMilliseconds`.

---

## Navigation Extensions

**File**: `lib/core/extensions/build_context_extensions.dart`

| Extension | Purpose |
|-----------|---------|
| `context.router` | Access the nearest `StackRouter` |
| `context.pushRoute(route)` | Push a route onto the stack |
| `context.replaceRoute(route)` | Replace current route |
| `context.popRoute()` | Pop current route |
| `context.navigateToBook(bookId)` | Convenience: navigate to book detail |
| `context.openReader(bookId, chapter)` | Convenience: open reader at chapter |

---

## Navigation Flow Diagrams

### App Launch
```
SplashRoute
  ├── Has valid token? → HomeRoute (LibraryTab)
  └── No token? → LoginRoute
                    └── Login success → HomeRoute (LibraryTab)
```

### Reading Flow
```
LibraryRoute
  → tap book → BookDetailRoute(bookId)
    → tap "Read" → ReaderRoute(bookId, chapterIndex: 0)
    → tap "Continue" → ReaderRoute(bookId, chapterIndex: savedProgress)
```

### Deep Link Flow
```
readingapp://books/abc123
  → AuthGuard check
    ├── Authenticated → BookDetailRoute(bookId: "abc123")
    └── Not authenticated → LoginRoute → (after login) → BookDetailRoute(bookId: "abc123")
```

auto_route handles the deferred navigation automatically - the guard redirects to login, and after successful auth, the original deep link destination is restored.
