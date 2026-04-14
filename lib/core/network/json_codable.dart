/// Contract for all Data Transfer Objects (DTOs) in the data layer.
///
/// Every model class that is serialized to or from JSON **must** implement
/// this interface. This ensures:
/// - Serialization is never forgotten when a new model is added.
/// - The compiler enforces the contract — no implicit `dynamic.toJson()` calls.
/// - `JsonParser.toJson` can serialize nested models automatically.
///
/// The companion `fromJson` factory constructor is not part of this interface
/// (Dart does not support static factory methods in interfaces), but it is
/// equally mandatory by convention. Pair it with `implements JsonCodable`:
///
/// ```dart
/// class UserModel implements JsonCodable {
///   const UserModel({required this.id, required this.name});
///
///   factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
///     id: JsonParser.parseRequiredString(json, 'id'),
///     name: JsonParser.parseRequiredString(json, 'name'),
///   );
///
///   final String id;
///   final String name;
///
///   @override
///   Map<String, dynamic> toJson() => JsonParser.toJson({
///     'id': id,
///     'name': name,
///   });
/// }
/// ```
// ignore: one_member_abstracts
abstract interface class JsonCodable {
  /// Serializes this object to a JSON-compatible map.
  ///
  /// Prefer delegating to `JsonParser.toJson` to ensure nulls are stripped
  /// and nested objects are serialized recursively.
  Map<String, dynamic> toJson();
}
