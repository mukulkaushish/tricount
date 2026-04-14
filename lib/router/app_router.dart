import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'package:tricount/features/auth/auth.dart';
import 'package:tricount/features/home/home.dart';
import 'package:tricount/router/auth_guard.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required this.authGuard});

  final AuthGuard authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: RegisterRoute.page, path: '/register'),
    AutoRoute(page: ForgotPasswordRoute.page, path: '/forgot-password'),
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
      guards: [authGuard],
    ),
  ];
}
