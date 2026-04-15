# 07 — JSON Parsing

> DTO examples are illustrative. Replace with real domain types.

## Overview

Single `JsonParser` mixin = entire JSON layer. Type-safe field extraction + null-stripping serialization. **No code generation.**

**File:** `lib/core/network/json_parser.dart` — co-located with network (it parses HTTP bodies). Exported via `network.dart` → available through `core/core.dart`.

> `JsonCodable` has been removed. Models provide `fromJson` factory + `toDomain()` directly without an interface.

## `JsonParser` mixin

Declared `mixin JsonParser` but all methods `static` — no instance state. Call as `JsonParser.parseString(json, key)`. Every method throws `DataMismatchException` on type mismatch / missing required field. `DataMismatchException` is a subtype of `AppException` (→ `14_ERROR_HANDLING.md`).

**Rules for DTOs:**
1. `fromJson` uses `JsonParser` for every field — never direct `json['key']`.
2. `toJson` (if implemented) uses `JsonParser.toJson()` for null-stripping + nested serialization.
3. Models in `data/models/`, never `domain/entities/`.
4. Map to entity via `.toDomain()`.

## Primitive parsers

Required variants throw when missing/null/uncoercible. Optional variants return `null`.

### `parseString` / `parseStringOptional`
| Input | Behavior |
|---|---|
| `String` | as-is |
| `null` | required throws; optional → `null` |
| other type | required throws; optional → `null` (**no `.toString()` coercion on scalar fields**) |

### `parseInt` / `parseIntOptional`
| Input | Behavior |
|---|---|
| `int` | as-is |
| `double` | only if finite AND `value == value.truncateToDouble()` (no fractional part); else throws |
| `String` | `int.tryParse`; throws on null result |
| `null` | required throws; optional → `null` |
| other | throws |

`parseIntOptional` wraps `parseInt` in a temp single-key map and returns `null` on exception.

### `parseDouble` / `parseDoubleOptional`
| Input | Behavior |
|---|---|
| `double` | as-is |
| `int` | widened via `.toDouble()` |
| `String` | `double.tryParse`; must be finite — throws on `Infinity`/`NaN` |
| `null` | required throws; optional → `null` |
| other | throws |

### `parseBool` / `parseBoolOptional`
| Input | Behavior |
|---|---|
| `bool` | as-is |
| `String` | case-insensitive `"true"/"1"` → `true`, `"false"/"0"` → `false`; other strings throw |
| `int` | `0` → `false`, non-zero → `true` |
| `null` | required throws; optional → `null` |
| other | throws |

## Typed list parsers

All assert value is `List`. Per-item errors include index in `fieldName` (e.g. `"tags[2]"`).

### Primitive lists
| Method | Returns | Per-item coercion |
|---|---|---|
| `parseStringList` / `Optional` | `List<String>` / `?` | Non-string items converted via `.toString()` (**unlike scalar `parseString`**). Null items throw. |
| `parseIntList` / `Optional` | `List<int>` / `?` | same rules as `parseInt` per item |
| `parseDoubleList` / `Optional` | `List<double>` / `?` | same rules as `parseDouble` per item |
| `parseBoolList` / `Optional` | `List<bool>` / `?` | same rules as `parseBool` per item |

### Generic list — `parseList<T>` / `parseListOptional<T>`

```dart
static List<T> parseList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
)
```
Each element must be `Map<String, dynamic>`. If `fromJson` throws, rewrapped as `DataMismatchException` with `fieldName: '$key[$i]'`.

### Nested object — `parseObject<T>` / `parseObjectOptional<T>`

```dart
static T parseObject<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
)
```
Value must be `Map<String, dynamic>`. Any `fromJson` exception rewrapped as `DataMismatchException`.

## Serialization — `toJson`

```dart
static Map<String, dynamic> toJson(Map<String, dynamic> fields)
```
Pass every field as key/value. Strips `null` values, recursively serializes via `_serializeValue`:

| Value type | Serialized as |
|---|---|
| primitives (`String`, `int`, `double`, `bool`) | as-is |
| `null` | key omitted |
| `List` | each element recursively |
| `Map<String, dynamic>` | each value recursively |
| any object | attempts `.toJson()` dynamically; falls back to `.toString()` on failure |

> **Note:** dynamic `.toJson()` detection uses a runtime string check + `dynamic` cast. Works for any class with `.toJson()`, but failures are silently swallowed. **Prefer passing pre-serialized maps for nested objects** rather than relying on the fallback.

## Utilities

| Method | Signature | Purpose |
|---|---|---|
| `validateRequiredFields` | `(Map, List<String>) → void` | throws on first missing/null field |
| `hasKey` | `(Map, String) → bool` | true even if value is `null` |
| `getKeys` | `(Map) → Set<String>` | all keys |

## `DataMismatchException`

| Field | Type | Purpose |
|---|---|---|
| `message` | `String` | includes field name + type mismatch detail |
| `fieldName` | `String` | JSON key that failed; includes index for lists (`"chapters[0]"`) |

Imported from `network_exception.dart`. Flows through `Either` as Left unchanged — no mapping at repo boundary.

## Model implementation pattern

```dart
// lib/features/auth/data/models/user_model.dart

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    JsonParser.validateRequiredFields(json, ['id', 'email']);
    return UserModel(
      id: JsonParser.parseString(json, 'id'),
      email: JsonParser.parseString(json, 'email'),
      displayName: JsonParser.parseStringOptional(json, 'display_name'),
    );
  }

  Map<String, dynamic> toJson() => JsonParser.toJson({
    'id': id,
    'email': email,
    'display_name': displayName, // omitted if null
  });
}
```

### Model↔Entity strategies

| Strategy | When | How |
|---|---|---|
| **A — Model extends Entity** | Simple data carrier, no business logic | `class UserModel extends User` |
| **B — Separate + mapper** | Entity has methods / complex construction | standalone `UserModel` + `toEntity()`/`fromEntity()` |

Default to A. Switch to B when entity has methods that would be awkward in the model.

## Validation order in `fromJson`

1. `JsonParser.validateRequiredFields(json, [...])` — fast early fail.
2. Parse each field with appropriate method.
3. Failures throw `DataMismatchException` with exact field name + detail.

**Business rule validation** (non-empty, ranges, enum membership) belongs in the **domain entity constructor**, not `fromJson`.

## Type coercion quick reference

| Parser | Accepts | Rejects |
|---|---|---|
| `parseString` | `String` | `int`/`double`/`bool`/`null` |
| `parseInt` | `int`, whole `double`, numeric `String` | fractional `double`, non-numeric `String` |
| `parseDouble` | `double`, `int`, finite numeric `String` | `Infinity`, `NaN`, non-numeric `String` |
| `parseBool` | `bool`, `"true"/"false"/"1"/"0"` (ci), `int` (0/nonzero) | other strings |
| `parseStringList` items | `String` as-is, other → `.toString()` | `null` items (throw) |
| `parseIntList` / `parseDoubleList` / `parseBoolList` | per-item same as scalar rules | — |

## Background parsing for large payloads

| Size | Strategy |
|---|---|
| < 100 items | parse inline on main isolate |
| 100–500 | parse inline, monitor with DevTools |
| 500+ | `compute()` — top-level / static fn required |

```dart
List<UserModel> _parseUsers(String body) {
  final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
  return list.map(UserModel.fromJson).toList();
}
// In repo:
final users = await compute(_parseUsers, response.body);
```

Only use `compute()` after profiling confirms jank — isolate spawn ~2 ms is wasteful for small payloads.

## Testing

Every `fromJson`/`toJson` tests:

| Case | Assertion |
|---|---|
| Happy path | all fields correct |
| Missing required | `DataMismatchException`, `fieldName` matches |
| Wrong type | `DataMismatchException` with type description |
| Null required | throws |
| Null optional | returns `null`, no exception |
| Round-trip | `Model.fromJson(model.toJson())` equals original |
| Coercion edges | int JSON for double field, string `"true"` for bool, etc. |
| List index errors | `fieldName` includes index (`"tags[2]"`) |

Fixtures live in `test/fixtures/` as `.json` files — never inline JSON strings in tests.
