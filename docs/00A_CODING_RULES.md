# 00A - Coding Rules & Lint Configuration

> **Read this BEFORE writing any code.** Every file, every PR, every commit must pass these rules. No exceptions.

---

## Linting: very_good_analysis

The project uses `very_good_analysis` as the single source of lint rules. This is the strictest widely-adopted Flutter lint set, maintained by Very Good Ventures.

### Setup

**analysis_options.yaml** (project root):

```yaml
include: package:very_good_analysis/analysis_options.10.2.0.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.gr.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    # Project-specific overrides (only if justified):
    # public_member_api_docs: false  # Enable once stable API is defined
```

**pubspec.yaml** (dev_dependencies):

```yaml
dev_dependencies:
  very_good_analysis: ^10.2.0
```

### What very_good_analysis Enforces

This replaces `flutter_lints`. Key rules it enables beyond the defaults:

| Rule | What It Enforces |
|------|-----------------|
| `prefer_const_constructors` | Use `const` wherever possible |
| `prefer_const_declarations` | Declare constants as `const` |
| `prefer_single_quotes` | Single quotes for strings |
| `always_use_package_imports` | `package:<app_package>/...` not relative `../` |
| `avoid_dynamic_calls` | No calling methods on `dynamic` |
| `lines_longer_than_80_chars` | Line length limit (warning) |
| `prefer_final_locals` | Local variables should be `final` |
| `prefer_final_parameters` | Function parameters should be `final` |
| `cascade_invocations` | Use cascades `..` when chaining |
| `unawaited_futures` | Must await or explicitly mark `unawaited()` |
| `sort_constructors_first` | Constructors before methods in class body |
| `public_member_api_docs` | Document all public API members |
| `avoid_print` | Use `AppLogger` instead of `print()` |
| `no_default_cases` | Exhaustive switch statements |
| `unnecessary_lambdas` | Use tear-offs instead of `(x) => fn(x)` |
| `prefer_expression_function_bodies` | Use `=>` for single-expression functions |

---

## Dart & Flutter Conventions

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Classes, enums, typedefs | `PascalCase` | `BookModel`, `RequestMethod` |
| Files | `snake_case` | `book_model.dart`, `http_client.dart` |
| Variables, functions, parameters | `camelCase` | `bookTitle`, `fetchBooks()` |
| Constants | `camelCase` (not SCREAMING_CASE) | `maxRetryCount`, `defaultTimeout` |
| Private members | `_camelCase` | `_dio`, `_handleError()` |
| Enum values | `camelCase` | `RequestMethod.get` |

### File Organization (within a file)

Order members in this sequence:

1. Static constants / fields
2. Final fields
3. Constructors (unnamed first, then named)
4. Factory constructors
5. Public methods
6. Private methods
7. `@override` methods last

### Import Organization

Order imports in this sequence (separated by blank lines):

1. `dart:` libraries
2. `package:flutter/` imports
3. `package:` third-party imports
4. `package:<app_package>/` project imports

Within each group, sort alphabetically. `very_good_analysis` enforces this via `directives_ordering`.

---

## Code Style Rules

### 1. Immutability First

- All model fields are `final`
- BLoC states extend `Equatable` with immutable fields
- Use `const` constructors wherever possible
- Use `final` for all local variables and parameters

### 2. No Inline Themes

```
// WRONG:
Text('Hello', style: TextStyle(fontSize: 16, color: Colors.blue))

// RIGHT:
Text('Hello', style: context.textTheme.bodyLarge)
```

No widget may construct `TextStyle`, `Color`, `BoxDecoration`, or similar directly. Always reference the theme via BuildContext extensions.

### 3. No Magic Numbers

```
// WRONG:
SizedBox(height: 16)
Padding(padding: EdgeInsets.all(24))
BorderRadius.circular(8)

// RIGHT:
SizedBox(height: AppDimensions.spacingM)
Padding(padding: AppDimensions.paddingL)
BorderRadius.circular(AppDimensions.radiusS)
```

Define all spacing, padding, radius, and elevation values in `AppDimensions`.

### 4. No Print Statements

```
// WRONG:
print('Error: $e');
debugPrint('Loaded $count items');

// RIGHT:
logger.error('Error', e);
logger.debug('Loaded $count items');
```

`very_good_analysis` enforces `avoid_print`. Use `AppLogger` everywhere.

### 5. Exhaustive Pattern Matching

```
// WRONG:
switch (state) {
  case Loading():
    return spinner;
  default:
    return container;
}

// RIGHT:
switch (state) {
  case Initial():
    return empty;
  case Loading():
    return spinner;
  case Loaded(:final data):
    return content(data);
  case Error(:final failure):
    return errorPage(failure);
}
```

No `default` cases in switches over sealed classes or enums. Handle every variant explicitly.

### 6. Single-Purpose Functions

- Functions should do one thing
- Max ~20 statements per function
- If a function needs a comment explaining what a section does, extract that section

### 7. No Deep Nesting

Maximum 3 levels of widget nesting in a single `build()` method. Extract named widgets:

```
// WRONG: 5+ levels deep in one build()
Column(children: [
  Container(child: Row(children: [
    Expanded(child: Column(children: [
      Padding(child: Text(...))
    ]))
  ]))
])

// RIGHT: Extract into named widgets
Column(children: [
  _BookHeader(book: book),
  _BookContent(chapters: chapters),
])
```

### 8. Package Imports Only

```
// WRONG:
import '../../../core/network/http_client.dart';

// RIGHT:
import 'package:<app_package>/core/network/http_client.dart';
```

`very_good_analysis` enforces `always_use_package_imports`.

### 9. Final Parameters

```
// WRONG:
Future<void> fetchBooks(String query, int page) async { ... }

// RIGHT:
Future<void> fetchBooks(final String query, final int page) async { ... }
```

All function parameters are `final`. `very_good_analysis` enforces `prefer_final_parameters`.

### 10. Trailing Commas

Always use trailing commas for multi-line argument lists. This improves diffs and auto-formatting:

```
// RIGHT:
const BookCard(
  title: 'Flutter',
  author: 'Google',
  onTap: _handleTap,
)
```

---

## Barrel Files

Every folder with 2+ public Dart files must have a barrel file named `<folder_name>.dart`. Barrel files contain ONLY `export` statements.

**Full rules, examples, and import patterns** → [02_PROJECT_STRUCTURE.md](02_PROJECT_STRUCTURE.md#barrel-file-convention)

Quick reference:
- Cross-module imports go through barrels: `import 'package:<app_package>/core/core.dart';`
- Within the same module, direct imports are fine
- Never export generated files (`*.g.dart`, `*.gr.dart`)
- Feature barrels export domain + presentation only (`data/` is internal)

---

## Architecture Rules

**Full layer rules, dependency diagram, and patterns** → [01_ARCHITECTURE_OVERVIEW.md](01_ARCHITECTURE_OVERVIEW.md)

Quick reference:

| Rule | Detail |
|------|--------|
| Presentation → Domain + Core only | Never import `data/` |
| Domain → pure Dart | No Flutter imports |
| BLoCs → Use Cases → Repositories | Never skip layers |
| Analytics from BLoCs only | Never from widgets |
| Repositories → `HttpClient` interface | Never Dio directly |

---

## Commit Rules

| Rule | Enforcement |
|------|-------------|
| All code passes `flutter analyze` with zero warnings | CI gate |
| All code passes `dart format` check | CI gate |
| All tests pass | CI gate |
| No `// ignore:` directives without a comment explaining why | Code review |
| Generated files are committed (no build_runner in CI for analysis) | Convention |

---

## Pre-Commit Checklist

Before every commit, run:

```bash
dart format .
flutter analyze
flutter test
```

Or use the `Makefile` shortcut: `make ci`

These three commands must pass with zero warnings and zero failures.
