import 'package:tricount/core/json/json_parser.dart';
import 'package:tricount/features/auth/domain/entities/user.dart';

/// Data-layer DTO for a registered user returned by the backend.
final class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
  });

  factory UserModel.fromJson(final Map<String, dynamic> json) => UserModel(
        id: JsonParser.parseString(json, 'id'),
        email: JsonParser.parseString(json, 'email'),
        displayName: JsonParser.parseString(json, 'displayName'),
      );

  final String id;
  final String email;
  final String displayName;

  User toDomain() => User(
        id: id,
        email: email,
        displayName: displayName,
      );
}
