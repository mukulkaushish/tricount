import 'package:auto_route/auto_route.dart';
import 'package:tricount/core/core.dart';
import 'package:tricount/router/app_router.gr.dart';

/// Redirects unauthenticated users to [LoginRoute].
///
/// Checks for a stored access token synchronously — the token is loaded
/// into memory at app startup by [SecureTokenProvider.initialize].
final class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._tokenProvider);

  final TokenProvider _tokenProvider;

  @override
  Future<void> onNavigation(
    final NavigationResolver resolver,
    final StackRouter router,
  ) async {
    if (_tokenProvider.accessToken != null &&
        _tokenProvider.refreshToken != null) {
      resolver.next();
      return;
    }
    resolver.redirectUntil(const LoginRoute());
  }
}
