# 09 — Navigation & Deep Linking (auto_route)

> Route names and deep-link schemes below are illustrative.
> This doc describes the **target** auto_route architecture. When this package is not yet in the project, treat examples as planned.

## Overview

Navigation uses `auto_route` exclusively. It provides:
- Declarative routes + code generation
- Typed args via `@PathParam` / `@QueryParam`
- Deep linking with path params + `DeepLinkBuilder`
- Route guards via `AutoRouteGuard`
- Reactive guard re-checks (`reevaluateListenable` or `router.reevaluateGuards()`)
- Per-route DI via `WrappedRoute` mixin
- Nested tabs via `AutoTabsRouter` / `AutoTabsScaffold`
- Built-in `context.router`/`context.pushRoute()` extensions
- `TransitionsBuilders` library + `CustomRoute`
- `AutoRouteObserver` (per-page) + `AutoRouterObserver` (global)

**No custom nav extensions needed.** auto_route provides everything.

## Route definitions (`lib/router/app_router.dart`)

| Route | Path | Page | Guard | Deep link |
|---|---|---|---|---|
| `SplashRoute` | `/` | `SplashPage` | — | — |
| `LoginRoute` | `/login` | `LoginPage` | — | — |
| `HomeRoute` | `/home` | `HomePage` (tab shell) | `AuthGuard` | — |
| `LibraryRoute` | `/home/library` | `LibraryPage` | `AuthGuard` | ✓ |
| `BookDetailRoute` | `/home/library/:bookId` | `BookDetailPage` | `AuthGuard` | `<scheme>://books/:bookId` |
| `ReaderRoute` | `/reader/:bookId/:chapterIndex` | `ReaderPage` | `AuthGuard` | `<scheme>://read/:bookId/:chapterIndex` |
| `SettingsRoute` | `/home/settings` | `SettingsPage` | `AuthGuard` | — |
| `ErrorRoute` | `/error` | `AppErrorPage` | — | — |

### Typed param extraction

| Annotation | Purpose | Example |
|---|---|---|
| `@PathParam('bookId')` | URL path segment | `/books/:bookId` → `String bookId` |
| `@QueryParam('page')` | query string | `?page=2` → `int? page` |

Declared on page constructor; auto_route generates `Args` class automatically.

### Nested navigation (tabs)

Uses `AutoTabsScaffold`/`AutoTabsRouter`:
```
HomeRoute (AutoTabsScaffold)
├─ Tab 0: LibraryRoute  └─ BookDetailRoute (pushed on top)
├─ Tab 1: SearchRoute (future)
└─ Tab 2: SettingsRoute
```

| Widget | Use |
|---|---|
| `AutoTabsScaffold` | standard bottom nav / app bar |
| `AutoTabsRouter` | custom layout, full builder callback |
| `AutoTabsRouter.pageView` | swipeable |
| `AutoTabsRouter.tabBar` | TabBarView style |

`AutoTabsScaffold` accepts `bottomNavigationBuilder` + `appBarBuilder`. Handles tab persistence, state retention, nested stacks automatically.

## Navigation API (built-in)

**Do NOT create custom extensions.**

| Method | Purpose |
|---|---|
| `context.router` | nearest `StackRouter` |
| `context.pushRoute(route)` | push typed route |
| `context.replaceRoute(route)` | replace current |
| `context.maybePop()` | pop if possible (returns `bool`) |
| `context.popRoute()` | unconditional pop |
| `context.navigateTo(route)` | declarative (push or activate existing) |
| `context.navigateNamedTo(path)` | navigate by URL string |
| `context.tabsRouter` | nearest `TabsRouter` (tab switch) |
| `context.routeData` | current route data/params |
| `context.topRoute` | topmost stack data |
| `context.innerRouterOf<T>()` | nested router by type |
| `context.watchRouter` | rebuild on router state change |

**Why no wrappers:**
```dart
// ❌ unnecessary indirection
extension NavX on BuildContext {
  void navigateToBook(String bookId) => pushRoute(BookDetailRoute(bookId: bookId));
}

// ✅
context.pushRoute(BookDetailRoute(bookId: bookId));
```
Wrappers hide actual destinations, make searching for route usages harder. Typed routes are self-documenting.

## Per-route DI with `WrappedRoute`

auto_route's built-in mixin for injecting `BlocProvider`/`RepositoryProvider` at route level. **How scoped BLoCs are provided** — not via manual wrappers in router config.

```dart
@RoutePage()
class LibraryPage extends StatelessWidget implements AutoRouteWrapper {
  const LibraryPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider(
    create: (_) => sl<LibraryBloc>()..add(const LibraryBooksRequested(page: 1)),
    child: this,
  );

  @override
  Widget build(BuildContext context) {
    // LibraryBloc accessible via context.read<LibraryBloc>()
  }
}
```

| Scenario | Approach |
|---|---|
| Global BLoCs (Auth/Theme/Connectivity) | `MultiBlocProvider` at app root |
| Feature BLoCs (Library/Reader/Settings) | `WrappedRoute` — BLoC lifecycle ties to route |
| Shared repos for child routes | `RepositoryProvider` inside `wrappedRoute` |

**Why:** BLoC created on route entry, disposed on pop. No manual lifecycle. Wrapping lives with the page — DI visible at use point.

## Route guards

### `AuthGuard` (`AutoRouteGuard`) — `lib/router/guards/auth_guard.dart`

Use `AutoRouteGuard.onNavigation(...)` for auth flows. For auth changes after navigation, trigger re-checks via `reevaluateListenable` in `router.config(...)` or `router.reevaluateGuards()` from an auth listener.

**Deps:** `TokenProvider` (GetIt), optional auth state listener.

```dart
class AuthGuard extends AutoRouteGuard {
  final TokenProvider _tokenProvider;
  AuthGuard(this._tokenProvider);

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (await _tokenProvider.hasValidToken()) {
      resolver.next();
      return;
    }
    resolver.redirectUntil(
      LoginRoute(onResult: (didLogin) {
        resolver.resolveNext(didLogin, reevaluateNext: false);
      }),
    );
  }
}
```

**Reactive re-check options:**
```dart
MaterialApp.router(
  routerConfig: appRouter.config(
    reevaluateListenable: ReevaluateListenable.stream(authBloc.stream),
  ),
)
```
or
```dart
authBloc.stream.listen((_) => appRouter.reevaluateGuards());
```

**Applied to:** all routes except `SplashRoute`, `LoginRoute`, `ErrorRoute`.

## Deep link config

### Schemes
| Platform | Scheme | Example |
|---|---|---|
| Both | `<app_scheme>://` | `<app_scheme>://books/abc123` |
| Android | `https://<app_domain>/` | `https://<app_domain>/books/abc123` |
| iOS | `https://<app_domain>/` | Universal link |

### `DeepLinkBuilder`
```dart
// In AppRouter config:
deepLinkBuilder: (deepLink) {
  if (deepLink.path.startsWith('/books')) return deepLink;
  return DeepLink.defaultPath; // fallback
}
```

### Supported links
| Pattern | Resolves | Params |
|---|---|---|
| `<scheme>://books/:bookId` | `BookDetailRoute` | `bookId: String` |
| `<scheme>://read/:bookId/:chapterIndex` | `ReaderRoute` | `bookId: String, chapterIndex: int` |
| `<scheme>://library` | `LibraryRoute` | — |

### Platform config
- **Android** — `AndroidManifest.xml` intent filters (custom scheme + app links).
- **iOS** — Associated Domains entitlement + `apple-app-site-association` on server.

**Only add this when the product is actually shipping deep links/app links.** Don't front-load native config the app doesn't use.

## Screen tracking

Two observer types:

| Type | Purpose | Scope |
|---|---|---|
| `AutoRouterObserver` | global route tracking (analytics/logging) | registered on router |
| `AutoRouteObserver` (+ `AutoRouteAwareStateMixin`) | route-aware widgets (pause/resume) | mixin on pages |

### Global (analytics)
```dart
class AnalyticsRouteObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    analyticsService.trackScreen(route.settings.name ?? '');
  }
}
```
Register in `navigatorObservers`. Builder **must return fresh instances** (an observer can only be used by one router).

### Route-aware widgets
```dart
class _ReaderPageState extends State<ReaderPage> with AutoRouteAwareStateMixin<ReaderPage> {
  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    // Tab active again — refresh if stale
  }
}
```
Hooks: `didInitTabRoute`, `didChangeTabRoute`, `didPush`, `didPopNext`.

## Page transitions

Default per-platform transitions in `AppTheme.build()` → `pageTransitionsTheme` (→ `05_THEMING_SYSTEM.md`). Performance budgets → `16_ANIMATIONS_TRANSITIONS.md`.

### Built-in `TransitionsBuilders`
`fadeIn`, `slideBottom`, `slideLeft`, `slideRight`, `slideTop`, `zoomIn`, `noTransition`, `slideLeftWithFade`, `slideRightWithFade`.

### Per-route overrides with `CustomRoute`
```dart
CustomRoute(
  page: ReaderRoute.page,
  transitionsBuilder: TransitionsBuilders.fadeIn,
  durationInMilliseconds: 250,
)
```

| Route | Transition | Reason |
|---|---|---|
| `ReaderRoute` | `fadeIn` | seamless content entry |
| modal dialogs | `slideBottom` | platform convention |
| tab switches | `noTransition` | tabs feel instant |

## Built-in utility widgets

| Widget | Purpose |
|---|---|
| `AutoLeadingButton` | context-aware back/close, adapts to stack depth + dialog |
| `AutoBackButton` | simple back button |
| `AutoRouter()` | outlet for nested child routes |
| `EmptyRouterPage` | placeholder shell for nested route groups |

## Flow diagrams

**App launch:**
```
SplashRoute
 ├─ token valid → HomeRoute(LibraryTab)
 └─ no token   → LoginRoute → success → HomeRoute(LibraryTab)
```

**Reading flow:**
```
LibraryRoute → tap book → pushRoute(BookDetailRoute(bookId))
  → tap Read → pushRoute(ReaderRoute(bookId, chapterIndex: 0))
  → tap Continue → pushRoute(ReaderRoute(bookId, chapterIndex: saved))
```

**Deep link:**
```
<scheme>://books/abc123
  → AuthGuard.onNavigation()
     ├─ token valid → BookDetailRoute('abc123')
     └─ no token    → redirectUntil(LoginRoute) → after login → BookDetailRoute('abc123')
```
