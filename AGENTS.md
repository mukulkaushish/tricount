# AGENTS.md

## Project Summary

This repository is a Flutter application workspace with a documented target architecture. The current codebase is still near starter-app state, so the docs should be read as a migration blueprint unless `docs/00B_PROJECT_STATUS_AND_ADOPTION.md` says a pattern is already in place.

## Documentation Read Order

Read these documents before making structural changes:

1. `docs/00A_CODING_RULES.md`
2. `docs/00B_PROJECT_STATUS_AND_ADOPTION.md`
3. `docs/01_ARCHITECTURE_OVERVIEW.md`
4. `docs/02_PROJECT_STRUCTURE.md`
5. `docs/03_DEPENDENCY_MANIFEST.md`

The remaining docs cover specific subsystems and should be consulted when touching those areas.

## Delivery Workflow

- If the user asks for phased screen delivery, implement one screen at a time.
- After each screen, run the app and capture a screenshot for review.
- Wait for explicit approval before moving to the next screen.
- If the user asks for a standalone plan file without naming a folder, create it at the repository root.

## Non-Negotiable Architecture Rules

### Layer Boundaries

- `presentation` depends on `domain` and `core` only
- `domain` stays pure Dart and does not import Flutter
- `data` implements domain contracts and talks to external systems
- `core` contains shared infrastructure

### Dependency Direction

- Widgets talk to BLoCs or equivalent presentation state only
- BLoCs depend on use cases, never repositories directly
- Repositories depend on abstractions such as `HttpClient`, not framework clients directly
- Infrastructure implementations such as `DioHttpClient` should stay referenced from DI, not business code
- Analytics belongs in state/business logic, not widgets
- Use Drift `AppDatabase` and DAOs directly rather than wrapping them in extra abstraction layers unless the repo already has a justified pattern

### Networking

- Standardize on `HttpClient.request<T>()`, `requestList<T>()`, and `requestEmpty()`
- Use a `RequestMethod` enum instead of scattered verb-specific APIs
- Return `Either<AppException, T>`
- Keep auth refresh logic in Dio interceptors or the existing network layer

### Error Handling

- Use `AppException` as the primary typed error model
- Avoid parallel `Failure` or `ErrorMapper` hierarchies unless they already exist for a specific boundary
- Let repositories pass structured errors upward instead of converting them to generic strings
- UI should render user-facing messages from the exception model or mapped presentation state

## Coding Standards

### Imports and File Structure

- Keep `dart:` imports for SDK libraries
- Use `package:<app_package>/...` imports for project files
- Cross-feature and cross-module project imports should go through barrel files
- Barrel files should contain `export` statements only

Example:

```dart
import 'package:<app_package>/core/core.dart';
import 'package:<app_package>/features/home/home.dart';
```

In this repository, `<app_package>` resolves to `tricount`.

### Dart / Flutter Style

- All parameters and local variables are `final`
- Use `const` wherever possible
- Prefer single quotes
- Avoid inline themes and hardcoded colors
- Avoid magic numbers; use shared dimensions/constants
- Use `AppLogger` instead of `print()`
- Keep switches on enums and sealed types exhaustive
- Keep widget trees shallow enough to stay readable

### Navigation

- Use `auto_route` APIs directly when the app has adopted `auto_route`
- Avoid custom wrappers around `context.router`, `pushRoute`, or `maybePop` unless there is a proven need

## Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables and functions: `camelCase`
- Barrel files: `<folder_name>.dart`

Common architecture naming:

- Repository contract: `AccountRepository`
- Repository implementation: `AccountRepositoryImpl`
- Use case: `GetAccountsUseCase`
- BLoC: `AccountsBloc`
- DTO/model: `AccountModel`
- Entity: `Account`
- Screen/page: `AccountsPage`

## Documentation Maintenance

When adding a new dependency to `pubspec.yaml`:

1. Add it to `docs/03_DEPENDENCY_MANIFEST.md` with the reason
2. If it introduces a new pattern (state, navigation, storage), update the relevant subsystem doc
3. If it has a theme extension or sub-theme, add entries to `AppTheme.build()` and `docs/05_THEMING_SYSTEM.md`
4. If it replaces an existing package, update all docs that reference the old one

When adding a new widget type to the app, follow the maintenance rule in `docs/05_THEMING_SYSTEM.md`.

## Recommended Commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## State Management Guidelines

- Use `flutter_bloc` for app-wide state management patterns
- Prefer BLoC for event-driven or multi-step flows
- Prefer Cubit for smaller, direct state transitions when that keeps the feature simpler
- Keep state objects immutable
- Favor a predictable lifecycle such as `Initial`, `Loading`, `Loaded`, and `Error`