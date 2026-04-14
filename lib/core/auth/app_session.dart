import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthenticatedUser extends Equatable {
  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.emailVerified = false,
    this.passkeyEnabled = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool emailVerified;
  final bool passkeyEnabled;

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

class AppSession extends Equatable {
  const AppSession({
    required this.tokens,
    required this.user,
  });

  final AuthTokens tokens;
  final AuthenticatedUser user;

  @override
  List<Object?> get props => [tokens, user];
}
