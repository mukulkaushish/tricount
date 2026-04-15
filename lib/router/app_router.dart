import 'package:auto_route/auto_route.dart';
import 'package:tricount/core/core.dart';
import 'package:tricount/router/app_router.gr.dart';
import 'package:tricount/router/guards/auth_guard.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
final class AppRouter extends RootStackRouter {
  AppRouter(this._tokenProvider);

  final TokenProvider _tokenProvider;

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true, path: '/'),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: RegisterRoute.page, path: '/register'),
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
      guards: [AuthGuard(_tokenProvider)],
      children: [
        AutoRoute(page: FeedRoute.page, path: 'feed', initial: true),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
      ],
    ),
  ];
}
