# 03 - Dependency Manifest

## Purpose

This document describes the recommended dependency set for the target architecture. It does not claim that every package listed here is already present in `pubspec.yaml`.

Before adding anything, compare this document with:

- `pubspec.yaml`
- `docs/00B_PROJECT_STATUS_AND_ADOPTION.md`

## Dependency Strategy

- Add packages deliberately, not preemptively.
- Prefer Flutter SDK capabilities, adaptive widgets, and theming hooks before adding a package or native layer.
- Prefer stable packages with strong maintenance history and clear documentation.
- Use caret constraints for packages you actively adopt.
- Verify actual version choices against the current Flutter and Dart SDK before editing `pubspec.yaml`.
- Run `flutter pub outdated` before large dependency updates.

## Recommended Production Dependencies

| Area | Package | Why |
|------|---------|-----|
| State management | `flutter_bloc` | Predictable event/state flow for medium and large features |
| Event transformers | `bloc_concurrency` | `droppable()`, `restartable()`, `sequential()` for BLoC event control |
| Equality | `equatable` | Lightweight value equality for states and events |
| Navigation | `go_router` | Flutter team maintained; typed routes via `go_router_builder`, guards via `redirect`, shell routes, deep links |
| Responsive layout | `flutter_adaptive_scaffold` | Official Flutter adaptive layouts, auto-adaptive navigation, foldable device support |
| Networking | `dio` | Mature interceptor model and flexible request handling |
| Connectivity | `connectivity_plus` | Network-awareness signals for resilience features |
| Local database | `drift` | Type-safe local persistence with migrations and DAOs |
| SQLite support | `sqlite3_flutter_libs` | SQLite binaries for mobile targets when Drift is adopted |
| Paths | `path_provider`, `path` | Database and file-path management |
| Secure storage | `flutter_secure_storage` | Sensitive key-value storage |
| Simple preferences | `shared_preferences` | Non-sensitive local preferences |
| Dependency injection | `get_it` | Small, explicit DI for non-widget layers |
| Functional error handling | `fpdart` | Typed `Either` support for async/data layers |
| Localization | `intl` | Formatting and localization support |
| Logging | `logger` | Structured local logging during development |
| Images | `cached_network_image` | Disk-backed image loading for remote media |
| SVG | `flutter_svg` | Vector rendering for icons and illustrations |
| Grid layouts | **No package required** | Native `GridView.builder` + breakpoints in `AppDimensions` cover 99% of cases |

### Optional Production Dependencies

Add only when the product actually needs them:

| Area | Package | When To Add |
|------|---------|-------------|
| Crash reporting | `sentry_flutter` | Release monitoring and crash diagnostics |
| Product analytics | provider-specific SDKs | Once event tracking requirements are defined |
| Remote config / feature flags | provider-specific SDKs | Only when server-driven behavior is required |
| Variable-height grids | `flutter_staggered_grid_view` | Only if grid items have significantly different heights (Pinterest-style layouts); native `GridView` is preferred for uniform-height cards |

## Recommended Dev Dependencies

| Area | Package | Why |
|------|---------|-----|
| Analysis | `very_good_analysis` | Strong Flutter lint baseline |
| Code generation | `build_runner` | Required by adopted code generators |
| BLoC testing | `bloc_test` | State-sequence testing helpers |
| Mocking | `mocktail` | No-codegen mocks and easy interaction verification |
| Drift generation | `drift_dev` | Drift code generation support |
| Route generation | `go_router_builder` | Type-safe route codegen for go_router |
| Integration testing | `integration_test` | End-to-end and profiling flows |

## Packages To Avoid By Default

These are not universally bad; they are just not default choices for this architecture:

| Package / Pattern | Why It Is Not Default |
|------------------|-----------------------|
| `dartz` | Heavier functional layer when `fpdart` is enough |
| `auto_route` | Extra codegen and ceremony — `go_router` (Flutter-team maintained) is the current recommended choice |
| `mockito` | Code generation overhead when `mocktail` is sufficient |
| `google_fonts` | Runtime dependency that is often unnecessary when fonts can be bundled |
| extra navigation wrappers | Adds indirection on top of typed route APIs |

## Example `pubspec.yaml` Shape

Use your real package name and current verified versions.

```yaml
name: <app_package>
description: A Flutter application
publish_to: 'none'

environment:
  sdk: ^3.11.4

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_bloc: ^<verified_version>
  bloc_concurrency: ^<verified_version>
  equatable: ^<verified_version>
  go_router: ^<verified_version>
  flutter_adaptive_scaffold: ^<verified_version>
  dio: ^<verified_version>
  connectivity_plus: ^<verified_version>
  drift: ^<verified_version>
  sqlite3_flutter_libs: ^<verified_version>
  path_provider: ^<verified_version>
  path: ^<verified_version>
  flutter_secure_storage: ^<verified_version>
  shared_preferences: ^<verified_version>
  get_it: ^<verified_version>
  fpdart: ^<verified_version>
  intl: ^<verified_version>
  logger: ^<verified_version>
  cached_network_image: ^<verified_version>
  flutter_svg: ^<verified_version>

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^<verified_version>
  build_runner: ^<verified_version>
  bloc_test: ^<verified_version>
  mocktail: ^<verified_version>
  drift_dev: ^<verified_version>
  go_router_builder: ^<verified_version>
  integration_test:
    sdk: flutter
```

In this repository, `<app_package>` resolves to `tricount`.

## Adoption Checklist

Before adding a dependency:

1. Confirm the feature actually needs it.
2. Check whether Flutter SDK support or an existing package already covers the use case.
3. Verify the latest compatible version.
4. Add a short reason in the PR description or changelog.
5. Add tests or validation for the behavior the dependency enables.

After adding a dependency:

6. Add it to the table above with area and reason.
7. Add it to the example `pubspec.yaml` shape.
8. Update the relevant subsystem doc (e.g., new networking package -> Doc 06, new state package -> Doc 08).
9. If the package provides theme extensions, update `AppTheme.build()` and Doc 05.
