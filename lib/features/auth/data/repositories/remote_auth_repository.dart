import 'package:fpdart/fpdart.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/core/network/network.dart';
import 'package:tricount/core/security/security.dart';
import 'package:tricount/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tricount/features/auth/data/datasources/social_auth_datasource.dart';
import 'package:tricount/features/auth/data/models/auth_token_model.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';

/// Remote-only implementation of [AuthRepository].
///
/// Maps data-layer DTOs to domain entities via `.toDomain()`.
/// Persists tokens and basic user info to [TokenProvider] after every
/// successful auth operation.
/// Social sign-in methods orchestrate both the native SDK call
/// (via [SocialAuthDataSource]) and the backend exchange
/// (via [AuthRemoteDataSource]) in sequence.
final class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(
    this._dataSource,
    this._socialAuth,
    this._tokenProvider,
  );

  final AuthRemoteDataSource _dataSource;
  final SocialAuthDataSource _socialAuth;
  final TokenProvider _tokenProvider;

  @override
  Future<Either<AppException, AuthToken>> login({
    required final String email,
    required final String password,
  }) async {
    final result = await _dataSource.login(email: email, password: password);
    return switch (result) {
      Left(:final value) => left(value),
      Right(:final value) => _persistSession(
        model: value,
        email: email,
      ),
    };
  }

  @override
  Future<Either<AppException, AuthToken>> register({
    required final String email,
    required final String password,
    required final String displayName,
  }) async {
    final result = await _dataSource.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    return switch (result) {
      Left(:final value) => left(value),
      Right(:final value) => _persistSession(
        model: value,
        email: email,
        displayName: displayName,
      ),
    };
  }

  @override
  Future<Either<AppException, EmptyResponse>> forgotPassword({
    required final String email,
  }) => _dataSource.forgotPassword(email: email);

  @override
  Future<Either<AppException, EmptyResponse>> resetPassword({
    required final String email,
    required final String code,
    required final String newPassword,
  }) => _dataSource.resetPassword(
    email: email,
    code: code,
    newPassword: newPassword,
  );

  @override
  Future<Either<AppException, AuthToken>> refreshToken({
    required final String refreshToken,
  }) async {
    final result = await _dataSource.refreshToken(refreshToken: refreshToken);
    return result.map((model) => model.toDomain());
  }

  @override
  Future<Either<AppException, AuthToken>> loginWithGoogle() async {
    final idTokenResult = await _socialAuth.getGoogleIdToken();
    if (idTokenResult case Left(:final value)) return left(value);
    final idToken = (idTokenResult as Right<AppException, String>).value;
    final backendResult = await _dataSource.loginWithGoogle(idToken: idToken);
    return switch (backendResult) {
      Left(:final value) => left(value),
      Right(:final value) => _persistSession(model: value, email: ''),
    };
  }

  @override
  Future<Either<AppException, AuthToken>> loginWithApple() async {
    final idTokenResult = await _socialAuth.getAppleIdToken();
    if (idTokenResult case Left(:final value)) return left(value);
    final idToken = (idTokenResult as Right<AppException, String>).value;
    final backendResult = await _dataSource.loginWithApple(idToken: idToken);
    return switch (backendResult) {
      Left(:final value) => left(value),
      Right(:final value) => _persistSession(model: value, email: ''),
    };
  }

  @override
  Future<Either<AppException, EmptyResponse>> logout() async {
    final result = await _dataSource.logout();
    await _tokenProvider.clearTokens();
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Either<AppException, AuthToken>> _persistSession({
    required final AuthTokenModel model,
    required final String email,
    final String? displayName,
  }) async {
    final token = model.toDomain();
    await Future.wait([
      _tokenProvider.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      ),
      if (email.isNotEmpty)
        _tokenProvider.saveUserInfo(email: email, displayName: displayName),
    ]);
    return right(token);
  }
}
