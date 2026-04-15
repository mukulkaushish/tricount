import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/constants/api_constants.dart';
import 'package:tricount/core/error/app_exception.dart';

/// Contract for obtaining native platform OAuth ID tokens.
///
/// Using flutter_appauth as the single OAuth2/OIDC library means
/// both Google and Apple (and any future provider) share the same
/// authorization-code + PKCE flow via the system browser, with no
/// provider-specific SDKs needed.
abstract interface class SocialAuthDataSource {
  /// Runs the Google OAuth2 flow and returns the OpenID Connect idToken.
  Future<Either<AppException, String>> getGoogleIdToken();

  /// Runs the Apple OAuth2 flow and returns the Apple identity token.
  Future<Either<AppException, String>> getAppleIdToken();
}

/// Production implementation using [FlutterAppAuth].
///
/// Both providers go through [FlutterAppAuth.authorizeAndExchangeCode],
/// which performs the full authorization-code + PKCE exchange via the
/// system browser (ASWebAuthenticationSession on iOS,
/// Chrome Custom Tabs on Android). The result includes an `idToken`
/// (OpenID Connect JWT) that the backend accepts at its SSO endpoints.
///
/// **Configuration**: set at build time via `--dart-define`:
/// - `GOOGLE_CLIENT_ID`   — from Google Cloud Console
/// - `APPLE_SERVICE_ID`   — Apple web service identifier
/// - `OAUTH_REDIRECT_URL` — custom scheme, e.g. `com.tricount.app:/oauth2redirect`
///
/// **Platform setup required**:
/// - iOS: register the redirect URL scheme in `Info.plist` and enable
///   "Sign in with Apple" capability in Xcode for Apple SSO.
/// - Android: add an intent-filter for the custom scheme in
///   `AndroidManifest.xml`.
final class NativeSocialAuthDataSource implements SocialAuthDataSource {
  NativeSocialAuthDataSource() : _appAuth = const FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  static const _googleAuthEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const _googleTokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _appleAuthEndpoint = 'https://appleid.apple.com/auth/authorize';
  static const _appleTokenEndpoint = 'https://appleid.apple.com/auth/token';

  @override
  Future<Either<AppException, String>> getGoogleIdToken() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          googleClientId,
          oAuthRedirectUrl,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: _googleAuthEndpoint,
            tokenEndpoint: _googleTokenEndpoint,
          ),
          scopes: const ['openid', 'email', 'profile'],
        ),
      );
      final idToken = result.idToken;
      if (idToken == null) {
        return left(UnknownException('Google idToken was null.'));
      }
      return right(idToken);
    } on PlatformException catch (e) {
      if (_isCancelled(e)) {
        return left(
          const NetworkException(message: 'Google sign-in cancelled.'),
        );
      }
      return left(UnknownException('Google sign-in error: ${e.message}'));
    } on Exception catch (e) {
      return left(UnknownException('Google sign-in error: $e'));
    }
  }

  @override
  Future<Either<AppException, String>> getAppleIdToken() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          appleServiceId,
          oAuthRedirectUrl,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: _appleAuthEndpoint,
            tokenEndpoint: _appleTokenEndpoint,
          ),
          scopes: const ['openid', 'email', 'name'],
          additionalParameters: const {'response_mode': 'form_post'},
        ),
      );
      final idToken = result.idToken;
      if (idToken == null) {
        return left(UnknownException('Apple idToken was null.'));
      }
      return right(idToken);
    } on PlatformException catch (e) {
      if (_isCancelled(e)) {
        return left(
          const NetworkException(message: 'Apple sign-in cancelled.'),
        );
      }
      return left(UnknownException('Apple sign-in error: ${e.message}'));
    } on Exception catch (e) {
      return left(UnknownException('Apple sign-in error: $e'));
    }
  }

  /// Returns true when the user dismissed the browser / cancelled the flow.
  bool _isCancelled(final PlatformException e) =>
      e.code == 'user_cancelled_flow' ||
      (e.message?.toLowerCase().contains('cancel') ?? false);
}
