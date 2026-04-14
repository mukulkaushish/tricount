import 'package:fpdart/fpdart.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/core/network/network.dart';
import 'package:tricount/features/auth/data/data_sources/data_sources.dart';
import 'package:tricount/features/auth/data/models/models.dart';
import 'package:tricount/features/auth/domain/domain.dart';

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterAppAuthIdentityProvider oidcIdentityProvider,
    required FlutterPasskeyIdentityProvider passkeyIdentityProvider,
    required AuthSessionStore sessionStore,
  }) : _remoteDataSource = remoteDataSource,
       _oidcIdentityProvider = oidcIdentityProvider,
       _passkeyIdentityProvider = passkeyIdentityProvider,
       _sessionStore = sessionStore;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthSessionStore _sessionStore;
  final FlutterAppAuthIdentityProvider _oidcIdentityProvider;
  final FlutterPasskeyIdentityProvider _passkeyIdentityProvider;

  @override
  Future<Either<AppException, AuthenticatedUser>> getCurrentUser() async {
    final result = await _remoteDataSource.getCurrentUser();
    return result.map((user) => user.toEntity());
  }

  @override
  Future<Either<AppException, AppSession>> login({
    required String email,
    required String password,
  }) async {
    final tokensResult = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    return _hydrateSession(tokensResult);
  }

  @override
  Future<Either<AppException, AppSession>> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final tokensResult = await _remoteDataSource.register(
      displayName: displayName,
      email: email,
      password: password,
    );
    return _hydrateSession(tokensResult);
  }

  @override
  Future<Either<AppException, Unit>> requestPasswordResetOtp({
    required String email,
  }) {
    return _remoteDataSource.requestPasswordResetOtp(email: email);
  }

  @override
  Future<Either<AppException, Unit>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) {
    return _remoteDataSource.resetPassword(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
    );
  }

  @override
  Future<Either<AppException, AppSession>> signInWithApple() async {
    final idToken = await _oidcIdentityProvider.getIdToken(OidcProvider.apple);
    switch (idToken) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final token):
        final tokensResult = await _remoteDataSource.signInWithApple(
          idToken: token,
        );
        return _hydrateSession(tokensResult);
    }
  }

  @override
  Future<Either<AppException, AppSession>> signInWithGoogle() async {
    final idToken = await _oidcIdentityProvider.getIdToken(OidcProvider.google);
    switch (idToken) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final token):
        final tokensResult = await _remoteDataSource.signInWithGoogle(
          idToken: token,
        );
        return _hydrateSession(tokensResult);
    }
  }

  @override
  Future<Either<AppException, AppSession>> signInWithPasskey({
    required String email,
  }) async {
    final optionsResult = await _remoteDataSource.getPasskeyOptions(
      email: email,
    );
    switch (optionsResult) {
      case Left(value: final failure):
        return left(failure);
      case Right(value: final options):
        final credentialResult = await _passkeyIdentityProvider.authenticate(
          options: options.payload,
        );
        switch (credentialResult) {
          case Left(value: final failure):
            return left(failure);
          case Right(value: final payload):
            final tokensResult = await _remoteDataSource.verifyPasskey(
              payload: payload,
            );
            return _hydrateSession(tokensResult);
        }
    }
  }

  Future<Either<AppException, AppSession>> _hydrateSession(
    Either<AppException, AuthTokensModel> tokensResult,
  ) async {
    return tokensResult.match(
      (failure) async => left(failure),
      (tokensModel) async {
        final tokens = tokensModel.toEntity();
        await _sessionStore.saveTokens(tokens);

        final userResult = await getCurrentUser();
        return userResult.match(
          (failure) async {
            await _sessionStore.clearTokens();
            return left(failure);
          },
          (user) => right(
            AppSession(tokens: tokens, user: user),
          ),
        );
      },
    );
  }
}
