# 08 — State Management (flutter_bloc)

> Feature names are pattern examples.

## Philosophy
- **BLoC** for complex, event-driven features.
- **Cubit** for simpler state with direct method calls.
- States are **immutable** `Equatable` value objects.
- Every state has variants: `initial`, `loading`, `loaded`, `error`.
- BLoCs **never** call APIs directly — they call Use Cases.

## BLoC vs Cubit

| Use BLoC | Use Cubit |
|---|---|
| Multiple event types | Single action per state change |
| Event transforms (debounce/throttle) | No transforms |
| Complex state machines | Linear state flow |
| Need event replay/logging | Simple logging suffices |

**Template assignments:**

| Feature | Pattern | Reason |
|---|---|---|
| Auth | BLoC | login/logout/refresh/expire events |
| Library | BLoC | load/search/filter/paginate |
| Reader | BLoC | load chapter/navigate/bookmark/progress |
| Settings | Cubit | direct method per setting (no events file) |
| Theme | BLoC | multi-event + persistence side effects |
| Connectivity | BLoC | stream-driven external source |

## State design

Sealed-class pattern:

| Variant | Fields |
|---|---|
| `Initial` | — |
| `Loading` | optional previous data for optimistic UI |
| `Loaded` | domain data |
| `Error` | `AppException` (has `userMessage`) |

**Rules:**
1. `extends Equatable` — avoids redundant rebuilds.
2. `props` includes ALL render-affecting fields.
3. States carry data, not behavior.
4. `Loaded` holds full dataset, not delta.
5. Pagination: `Loaded { List<Item> items, bool hasMore, int currentPage }`.

## Event design

**Rules:**
1. `extends Equatable`.
2. Past-tense/imperative: `BooksRequested`, `SearchSubmitted`, `BookmarkToggled`.
3. Carry minimum data.
4. **Never** carry callbacks or completer references.

**Library events:**
| Event | Payload | Triggers |
|---|---|---|
| `LibraryBooksRequested` | `int page` | load / pagination |
| `LibrarySearchSubmitted` | `String query` | search submit |
| `LibraryRefreshRequested` | — | pull-to-refresh |
| `LibraryBookSelected` | `String bookId` | nav to detail |

**Reader events:**
| Event | Payload | Triggers |
|---|---|---|
| `ReaderChapterRequested` | `String bookId, int chapterIndex` | open reader / nav |
| `ReaderBookmarkToggled` | `String chapterId, int position` | tap bookmark |
| `ReaderProgressSaved` | `ReadingProgress progress` | periodic save |
| `ReaderFontScaleChanged` | `double scale` | reader slider |

## BLoC implementation

**Three files:** `*_bloc.dart` (class + handlers), `*_event.dart` (sealed events), `*_state.dart` (sealed states).

**Rules:**
1. Constructor takes Use Cases (not repos) via DI.
2. `on<Event>` registered in constructor.
3. Handler signature: `(event, Emitter<State> emit)` — use `emit()` to produce states.
4. Handlers can `async` and `emit()` multiple times (Loading → Loaded).
5. Use `transformer` for debounce/throttle.
6. Override `onError` for analytics reporting.

**Emitter pattern:**
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

## Event transformers (`bloc_concurrency` package)

**Separate from `bloc` package** — add `bloc_concurrency: ^<verified>` to `pubspec.yaml`.

| Transformer | For | Behavior |
|---|---|---|
| `droppable()` | load/fetch | ignores new events while processing |
| `restartable()` | search | cancels in-progress handler on new event |
| `sequential()` | bookmark/progress | processes in order, one at a time |
| `concurrent()` | independent | processes all concurrently (default) |

```dart
on<LibrarySearchSubmitted>(
  _onSearchSubmitted,
  transformer: restartable(), // cancels previous on new input
);
```

> `restartable()` is generally better than manual debounce for search. Combine with a `Timer`/`Debouncer` in UI if you need input debouncing before dispatch.

## flutter_bloc widgets

| Widget | Use When | Key param |
|---|---|---|
| `BlocBuilder<B,S>` | rebuild UI from state | `buildWhen` |
| `BlocListener<B,S>` | side effects (nav/snackbar/dialog) | `listenWhen` |
| `BlocConsumer<B,S>` | rebuild AND side effect | `buildWhen` + `listenWhen` |
| `BlocSelector<B,S,T>` | rebuild only on derived value | `selector: (state) => state.field` |
| `MultiBlocListener` | many listeners without nesting | `List<BlocListener>` |

**BlocSelector** — more efficient than `BlocBuilder` when widget depends only on part of state:
```dart
BlocSelector<LibraryBloc, LibraryState, int>(
  selector: (state) => state is LibraryLoaded ? state.books.length : 0,
  builder: (context, bookCount) => Text('$bookCount books'),
)
```
Use `BlocSelector` for derived values; `BlocBuilder` + `buildWhen` when widget needs full state.

**`buildWhen`/`listenWhen`** — always provide to prevent unnecessary rebuilds. Only rebuild on specific state variant changes.

## Provider strategy

### Context extensions
| Extension | Use in | Purpose |
|---|---|---|
| `context.read<T>()` | callbacks (`onPressed`, `onTap`) | one-time lookup, no subscription |
| `context.watch<T>()` | `build()` | subscribes, rebuilds |
| `context.select<T,V>(selector)` | `build()` | subscribes to derived value only |

**Rule:** never `watch()`/`select()` in callbacks; never `read()` in `build()` for values that should rebuild.

### Global BLoCs (at app root in `app.dart`)
| BLoC | Reason |
|---|---|
| `ThemeBloc` | app-wide theme |
| `ConnectivityBloc` | affects all screens |
| `AuthBloc` | global session |

Provided via `MultiBlocProvider` wrapping `MaterialApp.router`.

### Scoped BLoCs (per-route via `WrappedRoute`)
| BLoC | Scope | Provided via |
|---|---|---|
| `LibraryBloc` | Library tab | `WrappedRoute` |
| `ReaderBloc` | Reader screen | `WrappedRoute` |
| `SettingsCubit` | Settings screen | `WrappedRoute` |

Full details → `09_NAVIGATION_DEEP_LINKING.md#per-route-di-with-wrappedroute`.

### `RepositoryProvider` (widget-tree DI)

`flutter_bloc` provides `RepositoryProvider`/`MultiRepositoryProvider` for injecting repos into the widget tree. Use when a subtree needs a repo not registered globally:

```dart
@override
Widget wrappedRoute(BuildContext context) => MultiRepositoryProvider(
  providers: [RepositoryProvider(create: (_) => sl<LibraryRepository>())],
  child: BlocProvider(
    create: (context) => LibraryBloc(getBooks: sl<GetBooksUseCase>())
      ..add(const LibraryBooksRequested(page: 1)),
    child: this,
  ),
);
```

| Approach | When |
|---|---|
| GetIt `sl<T>()` | default — most repos are singletons |
| `RepositoryProvider` | repo scoped to route subtree / testable via `context.read` |

### DI registration
- Global BLoCs → `registerLazySingleton`.
- Scoped BLoCs → `registerFactory`, injected via `WrappedRoute`.

## BLoC observer (`lib/core/di/app_bloc_observer.dart`)

Set globally in `bootstrap.dart`: `Bloc.observer = AppBlocObserver()`.

| Hook | On | Purpose |
|---|---|---|
| `onCreate` | both | log creation |
| `onEvent` | BLoC | log events |
| `onChange` | both | log state changes (`Change` with current+next) |
| `onTransition` | BLoC | log transition (current+event+next) |
| `onError` | both | report to `CrashReporter` |
| `onClose` | both | log disposal |

**Env:** dev — verbose `onTransition`; prod — only `onError` reports.

## Error handling

1. Use Cases return `Either<AppException, T>` (fpdart).
2. BLoC: `Left(exception)` → emit `Error`; `Right(data)` → emit `Loaded`.
3. Unexpected exceptions caught by `onError` → analytics.

### Retry pattern

`Error` states include the original event. UI shows "Retry" button that re-dispatches:
- `AppErrorPage` receives `VoidCallback onRetry`.
- `onRetry` → `context.read<FeatureBloc>().add(originalEvent)`.

## BLoC-to-BLoC communication

| Pattern | When |
|---|---|
| Shared use case | Both BLoCs call same use case independently |
| Stream subscription | BLoC A listens to BLoC B's `stream`, emits own events |
| Event dispatch from UI | `BlocListener` on A dispatches event to B |

**Preferred:** shared use cases (decoupled). Stream sub only when A must react without UI.

## Disposal & cleanup

BLoCs must clean up in `close()` to prevent leaks + race conditions.

| Resource | Cleanup | If skipped |
|---|---|---|
| Stream subs | `_sub.cancel()` | leak, callbacks on dead BLoC |
| `CancelToken` | `_token.cancel()` | orphaned network requests |
| Timers/debouncers | `_timer?.cancel()` | callbacks after disposal |
| Drift `.watch` | cancel `StreamSubscription` | DB listener stays alive |

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

## Double-tap / rapid event prevention

Use `droppable()` for writes; disable button while loading for UI-level prevention:

```dart
on<SubmitFormRequested>(_onSubmit, transformer: droppable());
```

```dart
FilledButton(
  onPressed: state is! Loading ? () => bloc.add(const SubmitFormRequested()) : null,
  child: state is Loading
    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
    : const Text('Submit'),
)
```

**Rule:** `droppable()` on write ops (submit/delete/toggle); `restartable()` on read ops where only the latest matters (search/filter).

## Testing BLoCs (`bloc_test`)

For each BLoC, test:
1. **Initial state** — starts with `Initial`.
2. **Happy path** — Event → `Loading` → `Loaded` with correct data.
3. **Error path** — Event → `Loading` → `Error` with correct failure.
4. **Multi-event** — verify state sequence for event chains.
5. **Transformer** — verify `droppable`/`restartable`.

**Mocking** — mocktail: `class MockGetBooksUseCase extends Mock implements GetBooksUseCase {}`. Mock at use-case level, not repo (BLoC tests don't care about data sources).
