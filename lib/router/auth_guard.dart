import 'package:auto_route/auto_route.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/router/app_router.dart';

class AuthGuard extends AutoRouteGuard {
  AuthGuard({required AuthSessionStore sessionStore})
    : _sessionStore = sessionStore;

  final AuthSessionStore _sessionStore;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (await _sessionStore.hasTokens()) {
      resolver.next();
      return;
    }

    await router.replace(const LoginRoute());
  }
}
