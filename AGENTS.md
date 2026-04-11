# AGENTS.md - Agent-Specific Instructions

## For All Agents

Before writing any code in this project, you MUST read and follow:
1. `docs/00A_CODING_RULES.md` - Lint rules, barrel files, style rules
2. `CLAUDE.md` - Architecture summary and key rules

## Delivery Workflow

- When the user requests screen-by-screen delivery, implement exactly one
  screen at a time.
- After finishing a screen, run the app, capture a screenshot, and present it
  before moving to the next screen.
- Do not implement the next screen until the user explicitly approves the
  current screen.
- If a plan file is requested without a location, prefer creating it at the
  repository root instead of inside `/`.

## Flutter Code Agent

When generating or modifying Flutter/Dart code:

### Mandatory Checks Before Writing Code
- [ ] File is in the correct layer (presentation/domain/data/core)
- [ ] Imports go through barrel files for cross-module access
- [ ] No relative imports (`../`) - use `package:reading_app/...`
- [ ] All parameters are `final`
- [ ] All local variables are `final`
- [ ] `const` constructors used where possible
- [ ] No inline themes - use `context.colorScheme`, `context.textTheme`
- [ ] No magic numbers - use `AppDimensions`
- [ ] No `print()` - use `AppLogger`
- [ ] Switches on sealed classes are exhaustive (no `default`)

### When Creating a New File
1. Determine which layer and feature it belongs to
2. Place it in the correct folder per `docs/02_PROJECT_STRUCTURE.md`
3. Add it to the appropriate barrel file
4. Use package imports only

### When Creating a New Feature Module
1. Create the full folder structure: `data/`, `domain/`, `presentation/` with sub-folders
2. Create barrel files at every level
3. Feature barrel (`feature_name.dart`) exports domain + presentation only
4. Register dependencies in `core/di/feature_module.dart`
5. Add route in `router/app_router.dart`

### When Creating a BLoC
1. Three files: `*_bloc.dart`, `*_event.dart`, `*_state.dart`
2. BLoC file also acts as barrel (exports event and state)
3. States extend `Equatable` with four variants: Initial, Loading, Loaded, Error
4. Events extend `Equatable` with descriptive past-tense names
5. BLoC depends on Use Cases only (never repositories)
6. Register as `registerFactory` in GetIt (not singleton)

### When Creating a Model/DTO
1. Place in `feature/data/models/`
2. Implement `JsonCodable`
3. Use `JsonParser` methods in `fromJson` - never raw `json['key']`
4. Use `JsonParser.toJson()` in `toJson()` for null stripping
5. Add to the models barrel file

### When Creating a Repository
1. Abstract interface in `feature/domain/repositories/`
2. Implementation in `feature/data/repositories/`
3. Implementation calls `HttpClient` methods with `RequestMethod` enum
4. No try-catch needed — `Either` from `HttpClient` handles errors (only exception: Drift `CacheException` wrapping)
5. Returns `Either<AppException, T>` — no `Failure` class, no error mapping
6. Register as `registerLazySingleton<AbstractRepo>(() => ImplRepo(...))` in GetIt

### Networking Calls
```dart
// Single object - use request<T>:
httpClient.request<BookModel>(
  '/v1/books/$id',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  keyPath: 'data',
)

// List - use requestList<T>:
httpClient.requestList<BookModel>(
  '/v1/books',
  method: RequestMethod.get,
  fromJson: BookModel.fromJson,
  keyPath: 'data',
  queryParameters: {'page': page},
)

// No response body - use requestEmpty:
httpClient.requestEmpty(
  '/v1/user/bookmarks/$id',
  method: RequestMethod.delete,
)
```

### Testing
- Use `mocktail` for mocking (no code generation)
- Mock at the boundary: Use Cases for BLoC tests, Repositories for Use Case tests, HttpClient for Repository tests
- Use `bloc_test` package for BLoC testing
- Test all four state variants: Initial, Loading, Loaded, Error
- JSON fixtures go in `test/fixtures/`

## Code Review Agent

When reviewing code in this project, check for:

### Critical (Block PR)
- Layer boundary violations (presentation importing data, domain importing Flutter)
- Direct Dio usage outside `DioHttpClient`
- Inline themes or hardcoded colors
- Missing barrel file exports for new files
- Relative imports across modules
- `print()` statements
- Non-exhaustive switches on sealed types
- Non-final parameters or local variables
- Custom navigation extensions (use auto_route's built-in API)
- Wrapping `context.read/watch/select` (flutter_bloc provides them)
- Using `Failure` class or `ErrorMapper` (use `AppException` directly)
- Abstract `LocalDatabase` interface wrapping Drift (use DAOs directly)

### Warning (Request Change)
- Missing `const` on constructors that could be const
- Widget nesting deeper than 3 levels in one `build()`
- BLoC directly calling a repository (should use Use Case)
- Analytics fired from a widget (should be in BLoC)
- Magic numbers not in `AppDimensions`
- Missing tests for new BLoC/UseCase/Repository

### Info (Suggest)
- Opportunities to use tear-offs instead of lambdas
- Cascade invocations that could be combined
- Files that could be extracted to reduce file length
