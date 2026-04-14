import 'package:equatable/equatable.dart';

import 'package:tricount/features/auth/data/auth_data.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSuccess extends AuthState {
  const AuthSuccess({required this.token});
  final AuthToken token;

  @override
  List<Object?> get props => [token.accessToken];
}

final class AuthFailure extends AuthState {
  const AuthFailure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

final class ForgotPasswordSent extends AuthState {
  const ForgotPasswordSent();
}
