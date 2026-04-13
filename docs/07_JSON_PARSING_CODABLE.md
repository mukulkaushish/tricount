# 07 - JSON Parsing & Codable System

## Overview

The app uses a single `JsonParser` mixin that serves as the complete codable system — providing both deserialization (type-safe field extraction) and serialization (null-stripping `toJson`). Inspired by Swift's Codable protocol. No code generation needed.

Two components:
1. **`JsonCodable`** - interface that all DTOs implement (`fromJson` factory + `toJson` method)
2. **`JsonParser`** - mixin with static helpers used inside `fromJson`/`toJson` implementations

---

## JsonCodable Interface

**File**: `lib/core/json/codable.dart`

```
abstract class JsonCodable {
  Map<String, dynamic> toJson();
}
```

Every DTO model in the `data/models/` layer implements `JsonCodable` and provides:
- A `factory Model.fromJson(Map<String, dynamic> json)` constructor
- A `toJson()` method returning `Map<String, dynamic>`

### Contract

| Method | Purpose |
|--------|---------|
| `fromJson(Map<String, dynamic>)` | Factory constructor - deserialize from JSON |
| `toJson()` | Serialize to JSON map |

### Rules

1. `fromJson` uses `JsonParser` methods for every field extraction
2. `toJson` uses `JsonParser.toJson()` to strip nulls and serialize nested objects
3. Models are in `data/models/`, never in `domain/entities/`
4. Models may extend domain entities or map to them via a `.toEntity()` method

---

## JsonParser Mixin

**File**: `lib/core/json/json_parser.dart`

This mixin (provided in full by the user) provides type-safe parsing with clear error messages via `DataMismatchException`.

### Available Methods

All methods are `static` — called as `JsonParser.parseString(json, key)`.

#### Primitive Types

| Method | Returns | Behavior |
|--------|---------|----------|
| `parseString(json, key)` | `String` | Throws if missing/null/wrong type |
| `parseStringOptional(json, key)` | `String?` | Returns null if missing/wrong |
| `parseInt(json, key)` | `int` | Handles int, double (if whole), string parsing |
| `parseIntOptional(json, key)` | `int?` | Returns null if missing/wrong |
| `parseDouble(json, key)` | `double` | Handles double, int, string parsing |
| `parseDoubleOptional(json, key)` | `double?` | Returns null if missing/wrong |
| `parseBool(json, key)` | `bool` | Handles bool, string ("true"/"false"/"1"/"0"), int (0/non-zero) |
| `parseBoolOptional(json, key)` | `bool?` | Returns null if missing/wrong |

#### Typed List Parsing

| Method | Returns | Behavior |
|--------|---------|----------|
| `parseStringList(json, key)` | `List<String>` | Throws on null items, converts non-strings via `.toString()` |
| `parseStringListOptional(json, key)` | `List<String>?` | Returns null if missing |
| `parseIntList(json, key)` | `List<int>` | Handles int, double (if whole), string items |
| `parseIntListOptional(json, key)` | `List<int>?` | Returns null if missing |
| `parseDoubleList(json, key)` | `List<double>` | Handles double, int, string items |
| `parseDoubleListOptional(json, key)` | `List<double>?` | Returns null if missing |
| `parseBoolList(json, key)` | `List<bool>` | Handles bool, string, int items |
| `parseBoolListOptional(json, key)` | `List<bool>?` | Returns null if missing |

#### Object & Generic List Parsing

| Method | Returns | Behavior |
|--------|---------|----------|
| `parseList<T>(json, key, fromJson)` | `List<T>` | Parses list of objects using factory |
| `parseListOptional<T>(json, key, fromJson)` | `List<T>?` | Returns null if missing |
| `parseObject<T>(json, key, fromJson)` | `T` | Parses nested object using factory |
| `parseObjectOptional<T>(json, key, fromJson)` | `T?` | Returns null if missing |

#### Serialization & Utilities

| Method | Returns | Behavior |
|--------|---------|----------|
| `toJson(fields)` | `Map<String, dynamic>` | Strips null values, serializes nested objects recursively |
| `validateRequiredFields(json, fields)` | `void` | Throws if any required field is missing/null |
| `hasKey(json, key)` | `bool` | Check if key exists in map |
| `getKeys(json)` | `Set<String>` | Returns all keys in the map |

---

## DataMismatchException

> Full `AppException` hierarchy is defined in [14_ERROR_HANDLING.md](14_ERROR_HANDLING.md). `DataMismatchException` is the JSON-specific subtype relevant here.

Used by `JsonParser` when a field is missing, null (when required), or the wrong type.

| Field | Type | Purpose |
|-------|------|---------|
| `message` | `String` | Human-readable description |
| `fieldName` | `String` | The JSON key that failed |

This exception is a subtype of `AppException` and flows through `Either` unchanged — no mapping needed.

---

## Model Implementation Pattern

Every model follows this exact pattern:

### Required Elements

1. **Class declaration**: `class BookModel extends Book implements JsonCodable`
   - Extends the domain entity
   - Implements `JsonCodable`

2. **Constructor**: Standard Dart constructor with named parameters

3. **fromJson factory**: Uses ONLY `JsonParser` methods - no manual `json['key']` access

4. **toJson method**: Uses `JsonParser.toJson()` for null-stripping and nested serialization

5. **toEntity method** (if not extending entity): Converts to domain entity

### Model-to-Entity Relationship

Two strategies (choose one per model):

**Strategy A: Model extends Entity**
- Model class extends the domain entity
- `fromJson` creates the model directly
- Domain layer works with the entity type; data layer uses the model

**Strategy B: Separate classes with mapper**
- Model is standalone with `toEntity()` and `fromEntity()` methods
- Better when entities have behavior/methods
- Repository calls `.toEntity()` before returning to domain

**Rule**: Choose Strategy A for simple data carriers, Strategy B for entities with business logic.

---

## Validation Pattern

For models with complex validation, use `validateRequiredFields` before parsing:

**Order**:
1. Call `JsonParser.validateRequiredFields(json, ['id', 'title', 'author'])`
2. Parse each field with the appropriate `JsonParser` method
3. Any failure throws `DataMismatchException` with the exact field that failed

**Where validation happens**:
- `fromJson` validates structural correctness (types, required fields)
- Domain entity validates business rules (non-empty title, valid ISBN)
- Repository passes `DataMismatchException` through as `Either` Left (no mapping)

---

## Example Model Specification (BookModel)

**File**: `lib/features/library/data/models/book_model.dart`

| JSON Key | Field | Type | Required | Parser Method |
|----------|-------|------|----------|--------------|
| `id` | `id` | `String` | Yes | `parseString` |
| `title` | `title` | `String` | Yes | `parseString` |
| `author` | `author` | `String` | Yes | `parseString` |
| `cover_url` | `coverUrl` | `String?` | No | `parseStringOptional` |
| `description` | `description` | `String?` | No | `parseStringOptional` |
| `page_count` | `pageCount` | `int` | Yes | `parseInt` |
| `rating` | `rating` | `double?` | No | `parseDoubleOptional` |
| `categories` | `categories` | `List<String>` | Yes | `parseStringList` |
| `is_premium` | `isPremium` | `bool` | Yes | `parseBool` |
| `chapters` | `chapters` | `List<ChapterModel>?` | No | `parseListOptional` with `ChapterModel.fromJson` |

---

## Background Parsing for Large Payloads

When a JSON response contains 500+ items (e.g., paginated list responses with large pages, batch sync payloads), parsing on the main isolate can cause frame drops (>16ms).

### When to Use Background Parsing

| Payload Size | Strategy |
|-------------|----------|
| < 100 items | Parse inline (main isolate) |
| 100-500 items | Parse inline, monitor with DevTools |
| 500+ items | Use `compute()` to parse in background isolate |

### Implementation

The parsing function must be **top-level** or **static** (isolates cannot capture closures):

```dart
// Top-level function — required for compute()
List<BookModel> parseBooks(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List<Object?>)
      .cast<Map<String, Object?>>();
  return parsed.map(BookModel.fromJson).toList();
}

// In repository:
final response = await httpClient.requestRaw('/v1/books');
final books = await compute(parseBooks, response.body);
```

**Rule**: Only use `compute()` when profiling confirms jank. The isolate spawn overhead (~2ms) makes it wasteful for small payloads.

---

## Testing JSON Parsing

Each model's `fromJson` and `toJson` must be tested with:

1. **Happy path**: Valid JSON → correct model fields
2. **Missing required field**: Throws `DataMismatchException` with correct `fieldName`
3. **Wrong type**: e.g., `int` where `String` expected → throws with descriptive message
4. **Null optional field**: Returns null, does not throw
5. **Round-trip**: `Model.fromJson(model.toJson())` equals original model
6. **Edge cases**: Empty strings, zero values, empty lists, epoch timestamps

Test fixtures live in `test/fixtures/` as `.json` files.
