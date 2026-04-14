/// Contract for reading and persisting auth tokens.
///
/// The concrete implementation wraps [SecureStore]. An in-memory
/// implementation is used during development/testing.
abstract interface class TokenProvider {
  String? get accessToken;
  String? get refreshToken;

  Future<void> saveTokens({
    required final String accessToken,
    required final String refreshToken,
  });

  Future<void> clearTokens();
}

/// Simple in-memory [TokenProvider].
///
/// Tokens survive only for the duration of the current app session.
/// Replace with a [SecureStore]-backed implementation for production.
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
