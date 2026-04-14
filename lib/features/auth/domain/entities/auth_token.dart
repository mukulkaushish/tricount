import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated session's token pair.
final class AuthToken extends Equatable {
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
