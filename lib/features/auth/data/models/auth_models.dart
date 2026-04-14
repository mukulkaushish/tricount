import 'package:equatable/equatable.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/core/network/network.dart';

class AuthTokensModel extends Equatable implements JsonCodable {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: JsonParser.parseString(json, 'accessToken'),
      refreshToken: JsonParser.parseString(json, 'refreshToken'),
    );
  }

  final String accessToken;
  final String refreshToken;

  AuthTokens toEntity() => AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );

  @override
  Map<String, dynamic> toJson() => JsonParser.toJson({
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthenticatedUserModel extends Equatable implements JsonCodable {
  const AuthenticatedUserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.emailVerified,
    required this.passkeyEnabled,
    this.avatarUrl,
  });

  factory AuthenticatedUserModel.fromJson(Map<String, dynamic> json) {
    // The backend may wrap the user under a nested 'user' key.
    final payload = JsonParser.parseMapOptional(json, 'user') ?? json;
    final email = JsonParser.parseStringOptional(payload, 'email') ?? '';

    return AuthenticatedUserModel(
      id: JsonParser.parseStringOptional(payload, 'id') ??
          JsonParser.parseStringOptional(payload, 'userId') ??
          email,
      email: email,
      displayName: JsonParser.parseStringOptional(payload, 'displayName') ??
          JsonParser.parseStringOptional(payload, 'name') ??
          email,
      avatarUrl: JsonParser.parseStringOptional(payload, 'avatarUrl'),
      emailVerified: JsonParser.parseBoolOptional(payload, 'emailVerified') ??
          JsonParser.parseBoolOptional(payload, 'isEmailVerified') ??
          false,
      passkeyEnabled:
          JsonParser.parseBoolOptional(payload, 'passkeyEnabled') ??
          JsonParser.parseBoolOptional(payload, 'hasPasskey') ??
          false,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool emailVerified;
  final bool passkeyEnabled;

  AuthenticatedUser toEntity() => AuthenticatedUser(
    id: id,
    email: email,
    displayName: displayName,
    avatarUrl: avatarUrl,
    emailVerified: emailVerified,
    passkeyEnabled: passkeyEnabled,
  );

  @override
  Map<String, dynamic> toJson() => JsonParser.toJson({
    'id': id,
    'email': email,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'emailVerified': emailVerified,
    'passkeyEnabled': passkeyEnabled,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    avatarUrl,
    emailVerified,
    passkeyEnabled,
  ];
}

class PasskeyOptionsModel extends Equatable implements JsonCodable {
  const PasskeyOptionsModel({required this.payload});

  factory PasskeyOptionsModel.fromJson(Map<String, dynamic> json) {
    return PasskeyOptionsModel(payload: Map<String, dynamic>.from(json));
  }

  final Map<String, dynamic> payload;

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(payload);

  @override
  List<Object?> get props => [payload];
}
