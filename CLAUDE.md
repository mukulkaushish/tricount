# CLAUDE.md

## Project Summary

This repository is a Flutter application workspace with a documented target architecture. The current codebase is still near starter-app state, so the docs should be read as a migration blueprint unless `docs/00B_PROJECT_STATUS_AND_ADOPTION.md` says a pattern is already in place.

## Docs-First Workflow (Mandatory Before Every Task)

Before writing any code or planning any implementation:

1. **Read memory** — Load `/memory/MEMORY.md` and the linked memory files to understand current project state, completed phases, and any prior feedback.
2. **Read the core docs** in this order:
   - `docs/00A_CODING_RULES.md` — linting, naming, style rules
   - `docs/00B_PROJECT_STATUS_AND_ADOPTION.md` — what is done vs. planned
   - `docs/01_ARCHITECTURE_OVERVIEW.md` — layer boundaries
   - `docs/02_PROJECT_STRUCTURE.md` — barrel files, file placement
   - `docs/03_DEPENDENCY_MANIFEST.md` — allowed packages
3. **Read subsystem docs** relevant to the task (e.g., `06_NETWORKING_LAYER.md` before touching network code, `20_SECURITY.md` before touching auth).
4. **Plan before coding** — enumerate every file that must change, in dependency order. Surface any doc contradictions or architecture boundary violations before touching code.
5. **Confirm scope** if the plan is large or cross-cutting.

This workflow prevents re-work caused by missing context and keeps implementations aligned with the documented architecture.

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

Common architecture naming — use **descriptive prefixes**, never `Impl`:

| Role | Naming pattern | Example |
|------|---------------|---------|
| Repository contract | `AccountRepository` | abstract interface |
| Repository implementation | `Remote<Name>Repository` | `RemoteAccountRepository` |
| Data source | `Dio<Name>DataSource` | `DioAuthDataSource` |
| Use case | `<Verb><Noun>UseCase` | `GetAccountsUseCase` |
| BLoC | `<Feature>Bloc` | `AccountsBloc` |
| DTO / model | `<Name>Model` | `AccountModel` |
| Entity | `<Name>` | `Account` |
| Screen / page | `<Name>Page` | `AccountsPage` |
| Logger | `<Qualifier>AppLogger` | `PrettyAppLogger`, `SilentAppLogger` |
| Secure store | `Platform<Name>` | `PlatformSecureStore` |

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
