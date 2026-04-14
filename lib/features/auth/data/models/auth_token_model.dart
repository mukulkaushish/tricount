import 'package:tricount/core/json/json_parser.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';

/// Data-layer DTO for the token pair returned by all auth endpoints.
final class AuthTokenModel {
  const AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokenModel.fromJson(final Map<String, dynamic> json) =>
      AuthTokenModel(
        accessToken: JsonParser.parseString(json, 'accessToken'),
        refreshToken: JsonParser.parseString(json, 'refreshToken'),
      );

  final String accessToken;
  final String refreshToken;

  AuthToken toDomain() => AuthToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}
