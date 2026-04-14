import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tricount/features/auth/presentation/widgets/forgot_password_sheet.dart';

/// Credential form for the login screen.
///
/// Handles: email + password fields, forgot-password link, login CTA,
/// social login buttons, and sign-up link.
///
/// Adaptive behaviors: AutofillGroup, TextInputAction chain, HapticFeedback,
/// CircularProgressIndicator.adaptive, keyboard-safe layout.
class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validate() {
    var valid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

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
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      valid = false;
    }

    if (!valid) unawaited(HapticFeedback.heavyImpact());
    return valid;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _onLoginPressed() {
    if (!_validate()) return;
    unawaited(HapticFeedback.lightImpact());
    context.read<AuthBloc>().add(
          LoginWithEmailRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _onGooglePressed() {
    unawaited(HapticFeedback.lightImpact());
    // TODO(auth): obtain a real Google ID token via google_sign_in package,
    // then dispatch: LoginWithGoogleRequested(idToken: idToken)
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Google sign-in coming soon.')),
      );
  }

  void _onApplePressed() {
    unawaited(HapticFeedback.lightImpact());
    // TODO(auth): obtain a real Apple ID token via sign_in_with_apple package,
    // then dispatch: LoginWithAppleRequested(idToken: idToken)
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Apple sign-in coming soon.')),
      );
  }

  void _onForgotPasswordPressed() {
    unawaited(showForgotPasswordSheet(
      context,
      prefillEmail: _emailController.text.trim(),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
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
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EmailField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocus: _passwordFocus,
                  errorText: _emailError,
                  enabled: !isLoading,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 100.ms,
                      duration: 350.ms,
                    ),
                const Gap(AppDimensions.s12),
                _PasswordField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscure: _obscurePassword,
                  errorText: _passwordError,
                  enabled: !isLoading,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  onSubmitted: (_) => _onLoginPressed(),
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 150.ms,
                      duration: 350.ms,
                    ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : _onForgotPasswordPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.s8,
                        vertical: AppDimensions.s4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Gap(AppDimensions.s20),
                _LoginButton(
                  isLoading: isLoading,
                  onPressed: _onLoginPressed,
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 200.ms,
                      duration: 350.ms,
                    ),
                const Gap(AppDimensions.s24),
                _OrDivider()
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 350.ms),
                const Gap(AppDimensions.s20),
                _SocialButton(
                  iconAsset: 'assets/icons/ic_google.svg',
                  label: 'Continue with Google',
                  onPressed: isLoading ? null : _onGooglePressed,
                ).animate().fadeIn(delay: 300.ms, duration: 350.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 300.ms,
                      duration: 350.ms,
                    ),
                const Gap(AppDimensions.s10),
                _SocialButton(
                  iconAsset: 'assets/icons/ic_apple.svg',
                  label: 'Continue with Apple',
                  onPressed: isLoading ? null : _onApplePressed,
                  colorize: false,
                ).animate().fadeIn(delay: 350.ms, duration: 350.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 350.ms,
                      duration: 350.ms,
                    ),
                const Gap(AppDimensions.s24),
                _SignUpRow()
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 350.ms),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.enabled,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Email address',
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        onChanged: onChanged,
        onSubmitted: (_) => nextFocus.requestFocus(),
        decoration: InputDecoration(
          hintText: 'your@email.com',
          errorText: errorText,
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            size: AppDimensions.iconMd,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.enabled,
    required this.onToggleObscure,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggleObscure;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Password',
      obscured: true,
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        obscureText: obscure,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'Password',
          errorText: errorText,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            size: AppDimensions.iconMd,
            color: context.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: Semantics(
            label: obscure ? 'Show password' : 'Hide password',
            button: true,
            child: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppDimensions.iconMd,
                color: context.colorScheme.onSurfaceVariant,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.buttonHeight,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colorScheme.onPrimary,
                  ),
                ),
              )
            : const Text('Login'),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: context.colorScheme.outline,
            thickness: 1,
            endIndent: AppDimensions.s12,
          ),
        ),
        Text(
          'or',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Divider(
            color: context.colorScheme.outline,
            thickness: 1,
            indent: AppDimensions.s12,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.iconAsset,
    required this.label,
    required this.onPressed,
    this.colorize = true,
  });

  final String iconAsset;
  final String label;
  final VoidCallback? onPressed;

  /// When false the SVG is drawn in [ColorScheme.onSurface] — used for the
  /// Apple button which follows a monochrome HIG requirement.
  final bool colorize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: AppDimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20,
              height: 20,
              colorFilter: colorize
                  ? null
                  : ColorFilter.mode(
                      isDark ? Colors.white : Colors.black,
                      BlendMode.srcIn,
                    ),
            ),
            const Gap(AppDimensions.s12),
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignUpRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO(auth): navigate to register screen
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign up',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
