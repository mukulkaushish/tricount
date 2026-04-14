import 'package:tricount/core/error/app_exception.dart';

/// Mixin providing static JSON parsing helpers with typed error surfaces.
///
/// Every method throws [DataMismatchException] on type mismatch or missing
/// required fields so callers get structured error context rather than
/// a generic [TypeError] or cast exception.
mixin JsonParser {
  // ========== STRING ==========

  static String parseString(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is String) return value;
    throw DataMismatchException(
      "Expected String but got ${value.runtimeType} for field '$key'",
      fieldName: key,
    );
  }

  static String? parseStringOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    return value is String ? value : null;
  }

  // ========== INT ==========

  static int parseInt(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is int) return value;
    if (value is double) {
      if (value.isFinite && value == value.truncateToDouble()) {
        return value.toInt();
      }
      throw DataMismatchException(
        "Double value $value cannot be safely converted to int for field '$key'",
        fieldName: key,
      );
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      throw DataMismatchException(
        "String value '$value' cannot be parsed as int for field '$key'",
        fieldName: key,
      );
    }
    throw DataMismatchException(
      "Expected int but got ${value.runtimeType} for field '$key'",
      fieldName: key,
    );
  }

  static int? parseIntOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    try {
      return parseInt({key: value}, key);
    } on Exception {
      return null;
    }
  }

  // ========== DOUBLE ==========

  static double parseDouble(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
      throw DataMismatchException(
        "String value '$value' cannot be parsed as double for field '$key'",
        fieldName: key,
      );
    }
    throw DataMismatchException(
      "Expected double but got ${value.runtimeType} for field '$key'",
      fieldName: key,
    );
  }

  static double? parseDoubleOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    try {
      return parseDouble({key: value}, key);
    } on Exception {
      return null;
    }
  }

  // ========== BOOL ==========

  static bool parseBool(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      throw DataMismatchException(
        "String value '$value' cannot be parsed as bool for field '$key'",
        fieldName: key,
      );
    }
    if (value is int) return value != 0;
    throw DataMismatchException(
      "Expected bool but got ${value.runtimeType} for field '$key'",
      fieldName: key,
    );
  }

  static bool? parseBoolOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    try {
      return parseBool({key: value}, key);
    } on Exception {
      return null;
    }
  }

  // ========== STRING LIST ==========

  static List<String> parseStringList(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is! List) {
      throw DataMismatchException(
        "Expected List but got ${value.runtimeType} for field '$key'",
        fieldName: key,
      );
    }
    final result = <String>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item == null) {
        throw DataMismatchException(
          "Null value at index $i for field '$key'",
          fieldName: '$key[$i]',
        );
      }
      result.add(item is String ? item : item.toString());
    }
    return result;
  }

  static List<String>? parseStringListOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseStringList(json, key);
    } on Exception {
      return null;
    }
  }

  // ========== INT LIST ==========

  static List<int> parseIntList(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is! List) {
      throw DataMismatchException(
        "Expected List but got ${value.runtimeType} for field '$key'",
        fieldName: key,
      );
    }
    final result = <int>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item == null) {
        throw DataMismatchException(
          "Null value at index $i for field '$key'",
          fieldName: '$key[$i]',
        );
      }
      if (item is int) {
        result.add(item);
      } else if (item is double &&
          item.isFinite &&
          item == item.truncateToDouble()) {
        result.add(item.toInt());
      } else if (item is String) {
        final parsed = int.tryParse(item);
        if (parsed != null) {
          result.add(parsed);
        } else {
          throw DataMismatchException(
            "String '$item' cannot be parsed as int at index $i for '$key'",
            fieldName: '$key[$i]',
          );
        }
      } else {
        throw DataMismatchException(
          "Expected int but got ${item.runtimeType} at index $i for '$key'",
          fieldName: '$key[$i]',
        );
      }
    }
    return result;
  }

  static List<int>? parseIntListOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseIntList(json, key);
    } on Exception {
      return null;
    }
  }

  // ========== DOUBLE LIST ==========

  static List<double> parseDoubleList(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is! List) {
      throw DataMismatchException(
        "Expected List but got ${value.runtimeType} for field '$key'",
        fieldName: key,
      );
    }
    final result = <double>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item == null) {
        throw DataMismatchException(
          "Null value at index $i for field '$key'",
          fieldName: '$key[$i]',
        );
      }
      if (item is int) {
        result.add(item.toDouble());
      } else if (item is double) {
        result.add(item);
      } else if (item is String) {
        final parsed = double.tryParse(item);
        if (parsed != null && parsed.isFinite) {
          result.add(parsed);
        } else {
          throw DataMismatchException(
            "String '$item' cannot be parsed as double at index $i for '$key'",
            fieldName: '$key[$i]',
          );
        }
      } else {
        throw DataMismatchException(
          "Expected double but got ${item.runtimeType} at index $i for '$key'",
          fieldName: '$key[$i]',
        );
      }
    }
    return result;
  }

  static List<double>? parseDoubleListOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseDoubleList(json, key);
    } on Exception {
      return null;
    }
  }

  // ========== BOOL LIST ==========

  static List<bool> parseBoolList(
    final Map<String, dynamic> json,
    final String key,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is! List) {
      throw DataMismatchException(
        "Expected List but got ${value.runtimeType} for field '$key'",
        fieldName: key,
      );
    }
    final result = <bool>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item == null) {
        throw DataMismatchException(
          "Null value at index $i for field '$key'",
          fieldName: '$key[$i]',
        );
      }
      if (item is bool) {
        result.add(item);
      } else if (item is String) {
        final lower = item.toLowerCase();
        if (lower == 'true' || lower == '1') {
          result.add(true);
        } else if (lower == 'false' || lower == '0') {
          result.add(false);
        } else {
          throw DataMismatchException(
            "String '$item' cannot be parsed as bool at index $i for '$key'",
            fieldName: '$key[$i]',
          );
        }
      } else if (item is int) {
        result.add(item != 0);
      } else {
        throw DataMismatchException(
          "Expected bool but got ${item.runtimeType} at index $i for '$key'",
          fieldName: '$key[$i]',
        );
      }
    }
    return result;
  }

  static List<bool>? parseBoolListOptional(
    final Map<String, dynamic> json,
    final String key,
  ) {
    if (json[key] == null) return null;
    try {
      return parseBoolList(json, key);
    } on Exception {
      return null;
    }
  }

  // ========== OBJECT LIST ==========

  static List<T> parseList<T>(
    final Map<String, dynamic> json,
    final String key,
    final T Function(Map<String, dynamic>) fromJson,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is! List) {
      throw DataMismatchException(
        "Expected List but got ${value.runtimeType} for field '$key'",
        fieldName: key,
      );
    }
    final result = <T>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item is! Map<String, dynamic>) {
        throw DataMismatchException(
          "Expected Map<String, dynamic> at index $i but got "
          "${item.runtimeType} for field '$key'",
          fieldName: '$key[$i]',
        );
      }
      try {
        result.add(fromJson(item));
      } catch (e) {
        throw DataMismatchException(
          "Failed to parse item at index $i for field '$key': $e",
          fieldName: '$key[$i]',
        );
      }
    }
    return result;
  }

  static List<T>? parseListOptional<T>(
    final Map<String, dynamic> json,
    final String key,
    final T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json[key] == null) return null;
    try {
      return parseList(json, key, fromJson);
    } on Exception {
      return null;
    }
  }

  // ========== OBJECT ==========

  static T parseObject<T>(
    final Map<String, dynamic> json,
    final String key,
    final T Function(Map<String, dynamic>) fromJson,
  ) {
    final value = json[key];
    if (value == null) {
      throw DataMismatchException(
        "Required field '$key' is missing or null",
        fieldName: key,
      );
    }
    if (value is! Map<String, dynamic>) {
      throw DataMismatchException(
        "Expected Map<String, dynamic> but got ${value.runtimeType} for '$key'",
        fieldName: key,
      );
    }
    try {
      return fromJson(value);
    } catch (e) {
      throw DataMismatchException(
        "Failed to parse object for field '$key': $e",
        fieldName: key,
      );
    }
  }

  static T? parseObjectOptional<T>(
    final Map<String, dynamic> json,
    final String key,
    final T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json[key] == null) return null;
    try {
      return parseObject(json, key, fromJson);
    } on Exception {
      return null;
    }
  }

  // ========== SERIALIZATION ==========

  static Map<String, dynamic> toJson(final Map<String, dynamic> fields) {
    final json = <String, dynamic>{};
    fields.forEach((final key, final value) {
      if (value != null) {
        json[key] = _serializeValue(value);
      }
    });
    return json;
  }

  // ========== UTILITIES ==========

  static bool hasKey(
    final Map<String, dynamic> json,
    final String key,
  ) =>
      json.containsKey(key);

  static Set<String> getKeys(final Map<String, dynamic> json) =>
      json.keys.toSet();

  static void validateRequiredFields(
    final Map<String, dynamic> json,
    final List<String> requiredFields,
  ) {
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw DataMismatchException(
          "Required field '$field' is missing or null",
          fieldName: field,
        );
      }
    }
  }
}

/// Serializes [value] to a JSON-compatible primitive.
///
/// Handles: primitives, lists, `Map<String, dynamic>`, and objects
/// that implement [JsonCodable].
dynamic _serializeValue(final dynamic value) {
  if (value == null) return null;
  if (value is String || value is int || value is double || value is bool) {
    return value;
  }
  if (value is List) {
    return value.map(_serializeValue).toList();
  }
  if (value is Map<String, dynamic>) {
    return value.map(
      (final key, final val) => MapEntry(key, _serializeValue(val)),
    );
  }
  if (value is JsonCodable) return value.toJson();
  return value.toString();
}

/// Interface for objects that can serialize themselves to JSON.
abstract interface class JsonCodable {
  Map<String, dynamic> toJson();
}
