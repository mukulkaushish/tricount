import 'package:tricount/core/network/app_exception.dart';

/// Utility class for type-safe JSON extraction and serialization.
///
/// All parse methods throw [DataMismatchException] on type errors so failures
/// surface early with the field name, not silently as null values buried deep
/// in the data layer.
///
/// ## Naming convention
/// - `parse<Type>` — required field; throws if missing or wrong type.
/// - `parse<Type>Optional` — optional field; returns null if absent.
///
/// ## Junior guide: adding a new DTO
/// 1. In `fromJson`, call `parse*` for required fields and `parse*Optional`
///    for optional ones.
/// 2. In `toJson`, delegate to `JsonParser.toJson` passing a plain map.
/// 3. Implement `JsonCodable` so the compiler enforces the contract.
///
/// Example:
/// ```dart
/// class BookModel implements JsonCodable {
///   factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
///     id: JsonParser.parseString(json, 'id'),
///     title: JsonParser.parseString(json, 'title'),
///     rating: JsonParser.parseDoubleOptional(json, 'rating'),
///   );
///
///   @override
///   Map<String, dynamic> toJson() => JsonParser.toJson({
///     'id': id,
///     'title': title,
///     'rating': rating,
///   });
/// }
/// ```
abstract final class JsonParser {
  // ── Type casting ───────────────────────────────────────────────────────────

  /// Casts [data] to `List<dynamic>` or throws [DataMismatchException].
  static List<dynamic> castList(
    dynamic data, {
    String context = 'response body',
  }) {
    if (data is List<dynamic>) return data;
    throw DataMismatchException(
      message: 'Expected a JSON list for $context.',
    );
  }

  /// Casts [data] to `Map<String, dynamic>` or throws [DataMismatchException].
  static Map<String, dynamic> castMap(
    dynamic data, {
    String context = 'response body',
  }) {
    if (data is Map<String, dynamic>) return data;
    throw DataMismatchException(
      message: 'Expected a JSON object for $context.',
    );
  }

  // ── Key-path extraction ────────────────────────────────────────────────────

  /// Traverses a dot-notation [keyPath] (e.g. `"data.user"`) on [data].
  ///
  /// Supports both map keys and list indices (e.g. `"items.0.id"`).
  static dynamic extractByKeyPath(dynamic data, String keyPath) {
    if (keyPath.trim().isEmpty) return data;

    final segments = keyPath.split('.');
    var current = data;

    for (final segment in segments) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(segment)) {
          throw DataMismatchException(
            message: 'Missing keyPath segment "$segment" in "$keyPath".',
          );
        }
        current = current[segment];
        continue;
      }

      if (current is List<dynamic>) {
        final index = int.tryParse(segment);
        if (index == null || index < 0 || index >= current.length) {
          throw DataMismatchException(
            message: 'Invalid list index "$segment" in "$keyPath".',
          );
        }
        current = current[index];
        continue;
      }

      throw DataMismatchException(
        message: 'Cannot resolve keyPath "$keyPath" beyond "$segment".',
      );
    }

    return current;
  }

  // ── String ─────────────────────────────────────────────────────────────────

  /// Returns a non-empty string at [key] or throws [DataMismatchException].
  static String parseString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw DataMismatchException(
      message: 'Missing or empty required string for "$key".',
      fieldName: key,
    );
  }

  /// Returns the string at [key], or null if absent / null in the payload.
  static String? parseStringOptional(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value;
    throw DataMismatchException(
      message: 'Expected string for "$key" but got ${value.runtimeType}.',
      fieldName: key,
    );
  }

  // ── Int ────────────────────────────────────────────────────────────────────

  /// Returns the int at [key].
  ///
  /// Coerces whole-number doubles (e.g. `1.0`) and numeric strings (`"42"`).
  static int parseInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        message: 'Missing required int for "$key".',
        fieldName: key,
      );
    }
    if (value is int) return value;
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw DataMismatchException(
      message: 'Expected int for "$key" but got ${value.runtimeType}.',
      fieldName: key,
    );
  }

  /// Returns the int at [key], or null if absent / null in the payload.
  static int? parseIntOptional(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    try {
      return parseInt({key: value}, key);
    } on DataMismatchException {
      return null;
    }
  }

  // ── Double ─────────────────────────────────────────────────────────────────

  /// Returns the double at [key].
  ///
  /// Coerces ints and numeric strings.
  static double parseDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        message: 'Missing required double for "$key".',
        fieldName: key,
      );
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    throw DataMismatchException(
      message: 'Expected double for "$key" but got ${value.runtimeType}.',
      fieldName: key,
    );
  }

  /// Returns the double at [key], or null if absent / null in the payload.
  static double? parseDoubleOptional(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    try {
      return parseDouble({key: value}, key);
    } on DataMismatchException {
      return null;
    }
  }

  // ── Bool ───────────────────────────────────────────────────────────────────

  /// Returns the bool at [key].
  ///
  /// Coerces integers (`0`/non-zero) and strings
  /// (`"true"`/`"false"`/`"1"`/`"0"`).
  static bool parseBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        message: 'Missing required bool for "$key".',
        fieldName: key,
      );
    }
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    throw DataMismatchException(
      message: 'Expected bool for "$key" but got ${value.runtimeType}.',
      fieldName: key,
    );
  }

  /// Returns the bool at [key], or null if absent / null in the payload.
  ///
  /// Uses the same int/string coercion as [parseBool].
  static bool? parseBoolOptional(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    try {
      return parseBool({key: value}, key);
    } on DataMismatchException {
      return null;
    }
  }

  // ── Typed lists ────────────────────────────────────────────────────────────

  /// Decodes a list of strings at [key].
  ///
  /// Non-string scalars are coerced via `toString()`.
  static List<String> parseStringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final raw = _requireList(json, key);
    final result = <String>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item == null) {
        throw DataMismatchException(
          message: 'Null value at "$key[$i]".',
          fieldName: '$key[$i]',
        );
      }
      result.add(item is String ? item : item.toString());
    }
    return result;
  }

  /// Returns the string list at [key], or null if absent / null.
  static List<String>? parseStringListOptional(
    Map<String, dynamic> json,
    String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseStringList(json, key);
    } on DataMismatchException {
      return null;
    }
  }

  /// Decodes a list of ints at [key].
  ///
  /// Applies the same coercion as [parseInt].
  static List<int> parseIntList(Map<String, dynamic> json, String key) {
    final raw = _requireList(json, key);
    final result = <int>[];
    for (var i = 0; i < raw.length; i++) {
      result.add(parseInt({'v': raw[i]}, 'v'));
    }
    return result;
  }

  /// Returns the int list at [key], or null if absent / null.
  static List<int>? parseIntListOptional(
    Map<String, dynamic> json,
    String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseIntList(json, key);
    } on DataMismatchException {
      return null;
    }
  }

  /// Decodes a list of doubles at [key].
  ///
  /// Applies the same coercion as [parseDouble].
  static List<double> parseDoubleList(
    Map<String, dynamic> json,
    String key,
  ) {
    final raw = _requireList(json, key);
    final result = <double>[];
    for (var i = 0; i < raw.length; i++) {
      result.add(parseDouble({'v': raw[i]}, 'v'));
    }
    return result;
  }

  /// Returns the double list at [key], or null if absent / null.
  static List<double>? parseDoubleListOptional(
    Map<String, dynamic> json,
    String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseDoubleList(json, key);
    } on DataMismatchException {
      return null;
    }
  }

  /// Decodes a list of bools at [key].
  ///
  /// Applies the same coercion as [parseBool].
  static List<bool> parseBoolList(Map<String, dynamic> json, String key) {
    final raw = _requireList(json, key);
    final result = <bool>[];
    for (var i = 0; i < raw.length; i++) {
      result.add(parseBool({'v': raw[i]}, 'v'));
    }
    return result;
  }

  /// Returns the bool list at [key], or null if absent / null.
  static List<bool>? parseBoolListOptional(
    Map<String, dynamic> json,
    String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseBoolList(json, key);
    } on DataMismatchException {
      return null;
    }
  }

  // ── Map ────────────────────────────────────────────────────────────────────

  /// Returns the nested object at [key] or throws [DataMismatchException].
  static Map<String, dynamic> parseMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    throw DataMismatchException(
      message: 'Expected object for "$key".',
      fieldName: key,
    );
  }

  /// Returns the nested object at [key], or null if absent / null.
  static Map<String, dynamic>? parseMapOptional(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    throw DataMismatchException(
      message: 'Expected object for "$key" but got ${value.runtimeType}.',
      fieldName: key,
    );
  }

  // ── Object ─────────────────────────────────────────────────────────────────

  /// Decodes a nested object at [key] using [fromJson].
  ///
  /// Throws [DataMismatchException] if the key is missing or the value is not
  /// a JSON object, or if [fromJson] itself throws.
  static T parseObject<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        message: 'Missing required object for "$key".',
        fieldName: key,
      );
    }
    if (value is! Map<String, dynamic>) {
      throw DataMismatchException(
        message: 'Expected object for "$key" but got ${value.runtimeType}.',
        fieldName: key,
      );
    }
    try {
      return fromJson(value);
    } catch (e) {
      throw DataMismatchException(
        message: 'Failed to decode object at "$key": $e',
        fieldName: key,
      );
    }
  }

  /// Decodes a nested object at [key] using [fromJson], or returns null.
  static T? parseObjectOptional<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is! Map<String, dynamic>) {
      throw DataMismatchException(
        message: 'Expected object for "$key" but got ${value.runtimeType}.',
        fieldName: key,
      );
    }
    try {
      return fromJson(value);
    } catch (e) {
      throw DataMismatchException(
        message: 'Failed to decode object at "$key": $e',
        fieldName: key,
      );
    }
  }

  // ── List ───────────────────────────────────────────────────────────────────

  /// Decodes a list of objects at [key] using [fromJson].
  ///
  /// Each element must be a `Map<String, dynamic>`. Throws
  /// [DataMismatchException] with the element index in `fieldName` if any item
  /// fails to decode.
  static List<T> parseList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        message: 'Missing required list for "$key".',
        fieldName: key,
      );
    }
    if (value is! List) {
      throw DataMismatchException(
        message: 'Expected list for "$key" but got ${value.runtimeType}.',
        fieldName: key,
      );
    }
    final result = <T>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item is! Map<String, dynamic>) {
        throw DataMismatchException(
          message:
              'Expected object at "$key[$i]" but got ${item?.runtimeType}.',
          fieldName: '$key[$i]',
        );
      }
      try {
        result.add(fromJson(item));
      } catch (e) {
        throw DataMismatchException(
          message: 'Failed to decode item at "$key[$i]": $e',
          fieldName: '$key[$i]',
        );
      }
    }
    return result;
  }

  /// Decodes a list of objects at [key] using [fromJson], or returns null.
  static List<T>? parseListOptional<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final value = json[key];
    if (value == null) return null;
    return parseList(json, key, fromJson);
  }

  // ── Lookup helpers ─────────────────────────────────────────────────────────

  /// Returns true if [key] is present in [json] (value may be null).
  static bool hasKey(Map<String, dynamic> json, String key) =>
      json.containsKey(key);

  /// Returns all top-level keys of [json] as a set.
  static Set<String> getKeys(Map<String, dynamic> json) => json.keys.toSet();

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Throws [DataMismatchException] if any field in [requiredFields] is
  /// absent or null in [json].
  ///
  /// Call at the top of `fromJson` for a fast-fail with a clear error before
  /// individual field parsing begins.
  static void validateRequiredFields(
    Map<String, dynamic> json,
    List<String> requiredFields,
  ) {
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw DataMismatchException(
          message: 'Required field "$field" is missing or null.',
          fieldName: field,
        );
      }
    }
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  /// Builds a JSON map from [fields], filtering out null values.
  ///
  /// Nested objects that implement `toJson()` are serialized automatically.
  /// Use this inside `JsonCodable.toJson` to avoid writing boilerplate.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, dynamic> toJson() => JsonParser.toJson({
  ///   'id': id,
  ///   'name': name,
  ///   'metadata': metadata, // serialized recursively if it has toJson()
  /// });
  /// ```
  static Map<String, dynamic> toJson(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value != null) {
        result[entry.key] = _serialize(value);
      }
    }
    return result;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static List<dynamic> _requireList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        message: 'Missing required list for "$key".',
        fieldName: key,
      );
    }
    if (value is! List) {
      throw DataMismatchException(
        message: 'Expected list for "$key" but got ${value.runtimeType}.',
        fieldName: key,
      );
    }
    return value;
  }

  static dynamic _serialize(dynamic value) {
    if (value == null) return null;
    if (value is String || value is int || value is double || value is bool) {
      return value;
    }
    if (value is List) return value.map(_serialize).toList(growable: false);
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, _serialize(v)));
    }
    try {
      return (value as dynamic).toJson() as Map<String, dynamic>;
    } on Object {
      return value.toString();
    }
  }
}
