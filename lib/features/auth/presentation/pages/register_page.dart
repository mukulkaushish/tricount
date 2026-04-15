import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tricount/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:tricount/features/auth/presentation/widgets/auth_page_layouts.dart';
import 'package:tricount/router/router.dart';
import 'package:tricount/shared/shared.dart';

@RoutePage()
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(final BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          unawaited(context.router.replaceAll([const HomeRoute()]));
        } else if (state is AuthFailure) {
          unawaited(HapticFeedback.heavyImpact());
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.colorScheme.error,
              ),
            );
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: context.colorScheme.onPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            forceMaterialTransparency: true,
            shape: const Border(), // removes iOS hairline on transparent AppBar
          ),
          body: const AdaptiveLayout(
            compact: _CompactRegisterLayout(),
            expanded: _ExpandedRegisterLayout(),
          ),
        ),
      ),
    );
  }
}

class _CompactRegisterLayout extends StatelessWidget {
  const _CompactRegisterLayout();

  @override
  Widget build(final BuildContext context) => const AuthCompactLayout(
    formCard: AuthFormCard(
      title: 'Create account',
      child: _RegisterForm(),
    ),
  );
}

class _ExpandedRegisterLayout extends StatelessWidget {
  const _ExpandedRegisterLayout();

  @override
  Widget build(final BuildContext context) => const AuthExpandedLayout(
    title: 'Create account',
    subtitle: 'Split bills with your people.',
    formContent: _RegisterForm(),
  );
}

// ── Register form ────────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _displayNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    var valid = true;
    setState(() {
      _displayNameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final name = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _displayNameError = 'Display name is required');
      valid = false;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      valid = false;
    } else if (!email.isValidEmail) {
      setState(() => _emailError = 'Enter a valid email address');
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      valid = false;
    } else if (password.length < 8) {
      setState(
        () => _passwordError = 'Password must be at least 8 characters',
      );
      valid = false;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      valid = false;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      valid = false;
    }

    if (!valid) unawaited(HapticFeedback.heavyImpact());
    return valid;
  }

  void _onRegisterPressed() {
    if (!_validate()) return;
    unawaited(HapticFeedback.lightImpact());
    context.read<AuthBloc>().add(
      RegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _displayNameController,
                focusNode: _displayNameFocus,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                onChanged: (_) {
                  if (_displayNameError != null) {
                    setState(() => _displayNameError = null);
                  }
                },
                onSubmitted: (_) => _emailFocus.requestFocus(),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  errorText: _displayNameError,
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    size: AppDimensions.iconMd,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Gap(AppDimensions.s12),
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  errorText: _emailError,
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    size: AppDimensions.iconMd,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Gap(AppDimensions.s12),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
                onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                decoration: InputDecoration(
                  hintText: 'Password (8+ characters)',
                  errorText: _passwordError,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: AppDimensions.iconMd,
                    color: scheme.onSurfaceVariant,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppDimensions.iconMd,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const Gap(AppDimensions.s12),
              TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                enabled: !isLoading,
                obscureText: _obscureConfirmPassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) {
                  if (_confirmPasswordError != null) {
                    setState(() => _confirmPasswordError = null);
                  }
                },
                onSubmitted: (_) => _onRegisterPressed(),
                decoration: InputDecoration(
                  hintText: 'Confirm password',
                  errorText: _confirmPasswordError,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: AppDimensions.iconMd,
                    color: scheme.onSurfaceVariant,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppDimensions.iconMd,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
              ),
              const Gap(AppDimensions.s28),
              SizedBox(
                height: AppDimensions.buttonHeight,
                child: FilledButton(
                  onPressed: isLoading ? null : _onRegisterPressed,
                  child: isLoading
                      ? SizedBox.square(
                          dimension: AppDimensions.spinnerSize,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: AppDimensions.spinnerStroke,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              scheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const Gap(AppDimensions.s20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: context.maybePop,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.s6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Sign in',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
