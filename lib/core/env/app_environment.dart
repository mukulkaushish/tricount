abstract final class AppEnvironment {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String appAuthRedirectScheme = String.fromEnvironment(
    'APP_AUTH_REDIRECT_SCHEME',
    defaultValue: 'com.example.tricount.auth',
  );

  static const String appAuthRedirectUrl = String.fromEnvironment(
    'APP_AUTH_REDIRECT_URL',
    defaultValue: 'com.example.tricount.auth:/oauthredirect',
  );

  static const String googleOidcClientId = String.fromEnvironment(
    'GOOGLE_OIDC_CLIENT_ID',
  );

  static const String appleOidcClientId = String.fromEnvironment(
    'APPLE_OIDC_CLIENT_ID',
  );

  static const String googleDiscoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  static const String appleDiscoveryUrl =
      'https://appleid.apple.com/.well-known/openid-configuration';
}
