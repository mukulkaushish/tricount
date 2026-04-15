sealed class AuthEvent {
  const AuthEvent();
}

final class LoginWithEmailRequested extends AuthEvent {
  const LoginWithEmailRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Triggers the native Google Sign-In flow then exchanges the idToken
/// with the backend. The data layer handles both steps.
final class LoginWithGoogleRequested extends AuthEvent {
  const LoginWithGoogleRequested();
}

/// Triggers the native Apple Sign-In flow then exchanges the idToken
/// with the backend. The data layer handles both steps.
final class LoginWithAppleRequested extends AuthEvent {
  const LoginWithAppleRequested();
}

final class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;
}

final class ForgotPasswordRequested extends AuthEvent {
  const ForgotPasswordRequested({required this.email});

  final String email;
}

final class ResetPasswordRequested extends AuthEvent {
  const ResetPasswordRequested({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  final String email;
  final String code;
  final String newPassword;
}
