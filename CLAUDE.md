# CLAUDE.md

## Project Summary

Tricount is a Flutter application with a layered, feature-first architecture.

## Documentation Read Order

Read these documents before making structural changes:

1. [**docs/01_DEVELOPMENT.md**](docs/01_DEVELOPMENT.md) — Coding rules, status, and folder structure.
2. [**docs/02_ARCHITECTURE.md**](docs/02_ARCHITECTURE.md) — Design principles, BLoC, and DI.
3. [**docs/03_DATA_LAYER.md**](docs/03_DATA_LAYER.md) — Networking, Storage, and Security.
4. [**docs/04_UI_UX.md**](docs/04_UI_UX.md) — Theming, Navigation, and Components.
5. [**docs/05_OPS_QUALITY.md**](docs/05_OPS_QUALITY.md) — Testing, CI/CD, and Analytics.

## Non-Negotiable Architecture Rules

### Layer Boundaries
- `presentation` depends on `domain` and `core` only.
- `domain` stays pure Dart (no Flutter imports).
- `data` implements domain contracts and talks to external systems.
- `core` contains shared infrastructure.

### Dependency Direction
- BLoCs depend on use cases, never repositories directly.
- Repositories depend on `HttpClient` (interface), not `Dio` (implementation).
- Use `AppDatabase` and DAOs directly (Drift already provides reactive streams).

### Networking & Errors
- Use `HttpClient.request<T>()`, `requestList<T>()`, and `requestEmpty()`.
- Return `Either<AppException, T>` using `fpdart`.
- Use `AppException` as the single typed error model.

## Coding Standards

### Imports & Barrels
- Use `package:tricount/...` imports.
- Cross-module imports **must** go through barrel files.
- Barrel files contain `export` statements only.

### Style
- All variables and parameters are `final`.
- Use `const` wherever possible.
- **Zero Inline Styles**: All styling must live in `AppTheme.build`.
- **Grids over Lists**: Use `GridView.builder` for content browsing.

## Recommended Commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```
