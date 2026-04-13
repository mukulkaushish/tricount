# 09 - Navigation & Deep Linking (auto_route)

> Route names, deep-link schemes, and example paths in this document are illustrative. Replace them with the real navigation model for your app.
>
> This document describes the target navigation architecture once the app
> adopts `auto_route`. The current repository does not yet include that
> package, so treat the examples here as planned structure rather than current
> code.

## Overview

Navigation uses `auto_route` exclusively. auto_route provides:
- Declarative route definitions with code generation
- Type-safe route arguments with `@PathParam()` and `@QueryParam()`
- Deep linking with path parameters and `DeepLinkBuilder`
- Route guards via `AutoRouteGuard`
- Reactive guard re-checks via `reevaluateListenable` or `router.reevaluateGuards()`
- Per-route DI injection via `WrappedRoute` mixin
- Nested tab navigation via `AutoTabsRouter` / `AutoTabsScaffold`
- Built-in context extensions (`context.router`, `context.pushRoute()`, etc.)
- Built-in transition library via `TransitionsBuilders`
- `AutoRouteObserver` for route-aware widgets and `AutoRouterObserver` for global tracking
- Custom page transitions per route via `CustomRoute`

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
| `BookDetailRoute` | `/home/library/:bookId` | `BookDetailPage` | `AuthGuard` | Yes: `<app_scheme>://books/:bookId` |
| `ReaderRoute` | `/reader/:bookId/:chapterIndex` | `ReaderPage` | `AuthGuard` | Yes: `<app_scheme>://read/:bookId/:chapterIndex` |
| `SettingsRoute` | `/home/settings` | `SettingsPage` | `AuthGuard` | No |
| `ErrorRoute` | `/error` | `AppErrorPage` | None | No |

### Typed Parameter Extraction

auto_route generates typed arguments from path/query parameters:

| Annotation | Purpose | Example |
|-----------|---------|---------|
| `@PathParam('bookId')` | Extract from URL path segment | `/books/:bookId` -> `String bookId` |
| `@QueryParam('page')` | Extract from query string | `?page=2` -> `int? page` |

Parameters are declared on the page constructor. auto_route generates the corresponding `Args` class automatically.

### Nested Navigation (Tabs)

Uses `AutoTabsScaffold` or `AutoTabsRouter` (both built into auto_route):

```
HomeRoute (AutoTabsScaffold)
|- Tab 0: LibraryRoute
|   +-- BookDetailRoute (pushed on top)
|- Tab 1: SearchRoute (future)
+-- Tab 2: SettingsRoute
```

#### Tab Variants

| Widget | Use When |
|--------|----------|
| `AutoTabsScaffold` | Standard tab layout with bottom nav / app bar |
| `AutoTabsRouter` | Custom tab layout — full control via builder callback |
| `AutoTabsRouter.pageView` | Swipeable tabs (PageView-style) |
| `AutoTabsRouter.tabBar` | TabBarView-style tabs |

`AutoTabsScaffold` accepts `bottomNavigationBuilder` and `appBarBuilder` directly. It handles tab persistence, state retention, and nested navigation stacks automatically.

---

## Navigation API (Built into auto_route)

**Do NOT create custom navigation extensions.** Use auto_route's built-in context extensions directly:

| Built-in Method | Purpose |
|-----------------|---------|
| `context.router` | Access the nearest `StackRouter` |
| `context.pushRoute(route)` | Push a typed route onto the stack |
| `context.replaceRoute(route)` | Replace current route |
| `context.maybePop()` | Pop if possible (returns `bool`) |
| `context.popRoute()` | Unconditional pop |
| `context.navigateTo(route)` | Declarative navigate (push or activate existing) |
| `context.navigateNamedTo(path)` | Navigate by URL string |
| `context.tabsRouter` | Access nearest `TabsRouter` (for tab switching) |
| `context.routeData` | Access current route's data, params, query params |
| `context.topRoute` | Topmost route data in the stack |
| `context.innerRouterOf<T>()` | Access a specific nested router by type |
| `context.watchRouter` | Rebuilds widget when router state changes |

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

## Per-Route DI with WrappedRoute

**`WrappedRoute`** is auto_route's built-in mixin for injecting dependencies (BlocProviders, RepositoryProviders) at the route level. This is how scoped BLoCs are provided — not via manual `BlocProvider` wrappers in the router config.

### Usage Pattern

```dart
@RoutePage()
class LibraryPage extends StatelessWidget implements AutoRouteWrapper {
  const LibraryPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LibraryBloc>()..add(const LibraryBooksRequested(page: 1)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    // LibraryBloc is available here via context.read<LibraryBloc>()
  }
}
```

### When to Use WrappedRoute

| Scenario | Approach |
|----------|----------|
| Global BLoCs (Auth, Theme, Connectivity) | `MultiBlocProvider` at app root in `app.dart` |
| Feature BLoCs (Library, Reader, Settings) | `WrappedRoute` on the page — BLoC lifecycle ties to route lifecycle |
| Shared repositories needed by child routes | `RepositoryProvider` inside `wrappedRoute` |

**Why WrappedRoute**: The BLoC is created when the route is entered and disposed when popped. No manual lifecycle management. The wrapping lives with the page class itself, keeping DI visible at the point of use.

---

## Route Guards

### AuthGuard (using AutoRouteGuard)

**File**: `lib/router/guards/auth_guard.dart`

Use `AutoRouteGuard` with `onNavigation(...)` for auth flows. For auth
changes after navigation has already happened, trigger re-checks with either
`reevaluateListenable` in `router.config(...)` or `router.reevaluateGuards()`
from your auth state listener.

**Dependencies**: `TokenProvider` (via GetIt), optional auth state listener

**Setup**:
```dart
class AuthGuard extends AutoRouteGuard {
  final TokenProvider _tokenProvider;

  AuthGuard(this._tokenProvider);

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (await _tokenProvider.hasValidToken()) {
      resolver.next();
      return;
    }

    resolver.redirectUntil(
      LoginRoute(
        onResult: (didLogin) {
          resolver.resolveNext(didLogin, reevaluateNext: false);
        },
      ),
    );
  }
}
```

**Reactive re-check options**:
- Preferred when you already have a `Listenable` or auth stream: pass
  `reevaluateListenable` into `router.config(...)`
- Alternative: call `appRouter.reevaluateGuards()` from an auth listener or
  `AuthBloc` subscription when login/logout/token state changes

```dart
MaterialApp.router(
  routerConfig: appRouter.config(
    reevaluateListenable: ReevaluateListenable.stream(authBloc.stream),
  ),
)
```

```dart
authBloc.stream.listen((_) {
  appRouter.reevaluateGuards();
});
```

**Applied to**: All routes except `SplashRoute`, `LoginRoute`, `ErrorRoute`

### Guard Comparison

| Guard Type | When to Use |
|-----------|-------------|
| `AutoRouteGuard` | Route protection, including auth checks that may later be re-evaluated via `reevaluateListenable` or `router.reevaluateGuards()` |

---

## Deep Link Configuration

### URI Scheme

| Platform | Scheme | Example |
|----------|--------|---------|
| Both | `<app_scheme>://` | `<app_scheme>://books/abc123` |
| Android | `https://<app_domain>/` | `https://<app_domain>/books/abc123` |
| iOS | `https://<app_domain>/` | Universal link |

### Deep Link Builder

auto_route provides `DeepLinkBuilder` to intercept and validate deep links:

```dart
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
| `<app_scheme>://books/:bookId` | `BookDetailRoute` | `bookId: String` |
| `<app_scheme>://read/:bookId/:chapterIndex` | `ReaderRoute` | `bookId: String, chapterIndex: int` |
| `<app_scheme>://library` | `LibraryRoute` | None |

### Platform Configuration

**Android**: `AndroidManifest.xml` intent filters for both custom scheme and app links
**iOS**: Associated Domains entitlement + `apple-app-site-association` file on server

Only add this platform-specific setup when the product is actually shipping deep links or app links. Do not front-load native configuration that the current app does not use.

---

## Screen Tracking with AutoRouteObserver

auto_route has **two** observer types — they serve different purposes:

| Type | Purpose | Scope |
|------|---------|-------|
| `AutoRouterObserver` | Global route tracking (analytics, logging) | Registered on the router |
| `AutoRouteObserver` | Route-aware widgets (pause/resume behavior) | Mixin on individual pages |

### Global Screen Tracking (AutoRouterObserver)

For analytics integration, extend `AutoRouterObserver`:

```dart
class AnalyticsRouteObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    analyticsService.trackScreen(route.settings.name ?? '');
  }
}
```

Register in `navigatorObservers`. The builder returns **fresh instances** (required — an observer can only be used by a single router).

### Route-Aware Widgets (AutoRouteObserver)

For pages that need to react to being shown/hidden (e.g., pause video, refresh data):

```dart
class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>
    with AutoRouteAwareStateMixin<ReaderPage> {
  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    // Tab became active again — refresh if stale
  }
}
```

Hooks: `didInitTabRoute`, `didChangeTabRoute`, `didPush`, `didPopNext`

---

## Page Transitions

Default per-platform transitions are configured in `AppTheme.build()` via `pageTransitionsTheme` -> [05_THEMING_SYSTEM.md](05_THEMING_SYSTEM.md). Performance budgets for transitions -> [16_ANIMATIONS_TRANSITIONS.md](16_ANIMATIONS_TRANSITIONS.md).

### Built-in TransitionsBuilders Library

auto_route provides `TransitionsBuilders` with ready-made transitions — use these instead of writing custom ones:

| Builder | Effect |
|---------|--------|
| `TransitionsBuilders.fadeIn` | Fade in |
| `TransitionsBuilders.slideBottom` | Slide up from bottom |
| `TransitionsBuilders.slideLeft` | Slide from left |
| `TransitionsBuilders.slideRight` | Slide from right |
| `TransitionsBuilders.slideTop` | Slide from top |
| `TransitionsBuilders.zoomIn` | Zoom in |
| `TransitionsBuilders.noTransition` | Instant, no animation |
| `TransitionsBuilders.slideLeftWithFade` | Slide left + fade |
| `TransitionsBuilders.slideRightWithFade` | Slide right + fade |

### Per-Route Overrides with CustomRoute

Use `CustomRoute` in route definitions for route-specific transitions:

```dart
CustomRoute(
  page: ReaderRoute.page,
  transitionsBuilder: TransitionsBuilders.fadeIn,
  durationInMilliseconds: 250,
)
```

| Route | Transition | Reason |
|-------|-----------|--------|
| `ReaderRoute` | `TransitionsBuilders.fadeIn` | Seamless content entry |
| Modal dialogs | `TransitionsBuilders.slideBottom` | Platform convention |
| Tab switches | `TransitionsBuilders.noTransition` | Tabs should feel instant |

---

## Built-in Utility Widgets

auto_route provides utility widgets — use them instead of custom implementations:

| Widget | Purpose |
|--------|---------|
| `AutoLeadingButton` | Context-aware back/close button — adapts to stack depth and dialog context |
| `AutoBackButton` | Simple back button |
| `AutoRouter()` | Outlet widget for rendering nested child routes |
| `EmptyRouterPage` | Placeholder shell for nested route groups that need no UI |

---

## Navigation Flow Diagrams

### App Launch
```
SplashRoute
  |- Has valid token? -> HomeRoute (LibraryTab)
  +-- No token? -> LoginRoute
                    +-- Login success -> HomeRoute (LibraryTab)
```

### Reading Flow
```
LibraryRoute
  -> tap book -> context.pushRoute(BookDetailRoute(bookId: id))
    -> tap "Read" -> context.pushRoute(ReaderRoute(bookId: id, chapterIndex: 0))
    -> tap "Continue" -> context.pushRoute(ReaderRoute(bookId: id, chapterIndex: saved))
```

### Deep Link Flow
```
<app_scheme>://books/abc123
  -> AuthGuard.onNavigation()
    |- Token valid -> BookDetailRoute(bookId: "abc123")
    +-- No token -> redirectUntil(LoginRoute()) -> after login -> BookDetailRoute(bookId: "abc123")
```
