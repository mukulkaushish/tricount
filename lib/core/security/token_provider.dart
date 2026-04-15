/// Contract for reading and persisting auth tokens and basic user profile.
///
/// The production implementation is SecureTokenProvider
/// (flutter_secure_storage). Use InMemoryTokenProvider only in tests.
abstract interface class TokenProvider {
  /// Current access token (sync — loaded from secure storage at startup).
  String? get accessToken;

  /// Current refresh token (sync — loaded from secure storage at startup).
  String? get refreshToken;

  /// Display name cached after the most recent successful auth.
  String? get displayName;

  /// Email cached after the most recent successful auth.
  String? get email;

  Future<void> saveTokens({
    required final String accessToken,
    required final String refreshToken,
  });

  Future<void> saveUserInfo({
    required final String email,
    final String? displayName,
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
  String? _displayName;
  String? _email;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  String? get displayName => _displayName;

  @override
  String? get email => _email;

  @override
  Future<void> saveTokens({
    required final String accessToken,
    required final String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> saveUserInfo({
    required final String email,
    final String? displayName,
  }) async {
    _email = email;
    _displayName = displayName;
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _displayName = null;
  }
}
