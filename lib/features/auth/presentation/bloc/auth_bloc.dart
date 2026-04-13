import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/network/network.dart';
import 'package:tricount/features/auth/data/auth_data.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_event.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_state.dart';

export 'package:tricount/features/auth/presentation/bloc/auth_event.dart';
export 'package:tricount/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<LoginWithEmailRequested>(_onEmailLogin);
    on<LoginWithGoogleRequested>(_onGoogleLogin);
    on<LoginWithAppleRequested>(_onAppleLogin);
    on<ForgotPasswordRequested>(_onForgotPassword);
  }

  final AuthRepository _repository;

  Future<void> _onEmailLogin(
    LoginWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(token: token));
    } on AppException catch (e) {
      emit(AuthFailure(message: e.message));
    }
  }

  Future<void> _onGoogleLogin(
    LoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // TODO(auth): replace with Google OAuth → POST /v1/auth/google
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(const AuthFailure(message: 'Google sign-in coming soon.'));
  }

  Future<void> _onAppleLogin(
    LoginWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // TODO(auth): replace with Apple Sign-In → POST /v1/auth/apple
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(const AuthFailure(message: 'Apple sign-in coming soon.'));
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _repository.forgotPassword(email: event.email);
      emit(const ForgotPasswordSent());
    } on AppException catch (e) {
      emit(AuthFailure(message: e.message));
    }
  }
}
