import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/auth.dart';
import 'package:tricount/router/router.dart';

@RoutePage()
class RegisterPage extends StatelessWidget implements AutoRouteWrapper {
  const RegisterPage({super.key});

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
        }

        if (state.status == AuthStatus.failure && state.failure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.failure!.localizedMessage(context))),
            );
        }
      },
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
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
            title: l10n.registerTitle,
            subtitle: l10n.registerSubtitle,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: l10n.displayNameLabel,
                        hintText: l10n.displayNameHint,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateDisplayName,
                    ),
                    const Gap(AppDimensions.s16),
                    TextFormField(
                      controller: _emailController,
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
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        hintText: l10n.passwordHint,
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                    ),
                    const Gap(AppDimensions.s16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPasswordLabel,
                        hintText: l10n.confirmPasswordHint,
                      ),
                      obscureText: true,
                      validator: _validateConfirmPassword,
                    ),
                  ],
                ),
              ),
              const Gap(AppDimensions.s24),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return FilledButton(
                    onPressed: state.isSubmitting ? null : _submit,
                    child:
                        state.isSubmitting &&
                            state.action == AuthAction.register
                        ? const CircularProgressIndicator.adaptive()
                        : Text(l10n.registerCta),
                  );
                },
              ),
              const Gap(AppDimensions.s16),
              TextButton(
                onPressed: () => context.router.maybePop(),
                child: Text(l10n.switchToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = context.l10n;
    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordValidationRequired;
    }
    if (value != _passwordController.text) {
      return l10n.confirmPasswordValidationMismatch;
    }
    return null;
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.displayNameValidationRequired;
    }
    return null;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      RegisterSubmitted(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}
