# CLAUDE.md - Project Instructions for Claude Code

## Project Overview

Flutter reading application following Clean Architecture with feature-first organization. Built with flutter_bloc, auto_route, Dio, Drift, and fpdart.

## Documentation

Full template documentation lives in `docs/`. Read order:
1. `docs/00A_CODING_RULES.md` - Lint rules, coding standards, barrel file convention
2. `docs/01_ARCHITECTURE_OVERVIEW.md` - SOLID, patterns, layer rules
3. `docs/02_PROJECT_STRUCTURE.md` - Complete file tree with barrel files
4. `docs/03_DEPENDENCY_MANIFEST.md` - All packages with justifications
5. Remaining docs (04-20) cover specific subsystems

## Delivery Workflow

- If the user requests phased screen delivery, implement one screen at a time.
- After each screen is implemented, run the app and capture a screenshot for
  review.
- Wait for explicit approval before implementing the next screen.
- When the user requests a standalone project plan file and does not specify a
  folder, place it at the repository root.

## Key Architectural Rules

### Layers (strict boundaries)
- **Presentation** (widgets, pages, BLoCs) → depends on Domain + Core only
- **Domain** (entities, use cases, repository interfaces) → pure Dart, no Flutter imports
- **Data** (repository impls, DTOs, data sources) → implements Domain interfaces
- **Core** (network, theme, DI, extensions, error) → shared infrastructure

### Decoupling
- Repositories depend on `HttpClient` interface, never Dio directly
- BLoCs depend on Use Cases, never Repositories
- Widgets depend on BLoC states, never call repositories
- Analytics fired from BLoCs, never widgets
- `DioHttpClient` implements `HttpClient` - only referenced in DI registration
- No abstract `LocalDatabase` interface — use Drift `AppDatabase` + DAOs directly
- No abstract `ConnectivityService` interface — one concrete class wrapping connectivity_plus

### Networking
- `HttpClient` (abstract) with 3 methods: `request<T>`, `requestList<T>`, `requestEmpty`
- `DioHttpClient` (implementation) - handles HTML detection, keyPath extraction, error mapping
- All methods return `Either<AppException, T>` via fpdart
- `RequestMethod` enum instead of per-verb methods
- `AuthInterceptor` extends `QueuedInterceptorsWrapper` (Dio built-in) for safe token refresh
- HTTP logging via Dio's built-in `LogInterceptor` (no custom logging interceptor)

### Error Handling
- Single `sealed class AppException` — used directly as `Either` Left type
- No `Failure` class, no `ErrorMapper` — repositories pass `Either` through unchanged
- `AppException.fromDioError()` factory maps Dio errors to typed exceptions
- BLoCs fold `Either` → emit `Loaded` or `Error(exception: AppException)`
- UI uses `exception.userMessage` for display, sealed type for icon/action

### JSON Parsing
- `JsonParser` mixin for type-safe field extraction
- `JsonCodable` interface for all DTOs
- `DataMismatchException` for parse failures with field names

## Coding Standards

### Linting
- Uses `very_good_analysis: ^10.2.0` (strictest Flutter lint set)
- Zero warnings policy - `flutter analyze` must pass clean
- Generated files excluded: `*.g.dart`, `*.gr.dart`, `*.freezed.dart`

### Barrel Files
- Every folder with 2+ public files has a barrel (`<folder_name>.dart`)
- Cross-module imports always go through barrels
- `core/core.dart` is the top-level barrel for all core infrastructure
- Feature barrels export domain + presentation only (data is internal)
- Barrel files contain ONLY `export` statements

### Navigation
- `auto_route` handles all navigation — no custom navigation extensions
- Use built-in: `context.router`, `context.pushRoute()`, `context.maybePop()`
- `AutoTabsScaffold` for tab navigation, `AutoRouteGuard` with `redirectUntil` for auth
- `DeepLinkBuilder` for deep link validation
- `AutoRouteObserver` for screen tracking / analytics

### Style
- `final` for all parameters and local variables
- `const` constructors wherever possible
- Single quotes for strings
- Package imports only (`package:reading_app/...`), no relative `../`
- Trailing commas on multi-line arguments
- No inline themes - use `context.colorScheme`, `context.textTheme`, `context.appColors` (only 3 extensions)
- No magic numbers - use `AppDimensions`
- No `print()` - use `AppLogger`
- Exhaustive switches on sealed classes/enums (no `default`)
- Max 3 levels of widget nesting per `build()` method
- Do NOT wrap `context.read<T>()` / `context.watch<T>()` — flutter_bloc provides them

### File Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `camelCase` (not SCREAMING_CASE)
- Barrel files: `<folder_name>.dart`

### Architecture Naming
- Abstract repository: `LibraryRepository`
- Implementation: `LibraryRepositoryImpl`
- Use case: `GetBooksUseCase`
- BLoC: `LibraryBloc`
- DTO: `BookModel`
- Entity: `Book`
- Page: `LibraryPage`

## Dependencies (Minimal)

Core: `flutter_bloc`, `auto_route`, `dio`, `fpdart`, `drift`, `get_it`, `flutter_secure_storage`, `connectivity_plus`, `logger`, `cached_network_image`, `flutter_svg`

Testing: `very_good_analysis`, `bloc_test`, `mocktail`, `drift_dev`, `auto_route_generator`, `build_runner`

No `dartz` (use fpdart), no `injectable` (manual GetIt), no `mockito` (use mocktail), no `shimmer` (custom widget), no `google_fonts` (bundled fonts).

## Commands

```bash
# Code generation
dart run build_runner build --delete-conflicting-outputs

# Full CI check
dart format . && flutter analyze && flutter test

# Tests with coverage
flutter test --coverage
```

## State Management Pattern

- `flutter_bloc` for all state management
- BLoC for complex features (auth, library, reader) - event-driven
- Cubit for simple features (settings) - direct methods
- States: `Initial`, `Loading`, `Loaded`, `Error` - always exhaustive
- Events extend `Equatable`, use past-tense naming
- Error states carry the original event for retry
