# 08 - State Management (flutter_bloc)

> Feature names and event examples in this document illustrate the pattern. Use the same structure with names that fit the real product domain.

## Philosophy

- **BLoC** (full event-driven) for complex features with multiple event sources
- **Cubit** for simpler state with direct method calls
- States are **immutable** value objects using `Equatable`
- Every state has explicit variants: `initial`, `loading`, `loaded`, `error`
- BLoCs NEVER directly call APIs — they call Use Cases

---

## BLoC vs Cubit Decision Matrix

| Use BLoC When | Use Cubit When |
|---------------|----------------|
| Multiple event types trigger state changes | Single action per state change |
| Event transformations needed (debounce, throttle) | No event transformation needed |
| Complex state machines | Linear state flow |
| Need event replay/logging | Simple logging suffices |

### Template Feature Assignments

| Feature | Pattern | Reason |
|---------|---------|--------|
| Auth | BLoC | Login, logout, refresh, session expire events |
| Library | BLoC | Load, search, filter, paginate events |
| Reader | BLoC | Load chapter, navigate, bookmark, progress events |
| Settings | Cubit | Direct method calls for each setting (no events file — state only) |
| Theme | BLoC | Multiple theme-change events, persistence side effects |
| Connectivity | BLoC | Stream-driven, external event source |

---

## State Design Pattern

Every feature state follows this sealed-class pattern:

### State Variants

| Variant | Meaning | Fields |
|---------|---------|--------|
| `Initial` | Not yet loaded, no action taken | None |
| `Loading` | Action in progress | Optional: previous data for optimistic UI |
| `Loaded` | Data successfully retrieved | The domain data |
| `Error` | Action failed | `AppException` with type + userMessage |

### Rules

1. States extend `Equatable` — BLoC uses equality to avoid redundant rebuilds
2. `props` must include ALL fields that affect rendering
3. States carry data, not behavior
4. `Loaded` state includes the full dataset, not a delta
5. Pagination: `Loaded` state includes `List<Item>`, `hasMore`, `currentPage`

---

## Event Design Pattern

### Rules

1. Events extend `Equatable`
2. Events are past-tense or imperative: `BooksRequested`, `SearchSubmitted`, `BookmarkToggled`
3. Events carry the minimum data needed for the BLoC to act
4. Events never carry callbacks or completer references

### Common Event Types Per Feature

**Library Events**:
| Event | Payload | Triggers |
|-------|---------|----------|
| `LibraryBooksRequested` | `int page` | Initial load, pagination |
| `LibrarySearchSubmitted` | `String query` | Search bar submission |
| `LibraryRefreshRequested` | none | Pull-to-refresh |
| `LibraryBookSelected` | `String bookId` | Navigate to detail |

**Reader Events**:
| Event | Payload | Triggers |
|-------|---------|----------|
| `ReaderChapterRequested` | `String bookId, int chapterIndex` | Open reader, navigate chapter |
| `ReaderBookmarkToggled` | `String chapterId, int position` | Tap bookmark button |
| `ReaderProgressSaved` | `ReadingProgress progress` | Periodic auto-save |
| `ReaderFontScaleChanged` | `double scale` | Reader controls slider |

---

## BLoC Implementation Specification

### Structure Per BLoC

Each BLoC consists of three files:

1. **`*_bloc.dart`**: Class with event handlers
2. **`*_event.dart`**: Sealed event classes
3. **`*_state.dart`**: Sealed state classes

### BLoC Class Rules

1. Constructor receives Use Cases (not repositories) via DI
2. `on<Event>` handlers are registered in constructor
3. Each handler receives `(event, Emitter<State> emit)` — use `emit()` to produce new states
4. Handlers can be `async` and call `emit()` multiple times (e.g., emit Loading then Loaded)
5. Use `transformer` parameter on `on<Event>` for debounce/throttle
6. Override `onError` to report to analytics

### Emitter Pattern

```dart
on<LibraryBooksRequested>((event, emit) async {
  emit(const LibraryLoading());
  final result = await getBooks(page: event.page);
  result.fold(
    (exception) => emit(LibraryError(exception: exception)),
    (books) => emit(LibraryLoaded(books: books)),
  );
});
```

The `Emitter` replaces the old `yield` / `mapEventToState` pattern. It allows multiple `emit()` calls within a single handler and supports async/await directly.

### Event Transformers (bloc_concurrency package)

Event transformers are provided by the **separate `bloc_concurrency` package** — they are not built into `bloc`. Add it to `pubspec.yaml`:

```yaml
dependencies:
  bloc_concurrency: ^<verified_version>
```

| Transformer | Applied To | Behavior |
|-------------|-----------|----------|
| `droppable()` | Load/fetch events | Ignores new events while one is processing |
| `restartable()` | Search events | Cancels in-progress handler on new event |
| `sequential()` | Bookmark/progress events | Processes in order, one at a time |
| `concurrent()` | Independent events | Processes all concurrently (default bloc behavior) |

```dart
on<LibrarySearchSubmitted>(
  _onSearchSubmitted,
  transformer: restartable(),  // cancels previous search on new input
);
```

**Note**: `restartable()` is generally better than manual debounce for search. Combine with a `Timer`/`Debouncer` in the UI if you need input debouncing before the event is dispatched.

---

## flutter_bloc Widgets

### Widget Selection Guide

| Widget | Use When | Key Parameter |
|--------|----------|---------------|
| `BlocBuilder<B, S>` | Rebuild UI based on state | `buildWhen` |
| `BlocListener<B, S>` | Side effects: navigation, snackbar, dialog | `listenWhen` |
| `BlocConsumer<B, S>` | Both rebuild AND side effect on same state | `buildWhen` + `listenWhen` |
| `BlocSelector<B, S, T>` | Rebuild only when a **derived value** changes | `selector: (state) => state.field` |
| `MultiBlocListener` | Multiple listeners without nesting | Wraps `List<BlocListener>` |

### BlocSelector — Granular Rebuilds

`BlocSelector` is more efficient than `BlocBuilder` when a widget depends on only part of the state:

```dart
// Rebuilds only when bookCount changes, not on every state change
BlocSelector<LibraryBloc, LibraryState, int>(
  selector: (state) => state is LibraryLoaded ? state.books.length : 0,
  builder: (context, bookCount) => Text('$bookCount books'),
)
```

Use `BlocSelector` when a widget depends on a computed or derived value from the state. Use `BlocBuilder` with `buildWhen` when the widget needs the full state object.

### buildWhen / listenWhen

Always provide `buildWhen` to prevent unnecessary rebuilds:
- Only rebuild when the specific state variant changes
- Don't rebuild the entire page when only a sub-state changes

---

## BLoC Provider Strategy

### Context Extensions (from flutter_bloc)

| Extension | Use In | Purpose |
|-----------|--------|---------|
| `context.read<T>()` | Callbacks (`onPressed`, `onTap`) | One-time lookup, no subscription |
| `context.watch<T>()` | `build()` method | Subscribes to changes, triggers rebuild |
| `context.select<T, V>(selector)` | `build()` method | Subscribes to derived value only |

**Rule**: Never call `context.watch()` or `context.select()` inside callbacks. Never call `context.read()` in `build()` for values that should trigger rebuilds.

### Global BLoCs (provided at app root in `app.dart`)

| BLoC | Reason |
|------|--------|
| `ThemeBloc` | Theme is app-wide |
| `ConnectivityBloc` | Connectivity affects all screens |
| `AuthBloc` | Auth state is global |

Provided via `MultiBlocProvider` wrapping `MaterialApp.router`.

### Scoped BLoCs (provided per route via go_router builder)

| BLoC | Scope | Provided Via |
|------|-------|-------------|
| `BillsBloc` | Bills tab | `BlocProvider` inside go_router route `builder` |
| `BillDetailBloc` | Bill detail screen | `BlocProvider` inside go_router route `builder` |
| `SettingsCubit` | Settings screen | `BlocProvider` inside go_router route `builder` |

Per-route injection pattern → [09_NAVIGATION_DEEP_LINKING.md](09_NAVIGATION_DEEP_LINKING.md#per-route-bloc-injection)

### RepositoryProvider (for widget-tree DI)

`flutter_bloc` provides `RepositoryProvider` and `MultiRepositoryProvider` for injecting repositories into the widget tree. Use these when a subtree needs a repository that isn't registered globally in GetIt:

```dart
// Inside GoRouter route definition:
GoRoute(
  path: '/bills',
  builder: (context, state) => MultiBlocProvider(
    providers: [
      RepositoryProvider(create: (_) => sl<BillsRepository>()),
      BlocProvider(
        create: (context) => sl<BillsBloc>()..add(const BillsRequested()),
      ),
    ],
    child: const BillsPage(),
  ),
),
```

**When to use RepositoryProvider vs GetIt**:

| Approach | When |
|----------|------|
| GetIt (`sl<T>()`) | Default — most repos are singletons, accessible anywhere |
| `RepositoryProvider` | When a repo instance is scoped to a specific route subtree |

### DI Registration (GetIt)

- Global BLoCs: `registerLazySingleton` in GetIt
- Scoped BLoCs: `registerFactory` in GetIt, injected inside go_router route `builder`

---

## BLoC Observer

**File**: `lib/core/di/app_bloc_observer.dart`

Set globally via `Bloc.observer = AppBlocObserver()` in `bootstrap.dart`.

| Hook | Available On | Purpose |
|------|-------------|---------|
| `onCreate` | Both | Log BLoC/Cubit creation |
| `onEvent` | BLoC only | Log incoming events |
| `onChange` | Both | Log state changes (`Change` object with `currentState` + `nextState`) |
| `onTransition` | BLoC only | Log full transition (`currentState` + `event` + `nextState`) |
| `onError` | Both | Report errors to `CrashReporter` |
| `onClose` | Both | Log BLoC/Cubit disposal |

**Environment config**:
- Development: log `onTransition` at verbose level
- Production: only `onError` reports to crash reporter

---

## Error Handling in BLoCs

1. Use Cases return `Either<AppException, T>` (from fpdart)
2. BLoC maps `Left(exception)` -> emit `Error` state
3. BLoC maps `Right(data)` -> emit `Loaded` state
4. Unexpected exceptions in BLoC are caught by `onError` -> reported to analytics

### Retry Pattern

Error states include the original event. The UI can show a "Retry" button that re-dispatches the event:
- `AppErrorPage` receives `VoidCallback onRetry`
- `onRetry` calls `context.read<FeatureBloc>().add(originalEvent)`

---

## BLoC-to-BLoC Communication

When one BLoC needs to react to another BLoC's state changes:

| Pattern | When |
|---------|------|
| Shared Use Case | Both BLoCs call the same use case independently |
| Stream subscription | BLoC A listens to BLoC B's `stream` and emits its own events |
| Event dispatching from UI | `BlocListener` on BLoC A dispatches event to BLoC B |

**Preferred**: Shared use cases (decoupled). Stream subscription only when BLoC A must react immediately without UI involvement.

---

## BLoC Disposal & Cleanup

BLoCs must clean up resources in `close()` to prevent memory leaks and race conditions.

### What to Cancel on close()

| Resource | Cleanup | If Skipped |
|----------|---------|-----------|
| Stream subscriptions | `_subscription.cancel()` | Memory leak, callbacks on dead BLoC |
| `CancelToken` | `_cancelToken.cancel()` | Orphaned network requests |
| Timers / debounce timers | `_timer?.cancel()` | Callbacks after disposal |
| Reactive Drift watches | Cancel the `StreamSubscription` | DB listener stays alive |

```dart
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  late final StreamSubscription _progressSub;
  final CancelToken _cancelToken = CancelToken();

  ReaderBloc(...) : super(const ReaderInitial()) {
    _progressSub = _readingDao.watchProgress(bookId).listen(
      (progress) => add(ReaderProgressUpdated(progress)),
    );
  }

  @override
  Future<void> close() {
    _progressSub.cancel();
    _cancelToken.cancel('BLoC closed');
    return super.close();
  }
}
```

### Double-Tap / Rapid Event Prevention

Use `droppable()` transformer from `bloc_concurrency` to ignore duplicate events while one is processing:

```dart
on<SubmitFormRequested>(
  _onSubmit,
  transformer: droppable(),  // second tap ignored while first is in-flight
);
```

For UI-level prevention, disable the button while loading:

```dart
FilledButton(
  onPressed: state is! Loading ? () => bloc.add(const SubmitFormRequested()) : null,
  child: state is Loading
    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
    : const Text('Submit'),
)
```

**Rule**: Use `droppable()` on any event that triggers a write operation (submit, delete, toggle). Use `restartable()` on events that trigger read operations where only the latest matters (search, filter).

---

## Testing BLoCs

Using `bloc_test` package:

### Test Structure

For each BLoC, test:
1. **Initial state**: BLoC starts with `Initial` state
2. **Happy path**: Event -> `Loading` -> `Loaded` with correct data
3. **Error path**: Event -> `Loading` -> `Error` with correct failure
4. **Multiple events**: Verify state sequence for event chains
5. **Transformer behavior**: Verify `droppable` / `restartable` works correctly

### Mocking

- Use `mocktail`: `class MockGetBooksUseCase extends Mock implements GetBooksUseCase {}`
- Mock at the Use Case level, not the repository level (BLoC tests don't care about data sources)
