import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AppleSignInRequested extends AuthEvent {
  const AppleSignInRequested();
}

final class AuthStatusCleared extends AuthEvent {
  const AuthStatusCleared();
}

final class ForgotPasswordOtpRequested extends AuthEvent {
  const ForgotPasswordOtpRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

final class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class PasskeySignInRequested extends AuthEvent {
  const PasskeySignInRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class RegisterSubmitted extends AuthEvent {
  const RegisterSubmitted({
    required this.displayName,
    required this.email,
    required this.password,
  });

  final String displayName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [displayName, email, password];
}

final class ResetPasswordSubmitted extends AuthEvent {
  const ResetPasswordSubmitted({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });

  final String email;
  final String otpCode;
  final String newPassword;

  @override
  List<Object?> get props => [email, otpCode, newPassword];
}
