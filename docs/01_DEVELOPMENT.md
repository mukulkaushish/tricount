# 01 - Development Guide & Standards

This document covers everything a developer needs to know about writing code in this project, from coding rules to project structure and feature specifications.

---

## 1. Project Status & Adoption

The repository describes a production-ready architecture, but the codebase is currently in **Phase 1 (Baseline Setup)**.

| Area | Status | Key Files |
|------|--------|-----------|
| **Core Theme** | In Progress | `lib/core/theme/` |
| **Auth Feature** | In Progress | `lib/features/auth/` |
| **App Wiring** | In Progress | `lib/app.dart`, `lib/main.dart` |

**Rule**: Treat architectural patterns as adaptable recommendations. Apply them in proportion to the app's size and complexity.

---

## 2. Coding Rules (The "Non-Negotiables")

### Linting
We use `very_good_analysis`. Every file must pass `flutter analyze` with zero warnings.

### Key Conventions
- **Immutability**: Use `final` for all fields, variables, and parameters. Use `const` constructors.
- **No Magic Numbers**: Use `AppDimensions` for spacing, padding, and radius.
- **No Inline Themes**: Access themes via `context.textTheme` or `context.appColors`.
- **Exhaustive Patterns**: No `default` cases in switches over sealed classes or enums.
- **Naming**: `PascalCase` for classes/enums, `snake_case` for files, `camelCase` for variables/constants.

### File Organization
1. Static constants/fields
2. Final fields
3. Constructors
4. Public methods
5. Private methods
6. `@override` methods last

---

## 3. Project Structure & Barrel Files

### The Barrel Convention
Every folder with 2+ public Dart files **must** have a barrel file named `<folder_name>.dart`.
- **Import Rule**: Always import through barrels (e.g., `import 'core/core.dart'`) when crossing module boundaries.
- **Export Rule**: Only export the public surface. Never export implementation details (like `data/` in a feature) or generated files (`*.g.dart`).

### Directory Overview
- `lib/core/`: Cross-cutting infrastructure (Network, Theme, DI, Logging).
- `lib/features/`: Self-contained feature modules (Data, Domain, Presentation).
- `lib/shared/`: Reusable presentation-only widgets.
- `lib/router/`: Navigation and route guards.

### Feature Structure
```
feature_name/
├── data/           # Remote/Local sources, DTOs, Repository Impls
├── domain/         # Entities, Repository Interfaces, Use Cases
└── presentation/   # BLoC, Pages, Widgets
```

---

## 4. Feature Specification Template

When building a new feature, document it using this structure:

1. **API Contract**: Endpoints, methods, response shapes, and pagination.
2. **Data Layer**: Models (DTOs), Repository signatures, and cache strategy.
3. **Domain Layer**: Pure Dart entities and single-purpose use cases.
4. **Presentation Layer**: BLoC events/states, UI layout, and route injection.
5. **User Flows**: Happy path, error handling, and offline behavior.

**Responsive Priority**: Use **Grids over Lists** for content browsing to ensure the app feels "alive" and adaptive across phones, tablets, and foldables.

---

## 5. Pre-Commit Checklist

Before every commit, run:
```bash
dart format .
flutter analyze
flutter test
```
All three must pass with **zero** warnings/failures.
