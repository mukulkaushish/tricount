import 'package:equatable/equatable.dart';
import 'package:tricount/core/error/app_exception.dart';
import 'package:tricount/features/auth/domain/entities/auth_token.dart';

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
  List<Object?> get props => [token];
}

final class RegisterSuccess extends AuthState {
  const RegisterSuccess({required this.token});

  final AuthToken token;

  @override
  List<Object?> get props => [token];
}

final class AuthFailure extends AuthState {
  const AuthFailure({required this.exception});

  final AppException exception;

  String get message => exception.message;

  @override
  List<Object?> get props => [exception.message];
}

final class ForgotPasswordSent extends AuthState {
  const ForgotPasswordSent();
}

final class ResetPasswordSuccess extends AuthState {
  const ResetPasswordSuccess();
}
