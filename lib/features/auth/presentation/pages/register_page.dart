import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tricount/features/home/home.dart';
import 'package:tricount/shared/shared.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
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
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  String? _displayNameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    var valid = true;
    setState(() {
      _displayNameError = null;
      _emailError = null;
      _passwordError = null;
    });

    final name = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      setState(() => _displayNameError = 'Display name is required');
      valid = false;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      valid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      valid = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
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
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          unawaited(
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => HomePage(
                  displayName: _displayNameController.text.trim(),
                ),
              ),
            ),
          );
        } else if (state is AuthFailure) {
          unawaited(HapticFeedback.heavyImpact());
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
        }
      },
      child: KeyboardDismisser(
        gestures: const [
          GestureType.onTap,
          GestureType.onPanUpdateDownDirection,
        ],
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH,
                    vertical: AppDimensions.s16,
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create account',
                          style: context.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const Gap(AppDimensions.s8),
                        Text(
                          'Split bills with your people.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Gap(AppDimensions.s32),
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
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                          onSubmitted: (_) => _onRegisterPressed(),
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
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
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
                                    dimension: 22,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2.5,
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
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.s6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
