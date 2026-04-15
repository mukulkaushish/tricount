import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';

/// Shows the two-step password-reset bottom sheet.
///
/// Step 1: User enters email → server sends OTP code to that address.
/// Step 2: User enters the OTP code + new password → server resets.
///
/// Pass [prefillEmail] to pre-populate the email field from the login form.
Future<void> showForgotPasswordSheet(
  final BuildContext context, {
  final String? prefillEmail,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => BlocProvider.value(
    value: context.read<AuthBloc>(),
    child: _ForgotPasswordSheet(prefillEmail: prefillEmail),
  ),
);

// ── Widget ───────────────────────────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({this.prefillEmail});
  final String? prefillEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  // Step 1 — email
  late final _emailController = TextEditingController(
    text: widget.prefillEmail,
  );

  // Step 2 — OTP + new password
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _step2 = false; // false = email step, true = OTP step
  bool _obscurePassword = true;
  String? _emailError;
  String? _codeError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _codeFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  void _submitEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _emailError = null);
    unawaited(HapticFeedback.lightImpact());
    context.read<AuthBloc>().add(ForgotPasswordRequested(email: email));
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────────

  void _submitReset() {
    var valid = true;
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _codeError = null;
      _passwordError = null;
    });

    if (code.isEmpty) {
      setState(() => _codeError = 'Enter the code from your email');
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Enter a new password');
      valid = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      valid = false;
    }
    if (!valid) {
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    context.read<AuthBloc>().add(
      ResetPasswordRequested(
        email: _emailController.text.trim(),
        code: code,
        newPassword: password,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSent) {
          // Advance to OTP step.
          setState(() => _step2 = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _codeFocus.requestFocus();
          });
        } else if (state is ResetPasswordSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset — you can now log in.'),
              backgroundColor: scheme.primary,
            ),
          );
        } else if (state is AuthFailure && !_step2) {
          // Error on email step — show inline.
          setState(() => _emailError = state.message);
        } else if (state is AuthFailure && _step2) {
          // Error on OTP step — show inline.
          setState(() => _codeError = state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.s8,
              AppDimensions.pagePaddingH,
              AppDimensions.s24 + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: AppDimensions.s32,
                    height: AppDimensions.s4,
                    decoration: BoxDecoration(
                      color: scheme.outline,
                      borderRadius: BorderRadius.circular(AppDimensions.r4),
                    ),
                  ),
                ),
                const Gap(AppDimensions.s20),
                if (!_step2)
                  _EmailStep(
                    controller: _emailController,
                    errorText: _emailError,
                    isLoading: isLoading,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    onSubmit: _submitEmail,
                  )
                else
                  _OtpStep(
                    codeController: _codeController,
                    passwordController: _passwordController,
                    codeFocus: _codeFocus,
                    passwordFocus: _passwordFocus,
                    obscurePassword: _obscurePassword,
                    codeError: _codeError,
                    passwordError: _passwordError,
                    isLoading: isLoading,
                    onCodeChanged: (_) {
                      if (_codeError != null) {
                        setState(() => _codeError = null);
                      }
                    },
                    onPasswordChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _submitReset,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Step 1: email ────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Reset Password',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const Gap(AppDimensions.s8),
        Text(
          "Enter your email and we'll send you a one-time code.",
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Gap(AppDimensions.s24),
        TextField(
          controller: controller,
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => onSubmit(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'your@email.com',
            errorText: errorText,
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              size: AppDimensions.iconMd,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const Gap(AppDimensions.s20),
        SizedBox(
          height: AppDimensions.buttonHeight,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
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
                : const Text('Send Code'),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: OTP + new password ───────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.codeController,
    required this.passwordController,
    required this.codeFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.isLoading,
    required this.onCodeChanged,
    required this.onPasswordChanged,
    required this.onToggleObscure,
    required this.onSubmit,
    this.codeError,
    this.passwordError,
  });

  final TextEditingController codeController;
  final TextEditingController passwordController;
  final FocusNode codeFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool isLoading;
  final ValueChanged<String> onCodeChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final String? codeError;
  final String? passwordError;

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the Code',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const Gap(AppDimensions.s8),
        Text(
          'Check your inbox for the one-time code, then set a new password.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Gap(AppDimensions.s24),

        // OTP code field
        TextField(
          controller: codeController,
          focusNode: codeFocus,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => passwordFocus.requestFocus(),
          onChanged: onCodeChanged,
          decoration: InputDecoration(
            hintText: 'One-time code',
            errorText: codeError,
            prefixIcon: Icon(
              Icons.pin_outlined,
              size: AppDimensions.iconMd,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const Gap(AppDimensions.s12),

        // New password field
        TextField(
          controller: passwordController,
          focusNode: passwordFocus,
          enabled: !isLoading,
          obscureText: obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => onSubmit(),
          onChanged: onPasswordChanged,
          decoration: InputDecoration(
            hintText: 'New password (8+ characters)',
            errorText: passwordError,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: AppDimensions.iconMd,
              color: scheme.onSurfaceVariant,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppDimensions.iconMd,
                color: scheme.onSurfaceVariant,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const Gap(AppDimensions.s20),

        SizedBox(
          height: AppDimensions.buttonHeight,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
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
                : const Text('Reset Password'),
          ),
        ),
      ],
    );
  }
}
