# Flutter Reading Application - Template Documentation Index

> A comprehensive blueprint for building a world-class reading application in Flutter.
> This documentation package contains everything needed to implement the full template
> without writing a single line of code beforehand. Every architectural decision,
> file path, class name, dependency, and integration point is specified.

---

## Document Map

| # | Document | Purpose |
|---|----------|---------|
| 00A | [Coding Rules](00A_CODING_RULES.md) | **READ FIRST** - very_good_analysis, naming, style, architectural rules |
| 01 | [Architecture Overview](01_ARCHITECTURE_OVERVIEW.md) | SOLID principles, design patterns, layer separation, dependency rules |
| 02 | [Project Structure](02_PROJECT_STRUCTURE.md) | Complete file/folder tree with purpose annotations |
| 03 | [Dependency Manifest](03_DEPENDENCY_MANIFEST.md) | Every pub.dev package, version constraints, and why each is needed |
| 04 | [App Bootstrap & main.dart](04_APP_BOOTSTRAP.md) | Initialization sequence, DI setup, environment config, entry point |
| 05 | [Dynamic Theming System](05_THEMING_SYSTEM.md) | Multi-color palettes, night mode, font scaling, no inline themes |
| 06 | [Networking Layer](06_NETWORKING_LAYER.md) | Dio setup, interceptors (auth, retry, cache, built-in LogInterceptor), HttpClient interface |
| 07 | [JSON Parsing & Codable](07_JSON_PARSING_CODABLE.md) | JsonParser mixin, JsonCodable interface, AppException hierarchy |
| 08 | [State Management](08_STATE_MANAGEMENT.md) | flutter_bloc architecture, BLoC/Cubit conventions, event/state design |
| 09 | [Navigation & Deep Linking](09_NAVIGATION_DEEP_LINKING.md) | auto_route setup, guards, deep link schemas, route definitions |
| 10 | [Local Storage](10_LOCAL_STORAGE.md) | Drift database, secure storage, caching strategy |
| 11 | [Connectivity & Resilience](11_CONNECTIVITY_RESILIENCE.md) | Connectivity banner, offline mode, retry policies |
| 12 | [Analytics Interface](12_ANALYTICS_INTERFACE.md) | Abstract analytics, event taxonomy, provider adapters |
| 13 | [Logging System](13_LOGGING_SYSTEM.md) | Logger setup, log levels, interceptor logging, crash reporting |
| 14 | [Error Handling](14_ERROR_HANDLING.md) | AppException hierarchy, error state pages, boundary widgets |
| 15 | [Reusable Components](15_REUSABLE_COMPONENTS.md) | Loading page, error page, common widgets, component catalog |
| 16 | [Animations & Transitions](16_ANIMATIONS_TRANSITIONS.md) | Page transitions, micro-interactions, performance budgets |
| 17 | [Testing Strategy](17_TESTING_STRATEGY.md) | Unit, widget, integration tests, mocktail mocking, coverage targets |
| 18 | [CI/CD Pipeline](18_CI_CD_PIPELINE.md) | GitHub Actions workflows, automated testing, deployment |
| 19 | [Reading Feature Spec](19_READING_FEATURE_SPEC.md) | Content API integration, reader UI, text controls, bookmarks |
| 20 | [Security](20_SECURITY.md) | Secure token storage, certificate pinning, data encryption |
| 21 | [Localization](21_LOCALIZATION.md) | ARB files, gen-l10n setup, pluralization, date/currency formatting |
| 22 | [Accessibility](22_ACCESSIBILITY.md) | Semantics, contrast ratios, tap targets, screen reader testing |

---

## How to Use This Documentation

1. **Read 00A (Coding Rules) first** - non-negotiable standards before any code
2. **Read 01-04 next** - these establish the foundation
3. **Set up dependencies (03)** and **bootstrap (04)** in your project
4. **Implement core infrastructure** (05-07) before any features
5. **Layer in state management (08)** and **navigation (09)**
6. **Build feature modules** referencing patterns in (15) and (19)
7. **Add cross-cutting concerns** (11-14) throughout
8. **Set up CI/CD (18)** and **testing (17)** in parallel with development

## Conventions Used

- `lib/` paths are relative to the project root
- Class names are in `PascalCase`, file names in `snake_case`
- Interfaces are prefixed with the domain concept (e.g., `AnalyticsService`, not `IAnalyticsService`)
- Abstract classes serve as interfaces (Dart convention)
- Every module follows: `interface -> implementation -> registration`
