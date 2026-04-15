/// Contract for reading and persisting auth tokens.
///
/// The production implementation is SecureTokenProvider
/// (flutter_secure_storage). Use InMemoryTokenProvider only in tests.
abstract interface class TokenProvider {
  /// Current access token (sync — loaded from secure storage at startup).
  String? get accessToken;

  /// Current refresh token (sync — loaded from secure storage at startup).
  String? get refreshToken;

  Future<void> saveTokens({
    required final String accessToken,
    required final String refreshToken,
  });

  Future<void> clearTokens();
}

/// In-memory [TokenProvider] for unit tests and development.
///
/// Tokens are lost when the app process exits.
/// **Do not use in production builds.**
final class InMemoryTokenProvider implements TokenProvider {
  String? _accessToken;
  String? _refreshToken;

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
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
