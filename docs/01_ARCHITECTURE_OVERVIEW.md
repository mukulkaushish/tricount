# 01 — Architecture Overview

**Clean Architecture + feature-first.** Priorities: testability, modularity, decoupling via interfaces, zero boilerplate.

## SOLID application

- **S** — each class one reason to change. BLoCs = state only (no API calls); repositories = sole data owner; use cases = one operation.
- **O** — theming open for new `AppColorPalette`, closed on `AppTheme.build()` contract. Stackable interceptors. Pluggable analytics adapters.
- **L** — any `AnalyticsService` impl (Sentry/Mixpanel/Firebase/NoOp) interchangeable. Any repository impl (remote/local/cached) satisfies the contract. Mocks honor invariants.
- **I** — `AnalyticsService` split into `EventTracker`/`CrashReporter`/`UserIdentifier`. Auth split: `TokenProvider` (token CRUD) vs `AuthBloc` (session).
- **D** — domain defines interfaces; data implements. Presentation depends on domain never data. GetIt binds abstract→concrete. Widgets never import `data/`.

## Patterns used

| Pattern | Purpose | Location / rule |
|---|---|---|
| Repository | Abstract data sources | `domain/repositories/` interface; `data/repositories/` impl; returns domain models, not DTOs |
| BLoC | Events→states, no UI logic in BLoC / no business logic in widgets | `presentation/bloc/` |
| Use Case | One business op, single `call()` | `domain/usecases/`; may compose other use cases, not cross-feature repos |
| Adapter | Wrap third-party behind app interface | Analytics adapters, `DioHttpClient` → `HttpClient`. If a package appears in `import`, it belongs behind an interface in `core/` |
| Observer | Connectivity / auth / theme streams | Core services expose streams |
| Strategy | Cache, retry, theme strategies | `core/network/interceptors/`, `core/theme/` |
| Factory | Complex object creation | `core/di/`, `AppTheme.build()` |

## Layers

```
PRESENTATION (widgets, pages, BLoCs, routes)        → Domain, Core
DOMAIN       (entities, use cases, repo interfaces) → pure Dart + pure-Dart Core
DATA         (impls, DTOs, data sources, Drift)     → Domain, Core  (implements domain ifaces)
CORE         (network, theme, DI, error, log, sec)  → SDK + packages only
```

| Layer | Can import | Cannot import |
|---|---|---|
| Presentation | Domain, Core | Data |
| Domain | Core (pure-Dart only: `AppException`, value helpers, non-Flutter extensions) | Presentation, Data, Flutter |
| Data | Domain, Core | Presentation |
| Core | Dart/Flutter SDK, pub packages | Domain, Data, Presentation |

## Feature module layout

```
feature/
├── data/        datasources/  models/  repositories/
├── domain/      entities/     repositories/  usecases/
└── presentation/ bloc/        pages/  widgets/
```

## `shared/` rule

`shared/` is **not** a fifth layer and **not** a misc folder. Presentation-only reusable building blocks:
- `shared/widgets/` — app-wide reusable widgets
- `shared/mixins/` — UI lifecycle helpers
- Keep infrastructure in `core/`; keep repos/use cases/DTOs/networking **out** of `shared/`.

## Cross-cutting concerns (in `core/`, injected via GetIt)

Feature-scoped BLoCs are provided per-route via auto_route `WrappedRoute` → `09_NAVIGATION_DEEP_LINKING.md`.

| Concern | Interface | Default impl |
|---|---|---|
| HTTP | `HttpClient` | `DioHttpClient` |
| Local DB | `AppDatabase` (Drift) + DAOs | `BookDao`, `ReadingDao` |
| Secure store | `SecureStore` | `FlutterSecureStorageAdapter` |
| Analytics | `AnalyticsService` | `CompositeAnalyticsService` |
| Logging | `AppLogger` | `PrettyAppLogger` (dev), `ProductionAppLogger` (prod) |
| Connectivity | `ConnectivityService` (concrete, no abstract) | wraps `connectivity_plus` |
| Theme | `ThemeBloc` | palette + mode + font scale |
| Tokens | `TokenProvider` | `SecureTokenProvider` (wraps `SecureStore`) |

## Extensions

Use only where they remove real friction. Keep **read-only**, **thin**, **local to repeated pain points**. Never hide state mutation / navigation / analytics / package APIs behind an extension.

**Create for:**
1. Theme shortcuts on `BuildContext`: `colorScheme`, `textTheme`, `appColors`.
2. Domain methods on primitives: `String.toBookId()`, `DateTime.toReadableDate()`, `String.capitalize()`.
3. Collection helpers: `Iterable.separatedBy()`, `groupBy()`.

**Do NOT wrap** (already provided by packages):

| Don't wrap | Provided by |
|---|---|
| `context.pushRoute()`, `context.router` | auto_route |
| `context.read<T>()`, `watch<T>()`, `select<T,V>()` | flutter_bloc |

If an extension mutates state, navigates, dispatches analytics, or hides a package API — it's the wrong abstraction. Extensions live in `core/extensions/`, organized by extended type.
