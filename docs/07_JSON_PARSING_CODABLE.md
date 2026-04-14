# 07 - JSON Parsing & Codable System

> Example DTOs and payloads in this document are illustrative. Replace them with the fields and models that match your domain.

## Overview

The app uses a single `JsonParser` mixin that serves as the complete codable system — providing both deserialization (type-safe field extraction) and serialization (null-stripping `toJson`). Inspired by Swift's Codable protocol. No code generation needed.

Two components:

1. **`JsonCodable`** — interface that all DTOs implement (`fromJson` factory + `toJson` method)
2. **`JsonParser`** — mixin with static helpers used inside `fromJson`/`toJson` implementations

---

## JsonCodable Interface

**File**: `lib/core/json/codable.dart`

```dart
abstract class JsonCodable {
  Map<String, dynamic> toJson();
}
```

Every DTO model in the `data/models/` layer implements `JsonCodable` and provides:

- A `factory Model.fromJson(Map<String, dynamic> json)` constructor
- A `toJson()` method returning `Map<String, dynamic>`

| Method | Purpose |
|--------|---------|
| `fromJson(Map<String, dynamic>)` | Factory constructor — deserialize from JSON |
| `toJson()` | Serialize to JSON map |

**Rules:**

1. `fromJson` uses `JsonParser` static methods for every field — never direct `json['key']` access
2. `toJson` uses `JsonParser.toJson()` for null-stripping and nested serialization
3. Models live in `data/models/`, never in `domain/entities/`
4. Models map to domain entities via extension/inheritance (see Model-to-Entity section)

---

## JsonParser Mixin

**File**: `lib/core/json/json_parser.dart`

Declared as `mixin JsonParser` but all methods are `static` — no instance state. You do **not** need to apply the mixin to a class to call these methods; use them directly as `JsonParser.parseString(json, key)`. The mixin declaration exists so classes can optionally `with JsonParser` for convenience.

`DataMismatchException` is imported from `network_exception.dart` (part of the error layer). It is a subtype of `AppException` — see [14_ERROR_HANDLING.md](14_ERROR_HANDLING.md).

---

### Primitive parsers

All required variants throw `DataMismatchException` when the field is missing, null, or cannot be coerced. Optional variants return `null` in those cases.

#### `parseString` / `parseStringOptional`

| Input type | Behavior |
|---|---|
| `String` | Returned as-is |
| `null` | Required: throws. Optional: returns `null` |
| Any other type | Required: throws. Optional: returns `null` (no `.toString()` coercion on scalar fields) |

#### `parseInt` / `parseIntOptional`

| Input type | Behavior |
|---|---|
| `int` | Returned as-is |
| `double` | Converted only if finite AND `value == value.truncateToDouble()` (i.e., no fractional part). Otherwise throws. |
| `String` | Parsed via `int.tryParse`. Throws if `null` result. |
| `null` | Required: throws. Optional: returns `null` |
| Any other type | Throws |

`parseIntOptional` internally creates a temp single-key map and delegates to `parseInt`, returning `null` on any exception.

#### `parseDouble` / `parseDoubleOptional`

| Input type | Behavior |
|---|---|
| `double` | Returned as-is |
| `int` | Widened to `double` via `.toDouble()` |
| `String` | Parsed via `double.tryParse`. Must be finite — throws on `Infinity`/`NaN`. |
| `null` | Required: throws. Optional: returns `null` |
| Any other type | Throws |

#### `parseBool` / `parseBoolOptional`

| Input type | Behavior |
|---|---|
| `bool` | Returned as-is |
| `String` | Case-insensitive: `"true"` / `"1"` → `true`; `"false"` / `"0"` → `false`. Any other string throws. |
| `int` | `0` → `false`, any non-zero → `true` |
| `null` | Required: throws. Optional: returns `null` |
| Any other type | Throws |

---

### Typed list parsers

All list parsers first assert the value is a `List`. Per-item errors include the index in `fieldName` (e.g., `"tags[2]"`) for precise diagnostics.

#### Primitive list variants

| Method | Returns | Per-item coercion |
|---|---|---|
| `parseStringList` / `parseStringListOptional` | `List<String>` / `List<String>?` | Non-string items converted via `.toString()` (unlike scalar `parseString`). Null items throw. |
| `parseIntList` / `parseIntListOptional` | `List<int>` / `List<int>?` | Same coercion rules as `parseInt` per item |
| `parseDoubleList` / `parseDoubleListOptional` | `List<double>` / `List<double>?` | Same coercion rules as `parseDouble` per item |
| `parseBoolList` / `parseBoolListOptional` | `List<bool>` / `List<bool>?` | Same coercion rules as `parseBool` per item |

#### Generic list — `parseList<T>` / `parseListOptional<T>`

```dart
static List<T> parseList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
)
```

Each element must be `Map<String, dynamic>`. If `fromJson` throws, the error is re-wrapped as `DataMismatchException` with `fieldName: '$key[$i]'`.

#### Nested object — `parseObject<T>` / `parseObjectOptional<T>`

```dart
static T parseObject<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
)
```

Value must be `Map<String, dynamic>`. Any exception from `fromJson` is re-wrapped as `DataMismatchException`.

---

### Serialization — `toJson`

```dart
static Map<String, dynamic> toJson(Map<String, dynamic> fields)
```

Pass every field as a key/value map. `toJson` strips `null` values and recursively serializes via `_serializeValue`:

| Value type | Serialized as |
|---|---|
| `String`, `int`, `double`, `bool` | As-is |
| `null` | Key omitted from output |
| `List` | Each element run through `_serializeValue` recursively |
| `Map<String, dynamic>` | Each value run through `_serializeValue` recursively |
| Any object | Attempts to call `.toJson()` dynamically. Falls back to `.toString()` if the call fails. |

> **Note:** The dynamic `.toJson()` detection uses a runtime string check and a `dynamic` cast. It will work for any class that exposes a `toJson()` method, but failures are silently swallowed and fall back to `.toString()`. Prefer passing pre-serialized maps for nested objects rather than relying on this fallback.

---

### Utilities

| Method | Signature | Purpose |
|---|---|---|
| `validateRequiredFields` | `(Map, List<String>) → void` | Throws `DataMismatchException` for the first missing/null field in the list |
| `hasKey` | `(Map, String) → bool` | Returns `true` if the key exists (even if value is `null`) |
| `getKeys` | `(Map) → Set<String>` | Returns all keys in the map |

---

## DataMismatchException

Thrown by `JsonParser` when a field is missing, null when required, or the wrong type.

| Field | Type | Purpose |
|-------|------|---------|
| `message` | `String` | Human-readable description including field name and type mismatch detail |
| `fieldName` | `String` | The JSON key that failed — includes index for list errors (e.g., `"chapters[0]"`) |

Imported from `network_exception.dart`. Flows through `Either` as the Left value unchanged — no mapping needed at repository boundaries.

---

## Model Implementation Pattern

Every model follows this exact pattern:

```dart
// lib/features/auth/data/models/user_model.dart

class UserModel extends User implements JsonCodable {
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

  @override
  Map<String, dynamic> toJson() => JsonParser.toJson({
        'id': id,
        'email': email,
        'display_name': displayName, // omitted if null
      });
}
```

### Model-to-Entity Relationship

| Strategy | When to use | How |
|---|---|---|
| **A — Model extends Entity** | Simple data carriers with no business logic | `class UserModel extends User implements JsonCodable` |
| **B — Separate classes with mapper** | Entities with business methods or complex construction | Standalone `UserModel` + `toEntity()` / `fromEntity()` methods |

Choose Strategy A by default; switch to B when the entity has methods that would be awkward to carry into the model layer.

---

## Validation Order

Inside every `fromJson`:

1. `JsonParser.validateRequiredFields(json, [...])` — fast early fail for missing fields
2. Parse each field with the appropriate `JsonParser` method
3. Any failure throws `DataMismatchException` with the exact field name and mismatch detail

Business rule validation (non-empty values, valid ranges, enum membership) belongs in the **domain entity** constructor, not in `fromJson`.

---

## Type coercion quick reference

| Parser | Accepts | Rejects |
|---|---|---|
| `parseString` | `String` | `int`, `double`, `bool`, `null` (throws) |
| `parseInt` | `int`, whole `double`, numeric `String` | fractional `double`, non-numeric `String` |
| `parseDouble` | `double`, `int`, finite numeric `String` | `Infinity`, `NaN`, non-numeric `String` |
| `parseBool` | `bool`, `"true"/"false"/"1"/"0"` (case-insensitive), `int` (0/nonzero) | other strings |
| `parseStringList` items | `String` (as-is), any other (`.toString()`) | `null` items (throws) |
| `parseIntList` items | Same rules as `parseInt` per item | — |
| `parseDoubleList` items | Same rules as `parseDouble` per item | — |
| `parseBoolList` items | Same rules as `parseBool` per item | — |

---

## Background Parsing for Large Payloads

| Payload Size | Strategy |
|-------------|----------|
| < 100 items | Parse inline on main isolate |
| 100–500 items | Parse inline, monitor with DevTools |
| 500+ items | Use `compute()` — top-level or static function required |

```dart
// Top-level function — required for compute()
List<UserModel> _parseUsers(String responseBody) {
  final list = (jsonDecode(responseBody) as List).cast<Map<String, dynamic>>();
  return list.map(UserModel.fromJson).toList();
}

// In repository:
final users = await compute(_parseUsers, response.body);
```

Only use `compute()` after profiling confirms jank — isolate spawn overhead (~2 ms) is wasteful for small payloads.

---

## Testing JSON Parsing

Each model's `fromJson` and `toJson` must be tested with:

| Case | Assertion |
|---|---|
| Happy path | All fields deserialize to correct types and values |
| Missing required field | `DataMismatchException` thrown, `fieldName` matches the missing key |
| Wrong type | `DataMismatchException` thrown with type description in message |
| Null required field | `DataMismatchException` thrown |
| Null optional field | Returns `null`, no exception |
| Round-trip | `Model.fromJson(model.toJson())` equals original model |
| Type coercion edges | Integer JSON for a `double` field, string `"true"` for a `bool` field, etc. |
| List index errors | `fieldName` includes index (e.g., `"tags[2]"`) on per-item failure |

Test fixtures live in `test/fixtures/` as `.json` files — never inline raw JSON strings in test files.
