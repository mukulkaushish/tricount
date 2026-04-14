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
const String authGooglePath = '/v1/auth/google';
const String authApplePath = '/v1/auth/apple';
const String authPasskeysAuthOptionsPath = '/v1/auth/passkeys/authenticate/options';
const String authPasskeysAuthVerifyPath = '/v1/auth/passkeys/authenticate/verify';
