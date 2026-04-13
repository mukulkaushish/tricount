# AGENTS.md

## Read First

Before writing code in this project, read these files in order:

1. `docs/00A_CODING_RULES.md`
2. `docs/00B_PROJECT_STATUS_AND_ADOPTION.md`
3. `CLAUDE.md`

These documents define the repo's current state, target architecture, linting rules, and delivery expectations.

## Important Context

- Many docs in `docs/` describe the target architecture, not code that already exists.
- Examples use `package:<app_package>/...`; in this repository, `<app_package>` resolves to `tricount`.
- Prefer incremental adoption over architecture-only rewrites.

## Delivery Workflow

- If the user asks for screen-by-screen delivery, implement one screen only.
- After finishing that screen, run the app, capture a screenshot, and present it.
- Wait for explicit approval before moving to the next screen.
- If the user asks for a plan file without a location, create it at the repository root.

## Flutter / Dart Rules

Use this checklist before editing or creating Dart files:

- File belongs to the correct layer: `presentation`, `domain`, `data`, or `core`
- Cross-module imports go through barrel files
- No relative imports like `../`
- Package imports use the current app package name
- All parameters are `final`
- All local variables are `final`
- `const` constructors are used where possible
- UI styling comes from theme/context extensions, not inline values
- Spacing, radius, and sizing come from shared dimensions/constants
- Logging uses `AppLogger`, never `print()`
- Switches over sealed types are exhaustive and avoid `default`

Import examples:

```dart
import 'package:<app_package>/core/core.dart';
import 'package:<app_package>/features/auth/auth.dart';
```

## New File Workflow

When adding a file:

1. Pick the correct feature and layer.
2. Place it according to `docs/02_PROJECT_STRUCTURE.md`.
3. Export it from the appropriate barrel file.
4. Use package imports only.

## New Feature Workflow

When adding a feature module:

1. Create `data/`, `domain/`, and `presentation/`.
2. Add barrel files at each public folder level.
3. Keep the feature barrel limited to the public API, typically `domain` and `presentation`.
4. Register dependencies in `core/di/feature_module.dart` when that module exists.
5. Add routing in `router/app_router.dart` when the app has adopted that router structure.

## BLoC Rules

When creating a BLoC:

1. Create `*_bloc.dart`, `*_event.dart`, and `*_state.dart`.
2. Let the bloc file export the event and state files when that pattern is used in the repo.
3. Keep states immutable and `Equatable`.
4. Prefer the standard lifecycle states: `Initial`, `Loading`, `Loaded`, `Error`.
5. Use descriptive past-tense event names.
6. Depend on use cases, not repositories.
7. Register BLoCs with `registerFactory`, not singleton registration.

## Model / DTO Rules

When creating a DTO or model:

1. Place it in `feature/data/models/`.
2. Implement `JsonCodable` where that contract is used.
3. Use `JsonParser` helpers in `fromJson`.
4. Use `JsonParser.toJson()` for serialization and null stripping.
5. Export it from the models barrel file.

## Repository Rules

When creating a repository:

1. Put the abstract contract in `feature/domain/repositories/`.
2. Put the implementation in `feature/data/repositories/`.
3. Go through `HttpClient`, not Dio directly.
4. Return `Either<AppException, T>`.
5. Avoid extra error-mapping layers unless a boundary genuinely needs a specific exception wrapper.
6. Register implementations with `registerLazySingleton`.

## Networking Patterns

```dart
httpClient.request<ItemModel>(
  '/v1/items/$id',
  method: RequestMethod.get,
  fromJson: ItemModel.fromJson,
  keyPath: 'data',
);

httpClient.requestList<ItemModel>(
  '/v1/items',
  method: RequestMethod.get,
  fromJson: ItemModel.fromJson,
  keyPath: 'data',
  queryParameters: {'page': page},
);

httpClient.requestEmpty(
  '/v1/items/$id',
  method: RequestMethod.delete,
);
```

## Testing Rules

- Use `mocktail` for mocking
- Mock at architectural boundaries
- Use `bloc_test` for BLoC tests
- Cover `Initial`, `Loading`, `Loaded`, and `Error` states
- Keep JSON fixtures in `test/fixtures/`

## Review Checklist

### Blockers

- Layer boundary violations
- Dio used outside `DioHttpClient`
- Missing barrel exports for new public files
- Relative imports across modules
- Inline themes or hardcoded colors
- `print()` statements
- Non-final parameters or locals
- Non-exhaustive sealed-class switches
- Custom navigation wrappers where built-in `auto_route` APIs should be used
- BLoCs depending on repositories instead of use cases
- `Failure` / `ErrorMapper` patterns where `AppException` should be used directly

### Change Requests

- Missing `const` where possible
- Deep widget nesting in a single `build()`
- Magic numbers instead of shared dimensions
- Analytics fired from widgets instead of state logic
- Missing tests for new BLoCs, use cases, or repositories

### Suggestions

- Prefer tear-offs where they improve readability
- Combine obvious cascades
- Extract overly long files into smaller focused units
