import 'package:equatable/equatable.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/core/network/network.dart';

enum AuthAction {
  apple,
  google,
  login,
  passkey,
  register,
  requestPasswordResetOtp,
  resetPassword,
}

enum AuthStatus {
  authenticated,
  failure,
  idle,
  otpSent,
  passwordReset,
  submitting,
}

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.action,
    this.failure,
    this.passwordResetEmail,
    this.session,
  });

  const AuthState.initial() : this(status: AuthStatus.idle);

  final AuthAction? action;
  final AppException? failure;
  final String? passwordResetEmail;
  final AppSession? session;
  final AuthStatus status;

  bool get isSubmitting => status == AuthStatus.submitting;

  AuthState copyWith({
    AuthAction? action,
    AppException? failure,
    bool resetFailure = false,
    String? passwordResetEmail,
    bool resetPasswordResetEmail = false,
    AppSession? session,
    bool resetSession = false,
    AuthStatus? status,
  }) {
    return AuthState(
      status: status ?? this.status,
      action: action ?? this.action,
      failure: resetFailure ? null : failure ?? this.failure,
      passwordResetEmail: resetPasswordResetEmail
          ? null
          : passwordResetEmail ?? this.passwordResetEmail,
      session: resetSession ? null : session ?? this.session,
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    failure,
    passwordResetEmail,
    session,
  ];
}
