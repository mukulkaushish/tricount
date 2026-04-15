import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tricount/core/security/token_provider.dart';

/// FlutterSecureStorage-backed TokenProvider.
///
/// Tokens and basic user profile survive app restarts via the platform
/// keychain/keystore. Values are cached in memory after initialize() is called
/// so the AuthInterceptor can read them synchronously.
final class SecureTokenProvider implements TokenProvider {
  SecureTokenProvider(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'tricount_access_token';
  static const _refreshTokenKey = 'tricount_refresh_token';
  static const _emailKey = 'tricount_email';
  static const _displayNameKey = 'tricount_display_name';

  String? _accessToken;
  String? _refreshToken;
  String? _email;
  String? _displayName;

  /// Loads persisted tokens and user info into memory.
  ///
  /// Call this once during app bootstrap before runApp.
  Future<void> initialize() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    _email = await _storage.read(key: _emailKey);
    _displayName = await _storage.read(key: _displayNameKey);
  }

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  String? get email => _email;

  @override
  String? get displayName => _displayName;

  @override
  Future<void> saveTokens({
    required final String accessToken,
    required final String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  @override
  Future<void> saveUserInfo({
    required final String email,
    final String? displayName,
  }) async {
    _email = email;
    if (displayName != null) _displayName = displayName;
    await Future.wait([
      _storage.write(key: _emailKey, value: email),
      if (displayName != null)
        _storage.write(key: _displayNameKey, value: displayName),
    ]);
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _displayName = null;
    await _storage.deleteAll();
  }
}
