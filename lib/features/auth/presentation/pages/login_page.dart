import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tricount/features/auth/presentation/widgets/auth_form.dart';
import 'package:tricount/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:tricount/features/auth/presentation/widgets/auth_page_layouts.dart';
import 'package:tricount/router/router.dart';
import 'package:tricount/shared/shared.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(final BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess || state is RegisterSuccess) {
          unawaited(context.router.replaceAll([const HomeRoute()]));
        }
      },
      child: KeyboardDismisser(
        gestures: const [
          GestureType.onTap,
          GestureType.onPanUpdateDownDirection,
          GestureType.onPanUpdateUpDirection,
        ],
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: context.colorScheme.surface,
          body: const AdaptiveLayout(
            compact: _CompactLoginLayout(),
            expanded: _ExpandedLoginLayout(),
          ),
        ),
      ),
    );
  }
}

class _CompactLoginLayout extends StatelessWidget {
  const _CompactLoginLayout();

  @override
  Widget build(final BuildContext context) => const AuthCompactLayout(
    formCard: AuthFormCard(
      title: 'Sign in',
      child: AuthForm(),
    ),
  );
}

class _ExpandedLoginLayout extends StatelessWidget {
  const _ExpandedLoginLayout();

  @override
  Widget build(final BuildContext context) => const AuthExpandedLayout(
    title: 'Sign in',
    subtitle: 'Split bills, stay friends.',
    formContent: AuthForm(),
  );
}
