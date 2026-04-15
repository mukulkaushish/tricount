import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tricount/core/security/token_provider.dart';

/// FlutterSecureStorage-backed TokenProvider.
///
/// Tokens survive app restarts via the platform keychain/keystore.
/// Values are cached in memory after initialize() is called so the
/// AuthInterceptor can read them synchronously.
final class SecureTokenProvider implements TokenProvider {
  SecureTokenProvider(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'tricount_access_token';
  static const _refreshTokenKey = 'tricount_refresh_token';

  String? _accessToken;
  String? _refreshToken;

  /// Loads persisted tokens into memory.
  ///
  /// Call this once during app bootstrap before runApp.
  Future<void> initialize() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
  }

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

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
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }
}
