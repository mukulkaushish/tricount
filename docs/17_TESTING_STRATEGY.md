# 17 - Testing Strategy

## Test Pyramid

```
        ╱  Integration  ╲        ← Few: full user flows
       ╱    (E2E)         ╲
      ╱───────────────────╲
     ╱   Widget Tests       ╲    ← Medium: pages, components
    ╱─────────────────────────╲
   ╱      Unit Tests            ╲ ← Many: BLoCs, UseCases, Repos, Parsing
  ╱───────────────────────────────╲
```

| Layer | Count Target | Speed | What It Tests |
|-------|-------------|-------|---------------|
| Unit | ~70% of tests | < 1s each | BLoCs, Use Cases, Repositories, JsonParser, Extensions |
| Widget | ~20% of tests | < 3s each | Pages render correctly, user interactions, error/loading states |
| Integration | ~10% of tests | < 30s each | Full user flows across multiple screens |

---

## Unit Tests

### BLoC Tests (using `bloc_test`)

**Pattern**: For every BLoC, test every event → state sequence.

| Test Category | What to Verify |
|---------------|---------------|
| Initial state | BLoC starts with expected initial state |
| Happy path | Event → [Loading, Loaded(data)] |
| Error path | Event → [Loading, Error(failure)] |
| Multiple events | Correct state sequence for event chains |
| Debounce/throttle | Transformer behavior (e.g., search debounce) |

**Mocking**: Mock Use Cases with `mocktail` - no code generation needed.

### Use Case Tests

| Test Category | What to Verify |
|---------------|---------------|
| Delegation | Use case calls correct repository method |
| Return mapping | `Either` result is passed through correctly |
| Business logic | Any transformation/validation the use case performs |

### Repository Tests

| Test Category | What to Verify |
|---------------|---------------|
| Remote success | API call → DTO parsed → entity returned as Right |
| Remote failure | API exception → `AppException` returned as Left |
| Cache fallback | Remote fails → local cache returned |
| Cache update | Remote success → local cache updated |

**Mocking**: Mock both `RemoteDataSource` and `LocalDataSource`.

### JsonParser Tests

| Test Category | What to Verify |
|---------------|---------------|
| Valid parsing | Correct types extracted from well-formed JSON |
| Missing required field | `DataMismatchException` thrown with correct `fieldName` |
| Wrong type | `DataMismatchException` with descriptive message |
| Null optionals | Returns null without throwing |
| Type coercion | String "123" → int 123, etc. |
| Round-trip | `fromJson(toJson(model))` equals original |

### Extension Tests

Test all custom extensions on `String`, `DateTime`, `BuildContext`, etc.

---

## Widget Tests

### Page Tests

For every page, test:

| Scenario | Method |
|----------|--------|
| Loading state | Pump page with BLoC in `Loading` state → find `AppLoadingPage` |
| Loaded state | Pump page with BLoC in `Loaded` state → find expected widgets |
| Error state | Pump page with BLoC in `Error` state → find `AppErrorPage` |
| Retry | In error state, tap "Try Again" → verify event dispatched to BLoC |
| User interaction | Tap buttons, enter text → verify BLoC events |

### Component Tests

For every shared widget:

| Test | What to Verify |
|------|---------------|
| Renders correctly | Finds expected child widgets |
| Props work | Different prop values produce different output |
| Loading state | `isLoading` shows spinner |
| Disabled state | `null` callback disables interaction |
| Theme compliance | Uses theme colors (not hardcoded) |

### Test Helpers

**File**: `test/helpers/pump_app.dart`

A helper that wraps any widget in the required providers:

```
pumpApp(tester, widget)
  → MaterialApp
    → MultiBlocProvider (with mock BLoCs)
      → Theme (test theme)
        → widget
```

**File**: `test/helpers/mock_generators.dart`

Shared mock factories:
- `mockBook()` → returns a `Book` entity with defaults
- `mockChapter()` → returns a `Chapter` entity
- `mockException()` → returns a `ServerException()` (AppException subtype)

---

## Integration Tests

**Directory**: `test/integration/`

### Reading Flow Test

End-to-end test of the core reading journey:

1. App launches → Splash screen appears
2. Auth check → redirects to Library (with mock auth)
3. Library loads → books displayed
4. Tap a book → Book Detail page
5. Tap "Read" → Reader page opens
6. Reader loads chapter content
7. Scroll → reading progress saved
8. Tap bookmark → bookmark created
9. Navigate back → library shows progress indicator

### Offline Flow Test

1. Start with cached data
2. Simulate offline (`ConnectivityService` returns false)
3. Verify connectivity banner appears
4. Navigate to cached book → loads from Drift
5. Add bookmark → saved locally
6. Restore connectivity
7. Verify sync happens

---

## Mocking with mocktail

No code generation needed. Declare mock classes inline or in `test/helpers/mock_generators.dart`.

### Fakes vs Mocks

| Approach | When to Use | Benefit |
|----------|-------------|---------|
| **Mock** (mocktail `Mock`) | Verifying interactions (was method called? with what args?) | Precise call verification |
| **Fake** (hand-written impl) | Providing deterministic state for ViewModels/Views | Well-defined inputs, easier to reason about |

**Rule**: Prefer **Fakes** for repositories when testing BLoCs and widgets — they give you predictable state without stubbing every method. Use **Mocks** when you need to verify *that* a method was called (e.g., verifying analytics events fire).

```dart
// Fake — returns controlled data, no stubbing needed:
class FakeLibraryRepository implements LibraryRepository {
  final List<Book> books;
  FakeLibraryRepository({this.books = const []});

  @override
  Future<Either<AppException, List<Book>>> getBooks({required int page}) async =>
    right(books);
}

// Mock — for verifying interactions:
class MockAnalyticsService extends Mock implements AnalyticsService {}
```

### What Gets Mocked

| Layer | How | Mocked For |
|-------|-----|-----------|
| Use Cases | `class MockGetBooksUseCase extends Mock implements GetBooksUseCase {}` | BLoC tests |
| Repositories | `class FakeLibraryRepository implements LibraryRepository {...}` or Mock | Use Case tests, Widget tests |
| Data Sources | `class MockLibraryRemoteDataSource extends Mock implements LibraryRemoteDataSource {}` | Repository tests |
| HttpClient | `class MockHttpClient extends Mock implements HttpClient {}` | Data source tests |
| Services | `class MockConnectivityService extends Mock implements ConnectivityService {}` | Various |

Using `mocktail` for Mocks — no code generation needed. Declare mock/fake classes in `test/helpers/`.

---

## LayoutBuilder Testing

For responsive layout testing:

| Test | Screen Size | Verify |
|------|------------|--------|
| Mobile layout | 400 x 800 | Single column, full-width cards |
| Tablet layout | 800 x 1024 | Two-column layout |
| Desktop layout | 1400 x 900 | Three-column layout |

Use `tester.binding.window.physicalSizeTestValue` to set screen dimensions in widget tests.

---

## Test Fixtures

**Directory**: `test/fixtures/`

JSON files containing sample API responses:

| File | Contents |
|------|----------|
| `book_response.json` | Single book JSON object |
| `books_list_response.json` | Paginated list of books |
| `chapter_response.json` | Chapter content JSON |
| `auth_response.json` | Login response with tokens |
| `error_response.json` | Standard error response |

Loaded in tests via:
```dart
final json = jsonDecode(File('test/fixtures/book_response.json').readAsStringSync());
```

---

## Coverage Target

| Area | Minimum Coverage |
|------|-----------------|
| Core (json, network, error) | 90% |
| Domain (use cases, entities) | 95% |
| Data (repositories, models) | 85% |
| Presentation (BLoCs) | 90% |
| Presentation (widgets) | 70% |
| Overall | 80% |

Run coverage: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

---

## Integration Test Setup

### Package

Add to `pubspec.yaml` dev_dependencies:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

### Directory

```
integration_test/
├── app_test.dart          # Full user flow tests
└── helpers/
    └── test_app.dart      # App bootstrap with test config
```

### Running

| Platform | Command |
|----------|---------|
| Mobile (device/emulator) | `flutter test integration_test/app_test.dart` |
| Web (Chrome) | `chromedriver --port=4444` then `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome` |

### Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login flow', (final tester) async {
    await tester.pumpWidget(const TestApp());
    await tester.pumpAndSettle();

    // Find login fields
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'Test1234');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify navigation to home
    expect(find.text('Home'), findsOneWidget);
  });
}
```

### Widget Test Helpers with Localization

The `pumpApp` helper must include localization delegates for widgets that display localized text:

```dart
// test/helpers/pump_app.dart
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
