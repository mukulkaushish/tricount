/// Base URL injected at build time via `--dart-define=BASE_URL=https://...`
///
/// Falls back to localhost for simulator / Android-emulator development.
const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Default HTTP connect and receive timeout.
const Duration httpTimeout = Duration(seconds: 15);

/// Auth endpoints
const String authLoginPath = '/v1/auth/login';
const String authRegisterPath = '/v1/auth/register';
const String authRefreshPath = '/v1/auth/refresh';
const String authForgotPasswordPath = '/v1/auth/forgot-password';
const String authResetPasswordPath = '/v1/auth/reset-password';
const String authLogoutPath = '/v1/auth/logout';
const String authGooglePath = '/v1/auth/google';
const String authApplePath = '/v1/auth/apple';
const String authPasskeysAuthOptionsPath =
    '/v1/auth/passkeys/authenticate/options';
const String authPasskeysAuthVerifyPath =
    '/v1/auth/passkeys/authenticate/verify';

// ── SSO / OAuth ───────────────────────────────────────────────────────────────

/// Google OAuth2 client ID.
///
/// Set via `--dart-define=GOOGLE_CLIENT_ID=<value>` at build time.
/// Required for flutter_appauth Google sign-in flow.
const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

/// Apple OAuth2 service ID (web service identifier).
///
/// Set via `--dart-define=APPLE_SERVICE_ID=<value>` at build time.
/// Required for flutter_appauth Apple sign-in flow.
const String appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');

/// Custom URL scheme used as OAuth2 redirect after SSO authorization.
///
/// Override via `--dart-define=OAUTH_REDIRECT_URL=<value>`.
/// Must match the registered scheme in Info.plist (iOS) and
/// AndroidManifest.xml intent-filter (Android).
const String oAuthRedirectUrl = String.fromEnvironment(
  'OAUTH_REDIRECT_URL',
  defaultValue: 'com.tricount.app:/oauth2redirect',
);
