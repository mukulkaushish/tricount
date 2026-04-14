# Tricount Project Documentation Index

This docs set is a practical handbook for moving the Tricount Flutter codebase from a starter app to a production-ready architecture.

## Read Order

1. [**01 - Development Guide**](01_DEVELOPMENT.md) — Coding rules, structure, and standards.
2. [**02 - Architecture & State**](02_ARCHITECTURE.md) — Design principles, BLoC, and DI.
3. [**03 - Data Layer**](03_DATA_LAYER.md) — Networking, Storage, and Security.
4. [**04 - UI & UX**](04_UI_UX.md) — Theming, Navigation, and Components.
5. [**05 - Ops & Quality**](05_OPS_QUALITY.md) — Testing, CI/CD, and Analytics.

---

## Technical Summary

| Area | Choice |
|------|--------|
| **Language** | Dart (latest stable) |
| **UI Framework** | Flutter (Material 3) |
| **State Management** | BLoC / Cubit (`flutter_bloc`) |
| **Navigation** | `auto_route` |
| **Networking** | `dio` + abstract `HttpClient` |
| **Database** | `drift` (SQLite) |
| **DI** | `get_it` |
| **Lints** | `very_good_analysis` |
| **Testing** | `mocktail`, `bloc_test`, `integration_test` |

---

## Shared Conventions

- **Barrel Files**: Every folder with 2+ public files must have a barrel file.
- **Grids over Lists**: Use `GridView.builder` for content browsing to ensure responsiveness.
- **Zero Inline Styles**: All styling must live in `AppTheme.build`.
- **Typed Errors**: Use `sealed class AppException` and `Either<AppException, T>`.
