# 00A — Coding Rules & Lint

> Read before writing code. Every file must pass.

## Lint: very_good_analysis

**analysis_options.yaml:**
```yaml
include: package:very_good_analysis/analysis_options.10.2.0.yaml
analyzer:
  exclude: ["**/*.g.dart", "**/*.gr.dart", "**/*.freezed.dart"]
  errors:
    invalid_annotation_target: ignore
```
**pubspec:** `very_good_analysis: ^10.2.0` (dev). Replaces `flutter_lints`.

Key rules enabled: `prefer_const_constructors`, `prefer_const_declarations`, `prefer_single_quotes`, `always_use_package_imports`, `avoid_dynamic_calls`, `lines_longer_than_80_chars`, `prefer_final_locals`, `prefer_final_parameters`, `cascade_invocations`, `unawaited_futures`, `sort_constructors_first`, `public_member_api_docs`, `avoid_print`, `no_default_cases`, `unnecessary_lambdas`, `prefer_expression_function_bodies`, `directives_ordering`.

## Naming

| Element | Convention | Example |
|---|---|---|
| Classes/enums/typedefs | `PascalCase` | `BookModel` |
| Files | `snake_case` | `http_client.dart` |
| Vars/fns/params | `camelCase` | `fetchBooks()` |
| Constants | `camelCase` (not SCREAMING) | `maxRetryCount` |
| Private | `_camelCase` | `_dio` |
| Enum values | `camelCase` | `RequestMethod.get` |

## File member order
1. static const/fields → 2. final fields → 3. constructors (unnamed → named) → 4. factory → 5. public methods → 6. private methods → 7. `@override` last.

## Import order (blank line between groups, alpha within)
1. `dart:` → 2. `package:flutter/` → 3. `package:` third-party → 4. `package:<app>/` project.

## Code style rules

1. **Immutability** — all model fields `final`; BLoC states extend `Equatable`; `const` everywhere possible; `final` locals + params.
2. **No inline themes** — never construct `TextStyle`/`Color`/`BoxDecoration` at call site. Use `context.textTheme.*`, `context.colorScheme.*`.
3. **No magic numbers** — all spacing/padding/radius/elevation via `AppDimensions`.
4. **No print / debugPrint** — use `AppLogger` (`logger.debug/info/warn/error`).
5. **Exhaustive switch** — no `default:` over sealed classes/enums; handle every variant.
6. **Single-purpose fns** — ~20 statements max; if a section needs a comment, extract it.
7. **Max 3 widget nesting levels** per `build()`; extract named private widgets.
8. **Package imports only** — no `../`; cross-module imports go via barrels (`core/core.dart`, not leaf files).
9. **Final parameters** — every param `final`.
10. **Trailing commas** on multi-line arg lists.

## Barrels
Folder with **≥ 3 public files** must have `<folder>.dart` (exports only). Cross-module = via barrel. Feature barrels export `domain/` + `presentation/` only — never `data/`. Never export `*.g.dart` / `*.gr.dart`. Full rules → `02_PROJECT_STRUCTURE.md`.

## Architecture quick-ref (full → `01_ARCHITECTURE_OVERVIEW.md`)

| Rule | Detail |
|---|---|
| Presentation → Domain + Core only | Never `data/` |
| Domain → pure Dart | No Flutter imports |
| BLoCs → Use Cases → Repositories | Never skip |
| Analytics from BLoCs only | Never widgets |
| Repositories → `HttpClient` interface | Never `Dio` |

## Commit gates (CI)
- `flutter analyze` — zero warnings
- `dart format` — clean
- `flutter test` — green
- No `// ignore:` without reason comment
- Generated files committed

## Pre-commit
```bash
dart format . && flutter analyze && flutter test
```
Or `make ci`.
