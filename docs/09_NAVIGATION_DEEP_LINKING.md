# 09 - Navigation & Deep Linking (go_router)

> Route names, paths, and examples are illustrative. Replace with the real navigation model for your app.

## Overview

Navigation uses `go_router` — the Flutter team's recommended routing package, maintained in `flutter/packages`. It supersedes third-party alternatives with full official support.

**Capabilities:**
- Declarative URL-based routing
- Type-safe routes via `go_router_builder` codegen
- Route protection via `redirect` callbacks
- Deep linking (Android App Links + iOS Universal Links)
- Shell routes for persistent navigation UI (tabs, drawer)
- Built-in context extensions — no custom wrappers needed

---

## Route Definitions

**File**: `lib/router/app_router.dart`

```dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: _authRedirect,
  refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
  observers: [AnalyticsRouteObserver()],
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/login',  builder: (_, __) => const LoginPage()),
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/bills', builder: (_, __) => const BillsPage()),
        GoRoute(
          path: '/bills/:billId',
          builder: (_, state) => BillDetailPage(
            billId: state.pathParameters['billId']!,
          ),
        ),
        GoRoute(path: '/groups',   builder: (_, __) => const GroupsPage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      ],
    ),
  ],
);
```

### Route Table

| Path | Page | Guard |
|------|------|-------|
| `/splash` | `SplashPage` | None |
| `/login` | `LoginPage` | None |
| `/bills` | `BillsPage` | Auth redirect |
| `/bills/:billId` | `BillDetailPage` | Auth redirect |
| `/groups` | `GroupsPage` | Auth redirect |
| `/settings` | `SettingsPage` | Auth redirect |

---

## Auth Guard

go_router has no separate `Guard` class. Protection is a `redirect` callback on `GoRouter` — evaluated before every navigation attempt and re-evaluated whenever `refreshListenable` fires.

### File layout

```
lib/router/
  app_router.dart              # GoRouter instance
  go_router_refresh_stream.dart  # ChangeNotifier wrapper for auth stream
  auth_redirect.dart           # redirect logic (testable pure function)
```

### auth_redirect.dart

**File**: `lib/router/auth_redirect.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tricount/core/security/token_provider.dart';

/// Public routes that never require authentication.
const _publicPaths = {'/splash', '/login'};

/// Global redirect evaluated before every navigation attempt.
/// Returns a redirect path string, or null to allow navigation.
Future<String?> authRedirect(
  BuildContext context,
  GoRouterState state,
  TokenProvider tokenProvider,
) async {
  final isAuthenticated = await tokenProvider.hasValidToken();
  final isPublic = _publicPaths.contains(state.matchedLocation);

  // Unauthenticated user hitting a protected route → send to login
  // Preserve the intended destination so we can redirect back after login.
  if (!isAuthenticated && !isPublic) {
    final from = Uri.encodeComponent(state.uri.toString());
    return '/login?from=$from';
  }

  // Authenticated user hitting a login/splash → send to home
  if (isAuthenticated && isPublic) {
    return '/bills';
  }

  return null; // allow navigation
}
```

**Why preserve `from`**: Deep links and bookmarks hit protected routes directly. Storing the intended destination in a query param means the login page can redirect the user where they were going after a successful login.

### app_router.dart (wired up)

```dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  // Re-evaluate redirect whenever auth state changes (login / logout / token refresh)
  refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
  redirect: (context, state) => authRedirect(
    context,
    state,
    sl<TokenProvider>(),
  ),
  routes: [...],
);
```

### go_router_refresh_stream.dart

**File**: `lib/router/go_router_refresh_stream.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Wraps a [Stream] as a [ChangeNotifier] so go_router can
/// re-evaluate its redirect logic whenever the stream emits.
final class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

### Post-login redirect (honoring the `from` param)

In `LoginPage`, after a successful login event is emitted, read the `from` query param and navigate there:

```dart
BlocListener<AuthBloc, AuthState>(
  listenWhen: (_, current) => current is AuthAuthenticated,
  listener: (context, state) {
    // Honor deep link destination stored by authRedirect
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final destination = from != null
        ? Uri.decodeComponent(from)
        : '/bills';
    context.go(destination);
  },
  child: ...,
)
```

### Triggering logout

On session expiry (401 from `AuthInterceptor`) or explicit logout, add an event to `AuthBloc`. `GoRouterRefreshStream` detects the state change and calls `authRedirect` again, which redirects to `/login`:

```dart
// In AuthInterceptor (on 401 refresh failure):
sl<AuthBloc>().add(const SessionExpired());

// In settings / logout button:
context.read<AuthBloc>().add(const LogoutRequested());
```

No manual `context.go('/login')` needed — the redirect handles it automatically when `refreshListenable` fires.

### Redirect evaluation order

```
User taps / deep link arrives
       │
       ▼
GoRouter evaluates redirect() top-down for each matched route
       │
  authRedirect()
       ├── No valid token + protected route → return '/login?from=<original>'
       ├── Valid token + public route        → return '/bills'
       └── Otherwise                        → return null (allow)
       │
       ▼
Route builder runs, BlocProvider wraps the page
```

### What `authRedirect` does NOT handle

| Concern | Where it lives |
|---------|---------------|
| Token refresh on 401 | `AuthInterceptor` (Dio — see Doc 06) |
| Session expiry notification | `AuthBloc` emitting `SessionExpired` state |
| Permission checks (role-based) | A second `redirect` on specific routes, or in the BLoC |

---

## Navigation API

Use go_router's built-in context extensions directly:

| Method | Purpose |
|--------|---------|
| `context.go('/bills')` | Navigate (replace stack) |
| `context.push('/bills/$id')` | Push onto stack |
| `context.pop()` | Pop current route |
| `context.canPop()` | Check if pop is possible |
| `context.goNamed('bills')` | Navigate by name |
| `context.pushNamed('billDetail', pathParameters: {'billId': id})` | Push by name with params |

**Rule**: Never create custom navigation extension wrappers. go_router's typed routes are already self-documenting.

---

## Type-Safe Routes (go_router_builder)

Add to dev_dependencies:

```yaml
dev_dependencies:
  go_router_builder: ^<verified_version>
```

```dart
@TypedGoRoute<BillDetailRoute>(path: '/bills/:billId')
class BillDetailRoute extends GoRouteData {
  const BillDetailRoute({required this.billId});
  final String billId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BillDetailPage(billId: billId);
}

// Usage — compile-time safe, no string literals:
BillDetailRoute(billId: id).go(context);
```

Run `dart run build_runner build` to generate.

---

## Shell Routes (Tab Navigation)

`ShellRoute` keeps a persistent shell (bottom nav, drawer) while swapping body content:

```dart
ShellRoute(
  builder: (context, state, child) => AppShell(
    currentIndex: _indexFromPath(state.matchedLocation),
    child: child,
  ),
  routes: [
    GoRoute(path: '/bills',    builder: (_, __) => const BillsPage()),
    GoRoute(path: '/groups',   builder: (_, __) => const GroupsPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
  ],
),
```

For nested tab stacks that need independent history per tab, use `StatefulShellRoute.indexedStack` (go_router 7+):

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AppShell(shell: shell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/bills', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/groups', ...)]),
  ],
),
```

---

## Per-Route BLoC Injection

Provide scoped BLoCs inside the route builder — lifecycle ties to the route:

```dart
GoRoute(
  path: '/bills',
  builder: (context, state) => BlocProvider(
    create: (_) => sl<BillsBloc>()..add(const BillsRequested()),
    child: const BillsPage(),
  ),
),
```

For routes that need multiple BLoCs or repositories:

```dart
GoRoute(
  path: '/bills/:billId',
  builder: (context, state) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<BillDetailBloc>()),
      BlocProvider(create: (_) => sl<GroupsBloc>()),
    ],
    child: BillDetailPage(billId: state.pathParameters['billId']!),
  ),
),
```

**Global BLoCs** (Auth, Theme, Connectivity) are still provided at app root in `app.dart` via `MultiBlocProvider`.

---

## Deep Link Configuration

go_router matches deep links via path automatically — no extra builder needed for standard cases.

| Platform | Setup |
|----------|-------|
| Android | Intent filters in `AndroidManifest.xml` for custom scheme + App Links |
| iOS | Associated Domains entitlement + `apple-app-site-association` on server |

Only add platform-level setup when deep links are a shipping requirement.

---

## Screen Tracking

```dart
class AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) =>
      analyticsService.trackScreen(route.settings.name ?? '');

  @override
  void didPop(Route route, Route? previousRoute) =>
      analyticsService.trackScreen(previousRoute?.settings.name ?? '');
}
```

Register in `GoRouter(observers: [AnalyticsRouteObserver()])`.

---

## Page Transitions

Default per-platform transitions are configured in `AppTheme.build()` via `pageTransitionsTheme` → [05_THEMING_SYSTEM.md](05_THEMING_SYSTEM.md).

Per-route override with `CustomTransitionPage`:

```dart
GoRoute(
  path: '/bills/:billId',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: BillDetailPage(billId: state.pathParameters['billId']!),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
),
```

---

## Navigation Flow

```
/splash
  ├── token valid  → /bills
  └── no token     → /login
                       └── login success → /bills

/bills
  └── tap bill → /bills/:billId

Deep link: tricount://bills/abc123
  ├── authenticated → /bills/abc123
  └── not authenticated → /login → after login → /bills/abc123
```
