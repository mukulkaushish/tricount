# 01 - Architecture Overview

## Guiding Philosophy

This application follows **Clean Architecture** with **feature-first organization**. Every decision prioritizes:

1. **Testability** - every layer can be tested in isolation
2. **Modularity** - features are self-contained; removing one never breaks another
3. **Decoupling** - layers communicate through interfaces, never concrete implementations
4. **Zero boilerplate** - extensions, mixins, and code generation eliminate repetition

---

## SOLID Principles Applied

### Single Responsibility (S)
- Each class has exactly one reason to change
- BLoCs handle state logic only; they never call APIs directly
- Repositories are the sole owners of data access
- Use cases encapsulate one business operation

### Open/Closed (O)
- The theming system is open for new color palettes (add a new `AppColorPalette`) but closed for modification (the `ThemeBuilder` contract never changes)
- Interceptors are stackable - add new ones without modifying `DioHttpClient`
- Analytics adapters plug in without changing the `AnalyticsService` interface

### Liskov Substitution (L)
- Any `AnalyticsService` implementation (Sentry, Mixpanel, Firebase, NoOp) is interchangeable
- Any `BookRepository` (remote, local, cached) satisfies the same contract
- Mock implementations used in tests honor the same invariants

### Interface Segregation (I)
- `AnalyticsService` is split: `EventTracker`, `CrashReporter`, `UserIdentifier`
- `AuthService` is split: `TokenProvider`, `SessionManager`, `AuthStateNotifier`
- Consumers depend only on the slice they need

### Dependency Inversion (D)
- Domain layer defines interfaces; data layer implements them
- Presentation depends on domain, never on data
- `GetIt` registers concrete implementations against abstract types
- No widget ever imports from `data/` directly

---

## Design Patterns

### Repository Pattern
- **Purpose**: Abstract data sources behind a unified interface
- **Where**: Every feature's `domain/repositories/` defines the contract; `data/repositories/` implements it
- **Rule**: Repositories return domain models, never DTOs or raw JSON

### BLoC Pattern (Business Logic Component)
- **Purpose**: Separate presentation from business logic via streams of events and states
- **Where**: `presentation/bloc/` within each feature
- **Rule**: BLoCs receive events, call use cases, emit states. No UI logic in BLoCs; no business logic in widgets.

### Use Case Pattern
- **Purpose**: Encapsulate a single business operation
- **Where**: `domain/usecases/` within each feature
- **Rule**: One public `call()` method. Use cases may compose other use cases but never call repositories from other features directly.

### Adapter Pattern
- **Purpose**: Wrap third-party libraries behind app-owned interfaces
- **Where**: Analytics adapters, storage adapters, `DioHttpClient` implementing `HttpClient`
- **Rule**: If a package appears in an `import`, it should be behind an interface or adapter in `core/`

### Observer Pattern
- **Purpose**: Connectivity changes, auth state changes, theme changes
- **Where**: Streams exposed by core services, consumed by BLoCs or global listeners

### Strategy Pattern
- **Purpose**: Interchangeable algorithms for caching, retry policies, theme generation
- **Where**: `core/network/strategies/`, `core/theme/`

### Factory Pattern
- **Purpose**: Create complex objects (interceptors, theme data, database instances)
- **Where**: `core/di/`, `core/theme/theme_factory.dart`

---

## Layer Architecture

```
┌─────────────────────────────────────────┐
│            PRESENTATION                  │
│  Widgets, Pages, BLoCs, Routes           │
│  Depends on: Domain                      │
├─────────────────────────────────────────┤
│              DOMAIN                      │
│  Entities, Use Cases, Repository         │
│  Interfaces, Value Objects               │
│  Depends on: Nothing (pure Dart)         │
├─────────────────────────────────────────┤
│               DATA                       │
│  Repository Impls, DTOs, Data Sources,   │
│  API Services, Local DB (Drift)          │
│  Depends on: Domain (implements its      │
│  interfaces)                             │
├─────────────────────────────────────────┤
│               CORE                       │
│  Network, Theme, DI, Extensions,         │
│  Error Handling, Analytics, Logging,     │
│  JSON Parsing, Secure Storage            │
│  Shared across all features              │
└─────────────────────────────────────────┘
```

### Dependency Rules (Strict)

| Layer | Can Import | Cannot Import |
|-------|-----------|---------------|
| Presentation | Domain, Core | Data |
| Domain | Core (only error types & extensions) | Presentation, Data |
| Data | Domain, Core | Presentation |
| Core | Dart/Flutter SDK, pub packages | Domain, Data, Presentation |

---

## Feature Module Structure

Every feature follows this internal structure:

```
feature_name/
├── data/
│   ├── datasources/        # Remote and local data sources
│   ├── models/             # DTOs that implement JsonCodable
│   └── repositories/       # Concrete repository implementations
├── domain/
│   ├── entities/           # Pure domain objects
│   ├── repositories/       # Abstract repository interfaces
│   └── usecases/           # Single-purpose business operations
└── presentation/
    ├── bloc/               # BLoC/Cubit + Events + States
    ├── pages/              # Full-screen page widgets
    └── widgets/            # Feature-specific widgets
```

---

## Cross-Cutting Concerns

These live in `core/` and are injected via GetIt:

| Concern | Interface | Default Implementation |
|---------|-----------|----------------------|
| HTTP Client | `HttpClient` | `DioHttpClient` |
| Local DB | `AppDatabase` (Drift) + DAOs | `BookDao`, `ReadingDao` |
| Secure Storage | `SecureStore` | `FlutterSecureStorageAdapter` |
| Analytics | `AnalyticsService` | `CompositeAnalyticsService` |
| Logging | `AppLogger` | `PrettyLoggerImpl` |
| Connectivity | `ConnectivityService` | `ConnectivityPlusAdapter` |
| Theme | `ThemeManager` | `BlocThemeManager` |
| Token Management | `TokenProvider` | `SecureTokenProvider` |

---

## Extension Strategy

Extensions are used **only** when they add real value. Do not wrap APIs that packages already provide.

### What We Create Extensions For

1. **Theme shortcuts** on BuildContext: `context.colorScheme`, `context.textTheme`, `context.appColors` (saves nested access)
2. **Domain methods** on primitives: `String.toBookId()`, `DateTime.toReadableDate()`, `String.capitalize()`
3. **Collection utilities**: `Iterable.separatedBy()`, `Iterable.groupBy()`

### What We Do NOT Create Extensions For

| Don't Wrap | Already Provided By |
|-----------|-------------------|
| `context.pushRoute()` | auto_route (built-in) |
| `context.router` | auto_route (built-in) |
| `context.read<T>()` / `context.watch<T>()` | flutter_bloc (built-in) |
| `context.select<T, V>()` | flutter_bloc (built-in) |

**Rule**: If a package already provides a context extension, use it directly. Don't wrap it.

Extensions live in `core/extensions/` and are organized by the type they extend.
