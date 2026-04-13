# 09 - Navigation & Deep Linking (auto_route)

## Overview

Navigation uses `auto_route` exclusively. auto_route provides:
- Declarative route definitions with code generation
- Type-safe route arguments
- Deep linking with path parameters and `DeepLinkBuilder`
- Route guards via `AutoRouteGuard`
- Nested tab navigation via `AutoTabsRouter` / `AutoTabsScaffold`
- Built-in context extensions (`context.router`, `context.pushRoute()`, etc.)
- `AutoRouteObserver` for analytics/screen tracking
- Custom page transitions per route

**No custom navigation extensions needed.** auto_route provides everything.

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

Uses `AutoTabsScaffold` (built into auto_route):

```
HomeRoute (AutoTabsScaffold)
├── Tab 0: LibraryRoute
│   └── BookDetailRoute (pushed on top)
├── Tab 1: SearchRoute (future)
└── Tab 2: SettingsRoute
```

`AutoTabsScaffold` handles tab persistence, state retention, and nested navigation stacks automatically.

---

## Navigation API (Built into auto_route)

**Do NOT create custom navigation extensions.** Use auto_route's built-in context extensions directly:

| Built-in Method | Purpose |
|-----------------|---------|
| `context.router` | Access the nearest `StackRouter` |
| `context.pushRoute(BookDetailRoute(bookId: id))` | Push a typed route |
| `context.replaceRoute(HomeRoute())` | Replace current route |
| `context.maybePop()` | Pop if possible (safe) |
| `context.router.navigate(route)` | Navigate (push or replace depending on stack) |
| `context.tabsRouter` | Access nearest `TabsRouter` (for tab switching) |
| `context.routeData` | Access current route's data, params, query params |

### Why No Custom Extensions

```dart
// WRONG - unnecessary wrapper:
extension NavigationX on BuildContext {
  void navigateToBook(String bookId) =>
    pushRoute(BookDetailRoute(bookId: bookId));
}

// RIGHT - just use auto_route directly:
context.pushRoute(BookDetailRoute(bookId: bookId));
```

Custom navigation wrappers add indirection, hide the actual route being navigated to, and make searching for route usages harder. auto_route's typed routes are already self-documenting.

---

## Route Guards

### AuthGuard

**File**: `lib/router/guards/auth_guard.dart`

Extends `AutoRouteGuard` (built into auto_route). Implements `onNavigation()`.

**Dependencies**: `TokenProvider` (via GetIt)

**Logic**:
1. Check if valid access token exists via `TokenProvider.hasValidToken()`
2. If yes: `resolver.next(true)` (allow navigation)
3. If no: `resolver.redirectUntil(LoginRoute())` (redirect, auto-restores original destination after login)

**Applied to**: All routes except `SplashRoute`, `LoginRoute`, `ErrorRoute`

**Note**: `redirectUntil` (v9 API) automatically defers the original deep link destination. After successful login, the user is taken to where they originally intended to go. No manual state management needed.

---

## Deep Link Configuration

### URI Scheme

| Platform | Scheme | Example |
|----------|--------|---------|
| Both | `readingapp://` | `readingapp://books/abc123` |
| Android | `https://readingapp.com/` | `https://readingapp.com/books/abc123` |
| iOS | `https://readingapp.com/` | Universal link |

### Deep Link Builder

auto_route provides `DeepLinkBuilder` to intercept and validate deep links:

```
// In AppRouter config:
deepLinkBuilder: (deepLink) {
  // Validate, transform, or reject deep links
  if (deepLink.path.startsWith('/books')) return deepLink;
  return DeepLink.defaultPath; // fallback to home
}
```

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

## Screen Tracking with AutoRouteObserver

**Built into auto_route.** No custom observer class needed for basic screen tracking.

```
// In MaterialApp.router:
routerConfig: _appRouter.config(
  navigatorObservers: () => [AutoRouteObserver()],
)
```

For analytics integration, extend `AutoRouterObserver`:

```
class AnalyticsRouteObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    analyticsService.trackScreen(route.settings.name ?? '');
  }
}
```

Register in `navigatorObservers`. The builder returns **fresh instances** (required - an observer can only be used by a single router).

---

## Page Transitions

### Default Transitions

Configured in `AppTheme.build()` via `pageTransitionsTheme`:

| Platform | Transition | Duration |
|----------|-----------|----------|
| Android | `ZoomPageTransitionsBuilder` (Material default) | 300ms |
| iOS | `CupertinoPageTransitionsBuilder` (slide from right) | 350ms |

### Per-Route Overrides

Use `@RoutePage` annotation:

| Route | Transition | Reason |
|-------|-----------|--------|
| `ReaderRoute` | `FadeTransition` | Seamless content entry |
| Modal dialogs | `SlideTransition` (bottom-up) | Platform convention |
| Tab switches | Instant (no animation) | Tabs should feel instant |

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
  → tap book → context.pushRoute(BookDetailRoute(bookId: id))
    → tap "Read" → context.pushRoute(ReaderRoute(bookId: id, chapterIndex: 0))
    → tap "Continue" → context.pushRoute(ReaderRoute(bookId: id, chapterIndex: saved))
```

### Deep Link Flow
```
readingapp://books/abc123
  → AuthGuard.onNavigation()
    ├── Token valid → BookDetailRoute(bookId: "abc123")
    └── No token → redirectUntil(LoginRoute()) → after login → BookDetailRoute(bookId: "abc123")
```
