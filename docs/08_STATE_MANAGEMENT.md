# 08 - State Management (flutter_bloc)

> Feature names and event examples in this document illustrate the pattern. Use the same structure with names that fit the real product domain.

## Philosophy

- **BLoC** (full event-driven) for complex features with multiple event sources
- **Cubit** for simpler state with direct method calls
- States are **immutable** value objects using `Equatable`
- Every state has explicit variants: `initial`, `loading`, `loaded`, `error`
- BLoCs NEVER directly call APIs - they call Use Cases

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

1. States extend `Equatable` - BLoC uses equality to avoid redundant rebuilds
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
3. Each handler calls a Use Case, maps the result to a state
4. Use `emit()` for state transitions
5. Use `transformer` for debounce/throttle on search events
6. Override `onError` to report to analytics

### Event Transformers

| Transformer | Applied To | Config |
|-------------|-----------|--------|
| `debounce(300ms)` | Search events | Wait for user to stop typing |
| `droppable()` | Load events | Ignore duplicate loads while one is in progress |
| `sequential()` | Bookmark/progress events | Process in order |

---

## BLoC Provider Strategy

### Global BLoCs (provided at app root)

| BLoC | Reason |
|------|--------|
| `ThemeBloc` | Theme is app-wide |
| `ConnectivityBloc` | Connectivity affects all screens |
| `AuthBloc` | Auth state is global |

### Scoped BLoCs (provided per route)

| BLoC | Scope | Provided At |
|------|-------|-------------|
| `LibraryBloc` | Library tab | Library page route |
| `ReaderBloc` | Reader screen | Reader page route |
| `SettingsBloc` | Settings screen | Settings page route |

### DI Registration

- Global BLoCs: `registerLazySingleton` in GetIt
- Scoped BLoCs: `registerFactory` in GetIt, wrapped in `BlocProvider` at the route level

---

## BlocBuilder / BlocListener / BlocConsumer

### When to use which

| Widget | Use When |
|--------|----------|
| `BlocBuilder` | Rebuild UI based on state |
| `BlocListener` | Side effects: navigation, snackbar, dialog |
| `BlocConsumer` | Both rebuild AND side effect on same state |

### buildWhen / listenWhen

Always provide `buildWhen` to prevent unnecessary rebuilds:
- Only rebuild when the specific state variant changes
- Don't rebuild the entire page when only a sub-state changes

---

## Error Handling in BLoCs

1. Use Cases return `Either<AppException, T>` (from fpdart)
2. BLoC maps `Left(failure)` → emit `Error` state
3. BLoC maps `Right(data)` → emit `Loaded` state
4. Unexpected exceptions in BLoC are caught by `onError` → reported to analytics

### Retry Pattern

Error states include the original event. The UI can show a "Retry" button that re-dispatches the event:
- `AppErrorPage` receives `VoidCallback onRetry`
- `onRetry` calls `context.read<FeatureBloc>().add(originalEvent)`

---

## Testing BLoCs

Using `bloc_test` package:

### Test Structure

For each BLoC, test:
1. **Initial state**: BLoC starts with `Initial` state
2. **Happy path**: Event → `Loading` → `Loaded` with correct data
3. **Error path**: Event → `Loading` → `Error` with correct failure
4. **Multiple events**: Verify state sequence for event chains
5. **Event deduplication**: Verify `droppable` transformer works

### Mocking

- Use `mocktail`: `class MockGetBooksUseCase extends Mock implements GetBooksUseCase {}`
- Or use `mocktail` for simpler mock setup without code generation
- Mock at the Use Case level, not the repository level (BLoC tests don't care about data sources)
