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

### Core Rules (SOLID)
- **Single Responsibility (S)**: BLoCs handle logic; Repositories handle data; Widgets handle UI.
- **Open/Closed (O)**: Classes/modules are open for extension but closed for modification. Use inheritance and composition to add behavior.
- **Liskov Substitution (L)**: Subtypes must be substitutable for their base types without affecting correctness.
- **Interface Segregation (I)**: Services (Analytics, Logging) are hidden behind small, focused abstract interfaces.
- **Dependency Inversion (D)**: High-level modules (Domain) define interfaces; Low-level modules (Data) implement them.

---

## 2. Extensions: The Reusability Layer

We prioritize **Dart Extensions** to promote code reuse and avoid duplication across the project.

### Why Extensions?
- **DRY (Don't Repeat Yourself)**: Common logic on SDK types (e.g., `BuildContext`, `String`, `DateTime`) is centralized.
- **Readability**: Logic is accessed fluently (e.g., `context.colorScheme` instead of `Theme.of(context).colorScheme`).
- **Encapsulation**: Keeps feature code clean by moving utility logic to the `core/extensions/` directory.

### Key Extension Areas
- **BuildContext**: Quick access to Theme, MediaQuery, and Localization.
- **Strings/Numbers**: Formatting, validation, and transformations.
- **Date/Time**: Relative time, custom formatting, and comparisons.
- **UI Components**: Applying common styles or constraints to widgets.

---

## 3. Dependency Manifest

We add dependencies **deliberately**, prioritizing Flutter SDK capabilities first.

### Key Production Packages
- **State**: `flutter_bloc`, `bloc_concurrency`, `equatable`.
- **Navigation**: `auto_route` (with `auto_route_generator` for type-safety and `AutoRouteWrapper` for BLoC scoping).
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
- **Scoped BLoCs**: For feature-specific state that should be disposed of when leaving the route, implement `AutoRouteWrapper` on the page widget. This ensures the BLoC is created and provided only for that specific route and its sub-routes.
```dart
@RoutePage()
class LoginPage extends StatelessWidget implements AutoRouteWrapper {
  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) => const LoginView();
}
```
