import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/router/router.dart';

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SessionBloc>().state;
    _routeForState(context, state);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: AppDimensions.s16),
            Text(context.l10n.loadingSession),
          ],
        ),
      ),
    );
  }

  void _routeForState(BuildContext context, SessionState state) {
    if (state is SessionAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(context.router.replace(const HomeRoute()));
      });
    } else if (state is SessionFailure || state is SessionUnauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(context.router.replace(const LoginRoute()));
      });
    }
  }
}
