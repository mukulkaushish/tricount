import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';

/// Bottom sheet that collects the user's email and sends a reset link.
///
/// Shows inline progress while the API call is in flight, then auto-dismisses
/// on success or displays an error message.
Future<void> showForgotPasswordSheet(
  BuildContext context, {
  String? prefillEmail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: _ForgotPasswordSheet(prefillEmail: prefillEmail),
    ),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({this.prefillEmail});
  final String? prefillEmail;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final _controller = TextEditingController(text: widget.prefillEmail);
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _controller.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _errorText = 'Enter a valid email address');
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _errorText = null);
    unawaited(HapticFeedback.lightImpact());
    context.read<AuthBloc>().add(ForgotPasswordRequested(email: email));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSent) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Reset link sent — check your inbox.',
              ),
              backgroundColor: scheme.primary,
            ),
          );
        } else if (state is AuthFailure) {
          setState(() => _errorText = state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
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

                Text(
                  'Reset Password',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const Gap(AppDimensions.s8),
                Text(
                  "Enter your email and we'll send you a reset link.",
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppDimensions.s24),

                TextField(
                  controller: _controller,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    errorText: _errorText,
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
                    onPressed: isLoading ? null : _submit,
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
                        : const Text('Send Reset Link'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
