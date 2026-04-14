import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/auth.dart';
import 'package:tricount/router/router.dart';

@RoutePage()
class LoginPage extends StatelessWidget implements AutoRouteWrapper {
  const LoginPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && state.session != null) {
          context.read<SessionBloc>().add(
            SessionSignedIn(session: state.session!),
          );
          unawaited(context.router.replaceAll([const HomeRoute()]));
          context.read<AuthBloc>().add(const AuthStatusCleared());
        }

        if (state.status == AuthStatus.failure && state.failure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.failure!.localizedMessage(context))),
            );
        }
      },
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsiveContentPadding,
          child: AuthFormCard(
            title: l10n.authTitle,
            subtitle: l10n.authSubtitle,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        hintText: l10n.emailHint,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                    ),
                    const Gap(AppDimensions.s16),
                    TextFormField(
                      controller: _passwordController,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        hintText: l10n.passwordHint,
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                    ),
                  ],
                ),
              ),
              const Gap(AppDimensions.s16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.router.push(
                    ForgotPasswordRoute(
                      prefillEmail: _emailController.text.trim(),
                    ),
                  ),
                  child: Text(l10n.forgotPasswordCta),
                ),
              ),
              const Gap(AppDimensions.s8),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return FilledButton(
                    onPressed: state.isSubmitting ? null : _submitLogin,
                    child:
                        state.isSubmitting && state.action == AuthAction.login
                        ? const CircularProgressIndicator.adaptive()
                        : Text(l10n.loginCta),
                  );
                },
              ),
              const Gap(AppDimensions.s12),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return OutlinedButton.icon(
                    onPressed: state.isSubmitting ? null : _submitPasskey,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(l10n.passkeyCta),
                  );
                },
              ),
              const Gap(AppDimensions.s12),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return OutlinedButton.icon(
                    onPressed: state.isSubmitting
                        ? null
                        : () => context.read<AuthBloc>().add(
                            const GoogleSignInRequested(),
                          ),
                    icon: const Icon(Icons.public_rounded),
                    label: Text(l10n.googleLoginCta),
                  );
                },
              ),
              const Gap(AppDimensions.s12),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return OutlinedButton.icon(
                    onPressed: state.isSubmitting
                        ? null
                        : () => context.read<AuthBloc>().add(
                            const AppleSignInRequested(),
                          ),
                    icon: const Icon(Icons.apple_rounded),
                    label: Text(l10n.appleLoginCta),
                  );
                },
              ),
              const Gap(AppDimensions.s24),
              TextButton(
                onPressed: () => context.router.push(const RegisterRoute()),
                child: Text(l10n.switchToRegister),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) {
      return l10n.emailValidationRequired;
    }
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return l10n.emailValidationInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = context.l10n;
    if (value == null || value.isEmpty) {
      return l10n.passwordValidationRequired;
    }
    if (value.length < 8) {
      return l10n.passwordValidationShort;
    }
    return null;
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _submitPasskey() {
    if (_validateEmail(_emailController.text) != null) {
      _formKey.currentState!.validate();
      return;
    }

    context.read<AuthBloc>().add(
      PasskeySignInRequested(email: _emailController.text.trim()),
    );
  }
}
