import 'package:tricount/features/auth/data/models/auth_token_model.dart';

/// Contract for all authentication operations.
///
/// Methods throw AppException on failure — callers (BLoCs) must catch it.
abstract interface class AuthRepository {
  /// Authenticates with email + password.
  /// Returns an AuthToken on success.
  Future<AuthToken> login({
    required String email,
    required String password,
  });

  /// Sends a password-reset email.
  /// Throws AppException if the address is not registered.
  Future<void> forgotPassword({required String email});
}
