import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/auth.dart';

@RoutePage()
class ForgotPasswordPage extends StatelessWidget implements AutoRouteWrapper {
  const ForgotPasswordPage({
    this.prefillEmail,
    super.key,
  });

  final String? prefillEmail;

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ForgotPasswordView(prefillEmail: prefillEmail);
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView({this.prefillEmail});

  final String? prefillEmail;

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpRequested = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.otpSent) {
          setState(() {
            _otpRequested = true;
          });
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.passwordResetOtpSent)),
            );
          context.read<AuthBloc>().add(const AuthStatusCleared());
        }

        if (state.status == AuthStatus.passwordReset) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.passwordResetSuccess)),
            );
          unawaited(context.router.maybePop());
        }

        if (state.status == AuthStatus.failure && state.failure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.failure!.localizedMessage(context))),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: context.responsiveContentPadding,
            child: AuthFormCard(
              title: l10n.forgotPasswordTitle,
              subtitle: l10n.forgotPasswordSubtitle,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          hintText: l10n.emailHint,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const Gap(AppDimensions.s16),
                      if (_otpRequested) ...[
                        TextFormField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            labelText: l10n.otpCodeLabel,
                            hintText: l10n.otpCodeHint,
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateOtp,
                        ),
                        const Gap(AppDimensions.s16),
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            hintText: l10n.passwordHint,
                          ),
                          obscureText: true,
                          validator: _validatePassword,
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(AppDimensions.s24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return FilledButton(
                      onPressed: state.isSubmitting
                          ? null
                          : _otpRequested
                          ? _resetPassword
                          : _requestOtp,
                      child: state.isSubmitting
                          ? const CircularProgressIndicator.adaptive()
                          : Text(
                              _otpRequested
                                  ? l10n.resetPasswordCta
                                  : l10n.sendOtpCta,
                            ),
                    );
                  },
                ),
              ],
            ),
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

  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.otpValidationRequired;
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

  void _requestOtp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      ForgotPasswordOtpRequested(email: _emailController.text.trim()),
    );
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      ResetPasswordSubmitted(
        email: _emailController.text.trim(),
        otpCode: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      ),
    );
  }
}
