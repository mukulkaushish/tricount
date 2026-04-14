# 02 - Architecture, State & Dependencies

This document outlines the high-level design principles, dependency management strategy, and state management patterns used in the project.

---

## 1. Architectural Principles (SOLID & Clean)

We follow **Clean Architecture** with a **feature-first** organization.

### The 4 Layers
1. **Presentation**: Widgets, Pages, BLoCs, and Routes. Depends on Domain + Core.
2. **Domain**: Pure Dart entities, use cases, and repository interfaces. **No Flutter imports**.
3. **Data**: Repository implementations, DTOs, and Data Sources (Remote/Local). Depends on Domain.
4. **Core**: App-wide infrastructure (Network, Auth, Theme, DI).

### Core Rules
- **Dependency Inversion**: Domain defines interfaces; Data implements them.
- **Single Responsibility**: BLoCs handle logic; Repositories handle data; Widgets handle UI.
- **Interface Segregation**: Services (Analytics, Logging) are hidden behind abstract interfaces.

---

## 2. Dependency Manifest

We add dependencies **deliberately**, prioritizing Flutter SDK capabilities first.

### Key Production Packages
- **State**: `flutter_bloc`, `bloc_concurrency`, `equatable`.
- **Navigation**: `go_router` (with `go_router_builder` for type-safety).
- **Networking**: `dio`, `connectivity_plus`.
- **Storage**: `drift` (SQLite), `flutter_secure_storage`, `shared_preferences`.
- **DI**: `get_it`.
- **Logic**: `fpdart` (for `Either` types).
- **UI**: `cached_network_image`, `flutter_svg`, `flutter_adaptive_scaffold`.

---

## 3. App Bootstrap & DI

The app follows a strict initialization sequence in `lib/bootstrap.dart`:

1. **Logger**: First to initialize so other steps can log.
2. **Environment**: Determines API URLs and feature flags.
3. **DI (GetIt)**: Registers all modules (Network, Storage, Features).
4. **Global Observers**: Sets `Bloc.observer` and `AppLifecycleObserver`.
5. **Error Handlers**: Sets `FlutterError.onError` and `PlatformDispatcher.onError`.

### DI Strategy
- **Singletons**: Repositories and Services (`sl.registerLazySingleton`).
- **Factories**: BLoCs/Cubits (`sl.registerFactory`) — new instance per screen.

---

## 4. State Management (BLoC/Cubit)

### Pattern Selection
- **BLoC**: For complex features with multiple event sources (Auth, Library, Reader).
- **Cubit**: For simple, linear state (Settings).

### State Design (The Sealed Class Pattern)
Every state has explicit variants:
- `Initial`: No action taken.
- `Loading`: Work in progress.
- `Loaded`: Success, carries domain data.
- `Error`: Failure, carries `AppException`.

### Event Transformers
We use `bloc_concurrency` to control event flow:
- `droppable()`: Ignore new events while one is processing (e.g., Form Submit).
- `restartable()`: Cancel in-progress work on new event (e.g., Search).
- `sequential()`: Process events in order (e.g., Progress Tracking).

---

## 5. Global vs Scoped State

- **Global BLoCs**: Provided in `app.dart` (Theme, Auth, Connectivity).
- **Scoped BLoCs**: Provided per-route in `app_router.dart` using `BlocProvider` in the `builder` callback. This ensures BLoCs are disposed of when the user leaves the route.
