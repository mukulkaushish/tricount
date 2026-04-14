import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tricount/core/auth/app_session.dart';
import 'package:tricount/core/auth/auth_session_store.dart';

const _accessTokenKey = 'auth_access_token';
const _refreshTokenKey = 'auth_refresh_token';

class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({required FlutterSecureStorage storage})
    : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  @override
  Future<bool> hasTokens() async => (await readTokens()) != null;

  @override
  Future<AuthTokens?> readTokens() async {
    final values = await Future.wait([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
    ]);

    final accessToken = values.first;
    final refreshToken = values.last;

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
    ]);
  }
}
