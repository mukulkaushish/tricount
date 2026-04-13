# 03 - Dependency Manifest

## Guiding Principle: Fewer Packages = Smaller App

Every dependency adds binary size, maintenance burden, and potential breakage. Before adding a package, ask: "Can I do this in < 50 lines of Dart?" If yes, skip the package.

---

## Production Dependencies

### Core Framework
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Framework |
| `flutter_localizations` | SDK | Internationalization support |

### State Management
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^9.0.0 | BLoC/Cubit state management |
| `equatable` | ^2.0.7 | Value equality for events/states without boilerplate |

### Navigation
| Package | Version | Purpose |
|---------|---------|---------|
| `auto_route` | ^9.0.0 | Declarative routing with deep linking |

### Networking
| Package | Version | Purpose |
|---------|---------|---------|
| `dio` | ^5.7.0 | HTTP client with interceptor support |
| `connectivity_plus` | ^6.1.0 | Network connectivity detection |

### Local Storage
| Package | Version | Purpose |
|---------|---------|---------|
| `drift` | ^2.22.0 | Type-safe SQLite ORM |
| `sqlite3_flutter_libs` | ^0.5.0 | SQLite binaries for mobile |
| `path_provider` | ^2.1.0 | File system paths for DB location |
| `path` | ^1.9.0 | Path manipulation utilities |
| `flutter_secure_storage` | ^9.2.0 | Encrypted key-value storage (tokens, secrets) |
| `shared_preferences` | ^2.3.0 | Simple key-value prefs (non-sensitive settings) |

### Dependency Injection
| Package | Version | Purpose |
|---------|---------|---------|
| `get_it` | ^8.0.0 | Service locator for DI |

### Functional Programming
| Package | Version | Purpose |
|---------|---------|---------|
| `fpdart` | ^1.1.0 | `Either` type for typed error handling (lighter than dartz, actively maintained) |

### Localization
| Package | Version | Purpose |
|---------|---------|---------|
| `intl` | any | Date/number/currency formatting for l10n (version managed by Flutter SDK) |

### Logging
| Package | Version | Purpose |
|---------|---------|---------|
| `logger` | ^2.5.0 | Pretty console logging |

### UI
| Package | Version | Purpose |
|---------|---------|---------|
| `cached_network_image` | ^3.4.0 | Image loading with disk cache |
| `flutter_svg` | ^2.0.0 | SVG rendering for icons/illustrations |

### Analytics (all optional - behind interface, enable as needed)
| Package | Version | Purpose |
|---------|---------|---------|
| `sentry_flutter` | ^8.12.0 | Crash reporting & performance monitoring |

---

## Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Widget & unit test framework |
| `very_good_analysis` | ^10.2.0 | Strictest Flutter lint set (replaces flutter_lints) |
| `build_runner` | ^2.4.0 | Code generation orchestrator |
| `bloc_test` | ^9.1.0 | BLoC-specific testing utilities |
| `mocktail` | ^1.0.0 | Mocking without code generation |
| `drift_dev` | ^2.22.0 | Drift code generation |
| `auto_route_generator` | ^9.0.0 | Route code generation |
| `integration_test` | SDK | End-to-end testing on device |

---

## pubspec.yaml Skeleton

```yaml
name: reading_app
description: A world-class reading application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.4

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.0.0
  equatable: ^2.0.7

  # Navigation
  auto_route: ^9.0.0

  # Networking
  dio: ^5.7.0
  connectivity_plus: ^6.1.0

  # Local Storage
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  flutter_secure_storage: ^9.2.0
  shared_preferences: ^2.3.0

  # DI
  get_it: ^8.0.0

  # Functional
  fpdart: ^1.1.0

  # Localization
  intl: any

  # Logging
  logger: ^2.5.0

  # UI
  cached_network_image: ^3.4.0
  flutter_svg: ^2.0.0

  # Analytics (enable as needed)
  # sentry_flutter: ^8.12.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^10.2.0
  build_runner: ^2.4.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  drift_dev: ^2.22.0
  auto_route_generator: ^9.0.0
  integration_test:
    sdk: flutter

flutter:
  generate: true  # Required for l10n code generation (gen-l10n)
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
  fonts:
    - family: Montserrat
      fonts:
        - asset: assets/fonts/Montserrat-Regular.ttf
        - asset: assets/fonts/Montserrat-Medium.ttf
          weight: 500
        - asset: assets/fonts/Montserrat-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Montserrat-Bold.ttf
          weight: 700
```

---

## What Was Removed & Why

| Removed Package | Reason |
|----------------|--------|
| `dartz` | Replaced by `fpdart` - smaller, actively maintained, better Dart 3 support |
| `injectable` + `injectable_generator` | Over-engineering for manual GetIt. Writing `sl.registerLazySingleton(...)` directly is 1 line per service. Annotation-based DI adds code gen overhead for zero gain at this scale. |
| `mockito` | Replaced by `mocktail` - no code generation needed, same API, faster test iteration |
| `shimmer` | A shimmer effect is ~30 lines of custom `AnimationController` + `ShaderMask`. No package needed. |
| `google_fonts` | Bundle fonts in `assets/fonts/` instead. Eliminates runtime HTTP fetch, works offline, zero latency on first render, and reduces app startup time. |
| `mixpanel_flutter` | Not needed at launch. Add when product analytics is actually integrated. |
| `firebase_analytics` | Not needed at launch. Add when Firebase is actually integrated. |
| `custom_lint` | Not needed. `very_good_analysis` is strict enough. |
| `bloc` (explicit pin) | Transitive via `flutter_bloc`. No need to pin separately. |

---

## Dependency Count Comparison

| | Before | After |
|---|--------|-------|
| Production deps | 22 | 15 |
| Dev deps | 10 | 7 |
| Code generators | 3 (`auto_route`, `drift`, `injectable`) | 2 (`auto_route`, `drift`) |
| **Total** | **32** | **22** |

---

## Dependency Justification Matrix

| Requirement | Chosen Package | Alternatives Considered | Why This One |
|-------------|---------------|------------------------|--------------|
| HTTP Client | Dio | http, chopper | Interceptor chain, cancel tokens, multipart, mature |
| State Mgmt | flutter_bloc | Riverpod, Provider, GetX | Event-driven, testable, large community, scales well |
| Routing | auto_route | go_router, Navigator 2.0 | Deep linking, guards, code gen, nested nav |
| Local DB | Drift | sqflite, Hive, Isar | Type-safe, reactive, migrations, DAO pattern |
| DI | GetIt (manual) | Injectable, Riverpod, Provider | Framework-agnostic, works in non-widget code, zero code gen |
| Secure Storage | flutter_secure_storage | - | iOS Keychain + Android EncryptedSharedPrefs |
| Error Handling | fpdart (Either) | dartz, Result type, exceptions only | Lighter, maintained, Dart 3 native, functional composition |
| Logging | logger | logging, print | Pretty formatting, log levels, zero config |
| Mocking | mocktail | mockito | No code gen, same power, faster iteration |
| Shimmer | Custom widget | shimmer package | 30 lines vs. a dependency |
| Fonts | Bundled assets | google_fonts | Offline, no latency, smaller runtime footprint |

---

## Version Pinning Policy

- **Major version**: Pin with caret (`^9.0.0`) - allows minor/patch updates
- **Generated code packages**: Pin generator and runtime to same major version
- **Flutter SDK**: Pin to minimum supported version
- **Run `flutter pub outdated` monthly** to check for security patches
- **Never use `any` version constraint** in production

---

## Adding a New Dependency Checklist

Before adding any package, verify:

1. Can this be done in < 50 lines without a package?
2. Is the package actively maintained? (last publish < 6 months)
3. pub.dev score > 120?
4. Does it add native dependencies? (increases build complexity)
5. What's the transitive dependency count? (`flutter pub deps --style=compact`)
6. Is there a lighter alternative?

If answers to 1 or 6 are "yes", skip the package.
