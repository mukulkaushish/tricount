# 03 - Dependency Manifest

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
| `bloc` | ^9.0.0 | BLoC core (transitive, but pin for stability) |
| `equatable` | ^2.0.7 | Value equality for events/states without boilerplate |

### Navigation
| Package | Version | Purpose |
|---------|---------|---------|
| `auto_route` | ^9.0.0 | Declarative routing with deep linking |
| `auto_route_generator` | ^9.0.0 | (dev_dependency) Code generation for routes |

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
| `injectable` | ^2.5.0 | Annotation-based DI registration |
| `injectable_generator` | ^2.7.0 | (dev_dependency) Code gen for GetIt |

### Logging
| Package | Version | Purpose |
|---------|---------|---------|
| `logger` | ^2.5.0 | Pretty console logging |

### UI & Theming
| Package | Version | Purpose |
|---------|---------|---------|
| `cached_network_image` | ^3.4.0 | Image loading with disk cache |
| `shimmer` | ^3.0.0 | Skeleton loading effect |
| `flutter_svg` | ^2.0.0 | SVG rendering for icons/illustrations |
| `google_fonts` | ^6.2.0 | Dynamic font loading from Google Fonts |

### Functional Programming
| Package | Version | Purpose |
|---------|---------|---------|
| `dartz` | ^0.10.1 | Either, Option types for error handling |

### Analytics (all optional - behind interface)
| Package | Version | Purpose |
|---------|---------|---------|
| `sentry_flutter` | ^8.12.0 | Crash reporting & performance monitoring |
| `mixpanel_flutter` | ^2.3.0 | Product analytics (future integration) |
| `firebase_analytics` | ^11.3.0 | Event tracking (future integration) |

---

## Dev Dependencies

### Testing
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Widget & unit test framework |
| `mockito` | ^5.4.0 | Mock generation for testing |
| `build_runner` | ^2.4.0 | Code generation orchestrator |
| `bloc_test` | ^9.1.0 | BLoC-specific testing utilities |
| `mocktail` | ^1.0.0 | Alternative mocking (no code gen needed) |

### Code Generation
| Package | Version | Purpose |
|---------|---------|---------|
| `drift_dev` | ^2.22.0 | Drift code generation |
| `auto_route_generator` | ^9.0.0 | Route code generation |
| `injectable_generator` | ^2.7.0 | DI code generation |

### Linting
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | ^6.0.0 | Recommended lint rules |
| `custom_lint` | ^0.7.0 | Custom project lint rules (optional) |

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

  # Dependency Injection
  get_it: ^8.0.0
  injectable: ^2.5.0

  # Logging
  logger: ^2.5.0

  # UI
  cached_network_image: ^3.4.0
  shimmer: ^3.0.0
  flutter_svg: ^2.0.0
  google_fonts: ^6.2.0

  # Functional
  dartz: ^0.10.1

  # Analytics (enable as needed)
  # sentry_flutter: ^8.12.0
  # mixpanel_flutter: ^2.3.0
  # firebase_analytics: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.0
  mockito: ^5.4.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  drift_dev: ^2.22.0
  auto_route_generator: ^9.0.0
  injectable_generator: ^2.7.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
```

---

## Dependency Justification Matrix

| Requirement | Chosen Package | Alternatives Considered | Why This One |
|-------------|---------------|------------------------|--------------|
| HTTP Client | Dio | http, chopper | Interceptor chain, cancel tokens, multipart, mature |
| State Mgmt | flutter_bloc | Riverpod, Provider, GetX | Event-driven, testable, large community, scales well |
| Routing | auto_route | go_router, Navigator 2.0 | Deep linking, guards, code gen, nested nav |
| Local DB | Drift | sqflite, Hive, Isar | Type-safe, reactive, migrations, DAO pattern |
| DI | GetIt + Injectable | Riverpod, Provider | Framework-agnostic, works in non-widget code |
| Secure Storage | flutter_secure_storage | - | iOS Keychain + Android EncryptedSharedPrefs |
| Analytics | Custom interface | firebase_analytics alone | Interface allows swapping providers without code changes |
| Logging | logger | logging, print | Pretty formatting, log levels, zero config |
| Error Handling | dartz (Either) | Result type, exceptions only | Functional composition, explicit error paths |

---

## Version Pinning Policy

- **Major version**: Pin with caret (`^9.0.0`) - allows minor/patch updates
- **Generated code packages**: Pin generator and runtime to same major version
- **Flutter SDK**: Pin to minimum supported version
- **Run `flutter pub outdated` monthly** to check for security patches
- **Never use `any` version constraint** in production
