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

final class LoginWithGoogleRequested extends AuthEvent {
  const LoginWithGoogleRequested();
}

final class LoginWithAppleRequested extends AuthEvent {
  const LoginWithAppleRequested();
}

final class ForgotPasswordRequested extends AuthEvent {
  const ForgotPasswordRequested({required this.email});
  final String email;
}
