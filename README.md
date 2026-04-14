# tricount

Flutter application workspace with a production-ready target architecture.

## Current Status

This repository is transitioning from a starter app to a layered architecture.

- **Current Implementation**: Theme system (`lib/core/theme/`) and Auth feature (`lib/features/auth/`) are under development.
- **Target State**: Layered, feature-first architecture as documented in `docs/`.

Read [docs/01_DEVELOPMENT.md](docs/01_DEVELOPMENT.md#1-project-status--adoption) for the current adoption status and roadmap.

## Documentation Index

The documentation is organized into five core guides:

1. [**01 - Development Guide**](docs/01_DEVELOPMENT.md) — Coding rules, project status, and folder structure.
2. [**02 - Architecture & State**](docs/02_ARCHITECTURE.md) — Design principles, BLoC, and DI.
3. [**03 - Data Layer**](docs/03_DATA_LAYER.md) — Networking, Storage, and Security.
4. [**04 - UI & UX**](docs/04_UI_UX.md) — Theming, Navigation, and Components.
5. [**05 - Ops & Quality**](docs/05_OPS_QUALITY.md) — Testing, CI/CD, and Analytics.

See [docs/00_INDEX.md](docs/00_INDEX.md) for a technical summary and shared conventions.

## Local Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

## Architecture Rule of Thumb

- **Barrel Files**: Every folder with 2+ public files must have a barrel file.
- **Grids over Lists**: Use `GridView.builder` for content browsing.
- **Zero Inline Styles**: All styling must live in `AppTheme.build`.
- **Typed Errors**: Use `sealed class AppException` and `Either<AppException, T>`.
