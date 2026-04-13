# Flutter App Documentation Index

> This docs set is a practical handbook for moving a Flutter codebase from starter app to production-ready architecture.
> It mixes current-state guidance, target-state architecture, and operational checklists, so always read the project-status doc first.

## Read Order

1. [00A - Coding Rules](00A_CODING_RULES.md)
2. [00B - Project Status & Adoption Plan](00B_PROJECT_STATUS_AND_ADOPTION.md)
3. [01 - Architecture Overview](01_ARCHITECTURE_OVERVIEW.md)
4. [02 - Project Structure](02_PROJECT_STRUCTURE.md)
5. [03 - Dependency Manifest](03_DEPENDENCY_MANIFEST.md)

## Document Map

| # | Document | Purpose |
|---|----------|---------|
| 00A | [Coding Rules](00A_CODING_RULES.md) | Lint rules, style conventions, and non-negotiable coding practices |
| 00B | [Project Status & Adoption Plan](00B_PROJECT_STATUS_AND_ADOPTION.md) | Current repo reality, target architecture status, and rollout order |
| 01 | [Architecture Overview](01_ARCHITECTURE_OVERVIEW.md) | Layer boundaries, design principles, and dependency direction |
| 02 | [Project Structure](02_PROJECT_STRUCTURE.md) | Folder structure, barrel conventions, and module organization |
| 03 | [Dependency Manifest](03_DEPENDENCY_MANIFEST.md) | Recommended package set, selection criteria, and adoption notes |
| 04 | [App Bootstrap & main.dart](04_APP_BOOTSTRAP.md) | Startup sequence, initialization, and DI setup |
| 05 | [Dynamic Theming System](05_THEMING_SYSTEM.md) | Theme architecture, palettes, typography, and shared tokens |
| 06 | [Networking Layer](06_NETWORKING_LAYER.md) | HTTP abstractions, interceptors, and request conventions |
| 07 | [JSON Parsing & Codable](07_JSON_PARSING_CODABLE.md) | Parsing helpers, DTO conventions, and serialization rules |
| 08 | [State Management](08_STATE_MANAGEMENT.md) | BLoC/Cubit guidance, state modeling, and event conventions |
| 09 | [Navigation & Deep Linking](09_NAVIGATION_DEEP_LINKING.md) | Routing setup, guards, and deep-link handling |
| 10 | [Local Storage](10_LOCAL_STORAGE.md) | Drift, secure storage, and caching strategy |
| 11 | [Connectivity & Resilience](11_CONNECTIVITY_RESILIENCE.md) | Offline behavior, retries, and network awareness |
| 12 | [Analytics Interface](12_ANALYTICS_INTERFACE.md) | Analytics contracts, event taxonomy, and adapters |
| 13 | [Logging System](13_LOGGING_SYSTEM.md) | Logging structure, environments, and crash-reporting hooks |
| 14 | [Error Handling](14_ERROR_HANDLING.md) | Exception modeling, UI error states, and error boundaries |
| 15 | [Reusable Components](15_REUSABLE_COMPONENTS.md) | Shared widgets, loading states, and design consistency |
| 16 | [Animations & Transitions](16_ANIMATIONS_TRANSITIONS.md) | Motion patterns and performance-friendly transitions |
| 17 | [Testing Strategy](17_TESTING_STRATEGY.md) | Recommended unit, widget, and integration testing approach |
| 18 | [CI/CD Pipeline](18_CI_CD_PIPELINE.md) | Recommended GitHub Actions pipeline and rollout path |
| 19 | [Example Feature Specification](19_READING_FEATURE_SPEC.md) | Example feature-spec format you can adapt to your domain |
| 20 | [Security](20_SECURITY.md) | Sensitive storage, transport security, and defensive defaults |
| 21 | [Localization](21_LOCALIZATION.md) | Localization setup, ARB workflow, and formatting guidance |
| 22 | [Accessibility](22_ACCESSIBILITY.md) | Semantics, contrast, touch targets, and assistive-tech support |
| 24 | [Performance & Release Gates](24_PERFORMANCE_AND_RELEASE_GATES.md) | Performance profiling, quality checks, and release readiness |

## How To Use These Docs

- Use `00A` and `00B` to understand the rules and the repo's current maturity.
- Treat `01` through `24` as the recommended target architecture unless a doc explicitly says otherwise.
- Adapt patterns to the app's actual size and complexity instead of applying every pattern on day one.
- When a doc describes files or dependencies that do not yet exist, create them only when they meaningfully support the next implementation step.

## Shared Conventions

- Paths are relative to the project root unless noted otherwise.
- Class names use `PascalCase`; file names use `snake_case`.
- Abstract classes typically serve as interfaces in Dart.
- Examples use `package:<app_package>/...`; in this repository, `<app_package>` resolves to `tricount`.
