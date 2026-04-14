import 'package:tricount/core/auth/app_session.dart';

abstract interface class AuthSessionStore {
  Future<AuthTokens?> readTokens();

  Future<void> saveTokens(AuthTokens tokens);

  Future<void> clearTokens();

  Future<bool> hasTokens();
}
