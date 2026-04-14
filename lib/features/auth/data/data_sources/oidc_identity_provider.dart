import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/env/app_environment.dart';
import 'package:tricount/core/network/network.dart';

enum OidcProvider { apple, google }

class FlutterAppAuthIdentityProvider {
  const FlutterAppAuthIdentityProvider({required FlutterAppAuth appAuth})
    : _appAuth = appAuth;

  final FlutterAppAuth _appAuth;

  Future<Either<AppException, String>> getIdToken(
    OidcProvider provider,
  ) async {
    final config = _configFor(provider);
    if (config == null) {
      return left(
        const ConfigurationAppException(
          message: 'Missing OIDC client configuration.',
        ),
      );
    }

    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          config.clientId,
          AppEnvironment.appAuthRedirectUrl,
          discoveryUrl: config.discoveryUrl,
          scopes: config.scopes,
          promptValues: const ['login'],
        ),
      );

      final idToken = response.idToken;
      if (idToken == null || idToken.isEmpty) {
        return left(
          const ValidationAppException(
            message: 'The identity provider did not return an ID token.',
          ),
        );
      }

      return right(idToken);
    } on Object catch (error) {
      return left(
        ValidationAppException(message: error.toString()),
      );
    }
  }

  _OidcProviderConfig? _configFor(OidcProvider provider) {
    return switch (provider) {
      OidcProvider.apple when AppEnvironment.appleOidcClientId.isNotEmpty =>
        const _OidcProviderConfig(
          clientId: AppEnvironment.appleOidcClientId,
          discoveryUrl: AppEnvironment.appleDiscoveryUrl,
          scopes: ['openid', 'email', 'name'],
        ),
      OidcProvider.google when AppEnvironment.googleOidcClientId.isNotEmpty =>
        const _OidcProviderConfig(
          clientId: AppEnvironment.googleOidcClientId,
          discoveryUrl: AppEnvironment.googleDiscoveryUrl,
          scopes: ['openid', 'email', 'profile'],
        ),
      _ => null,
    };
  }
}

class _OidcProviderConfig {
  const _OidcProviderConfig({
    required this.clientId,
    required this.discoveryUrl,
    required this.scopes,
  });

  final String clientId;
  final String discoveryUrl;
  final List<String> scopes;
}
