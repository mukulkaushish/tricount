# 17 — Testing Strategy

> Recommended strategy. Adopt incrementally.

## Test pyramid

```
        ╱  Integration (E2E)  ╲    ← few — full user flows
       ╱                        ╲
      ╱      Widget Tests         ╲  ← medium — pages, components
     ╱                              ╲
    ╱        Unit Tests              ╲  ← many — BLoCs, use cases, repos, parsing
```

| Layer | Target count | Speed | Covers |
|---|---|---|---|
| Unit | ~70% | < 1s each | BLoCs, Use Cases, Repos, JsonParser, Extensions |
| Widget | ~20% | < 3s each | Page render, interactions, error/loading states |
| Integration | ~10% | < 30s each | Full flows across screens |

## Unit tests

### BLoC tests (`bloc_test`)

Every BLoC, every event → state sequence.

| Category | Verify |
|---|---|
| Initial state | starts with expected |
| Happy path | Event → [Loading, Loaded(data)] |
| Error path | Event → [Loading, Error(failure)] |
| Multi-event | correct sequence for event chains |
| Debounce/throttle | transformer behavior (e.g. search debounce) |

**Mocking:** use cases with mocktail — no codegen.

### Use case tests
| Category | Verify |
|---|---|
| Delegation | calls correct repo method |
| Return mapping | `Either` passed through correctly |
| Business logic | any transformation/validation |

### Repository tests
| Category | Verify |
|---|---|
| Remote success | API call → DTO parsed → entity returned as Right |
| Remote failure | exception → `AppException` returned as Left |
| Cache fallback | remote fails → local cache returned |
| Cache update | remote success → local cache updated |

**Mocking:** both `RemoteDataSource` and `LocalDataSource`.

### JsonParser tests
| Category | Verify |
|---|---|
| Valid parse | correct types from well-formed JSON |
| Missing required | `DataMismatchException` with correct `fieldName` |
| Wrong type | `DataMismatchException` with descriptive message |
| Null optionals | returns `null` without throwing |
| Coercion | `"123"` → `int 123`, etc. |
| Round-trip | `fromJson(toJson(m)) == m` |

### Extension tests
All custom extensions on `String`, `DateTime`, `BuildContext`, etc.

## Widget tests

### Page tests
| Scenario | Method |
|---|---|
| Loading | pump with BLoC Loading → find `AppLoadingPage` |
| Loaded | pump with BLoC Loaded → find expected widgets |
| Error | pump with BLoC Error → find `AppErrorPage` |
| Retry | in error, tap "Try Again" → verify event dispatched |
| Interaction | tap buttons / enter text → verify BLoC events |

### Component tests
| Test | Verify |
|---|---|
| Renders | expected children |
| Props | different values → different output |
| Loading | `isLoading` shows spinner |
| Disabled | `null` callback disables interaction |
| Theme compliance | uses theme colors (not hardcoded) |

### Test helpers

**`test/helpers/pump_app.dart`** — wraps any widget in required providers:
```
pumpApp(tester, widget)
  → MaterialApp
    → MultiBlocProvider (mock BLoCs)
      → Theme (test theme)
        → widget
```

Must include localization delegates for widgets that display localized text:
```dart
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<BlocProvider>? providers,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: providers != null
          ? MultiBlocProvider(providers: providers, child: widget)
          : widget,
    ),
  );
}
```

**`test/helpers/mock_generators.dart`** — `mockEntity()`, `mockCollection()`, `mockException()`.

## Integration tests

**Directory:** `test/integration/`.

### Primary user flow
1. Launch.
2. Auth check completes.
3. Home/list loads.
4. Open detail/editing flow.
5. Perform core action.
6. Persist or sync.
7. Updated state visible after navigation/reload.

### Offline flow
1. Start with cached data.
2. Simulate offline (`ConnectivityService` returns false).
3. Banner appears.
4. Navigate to cached book → loads from Drift.
5. Add bookmark → saved locally.
6. Restore connectivity → verify sync.

## Mocking with mocktail

No codegen. Declare inline or in `test/helpers/mock_generators.dart`.

### Fakes vs mocks
| Approach | When | Benefit |
|---|---|---|
| **Mock** (mocktail `Mock`) | verify interactions (called? with what args?) | precise call verification |
| **Fake** (hand-written impl) | deterministic state for ViewModels/Views | predictable, easier to reason about |

**Rule:** prefer **Fakes** for repositories when testing BLoCs/widgets — predictable state without stubbing every method. Use **Mocks** to verify method calls (e.g., analytics events fire).

```dart
class FakeLibraryRepository implements LibraryRepository {
  final List<Book> books;
  FakeLibraryRepository({this.books = const []});

  @override
  Future<Either<AppException, List<Book>>> getBooks({required int page}) async =>
    right(books);
}

class MockAnalyticsService extends Mock implements AnalyticsService {}
```

### What gets mocked
| Layer | How | Mocked for |
|---|---|---|
| Use Cases | `MockGetBooksUseCase extends Mock implements GetBooksUseCase` | BLoC tests |
| Repositories | Fake or Mock | Use case + widget tests |
| Data Sources | `MockLibraryRemoteDataSource ...` | Repository tests |
| HttpClient | `MockHttpClient extends Mock implements HttpClient` | Data source tests |
| Services | `MockConnectivityService ...` | various |

## LayoutBuilder testing

Responsive layouts:

| Test | Size | Verify |
|---|---|---|
| Mobile | 400×800 | single column, full-width cards |
| Tablet | 800×1024 | two-column |
| Desktop | 1400×900 | three-column |

Use `tester.view.physicalSize` + `devicePixelRatio` to set dimensions. **Must** call `addTearDown(tester.view.reset)` to clean up.

## Test fixtures

**Directory:** `test/fixtures/` — JSON sample API responses.

| File | Contents |
|---|---|
| `item_response.json` | single domain object |
| `items_list_response.json` | paginated list |
| `detail_response.json` | detail payload |
| `auth_response.json` | login response with tokens |
| `error_response.json` | standard error |

```dart
final json = jsonDecode(File('test/fixtures/item_response.json').readAsStringSync());
```

## Coverage target

| Area | Min coverage |
|---|---|
| Core (json, network, error) | 90% |
| Domain (use cases, entities) | 95% |
| Data (repos, models) | 85% |
| Presentation (BLoCs) | 90% |
| Presentation (widgets) | 70% |
| Overall | 80% |

`flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`.

## Integration test setup

**Package:**
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

**Directory:**
```
integration_test/
├── app_test.dart
└── helpers/test_app.dart
```

**Running:**
| Platform | Command |
|---|---|
| Mobile | `flutter test integration_test/app_test.dart` |
| Web | `chromedriver --port=4444` then `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome` |

**Example:**
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login flow', (final tester) async {
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'Test1234');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
```
