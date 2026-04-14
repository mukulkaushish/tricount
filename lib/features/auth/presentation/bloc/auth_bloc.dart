import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tricount/features/auth/domain/usecases/usecases.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_event.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required final LoginUseCase loginUseCase,
    required final RegisterUseCase registerUseCase,
    required final ForgotPasswordUseCase forgotPasswordUseCase,
    required final ResetPasswordUseCase resetPasswordUseCase,
    required final LoginWithGoogleUseCase loginWithGoogleUseCase,
    required final LoginWithAppleUseCase loginWithAppleUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _loginWithAppleUseCase = loginWithAppleUseCase,
        super(const AuthInitial()) {
    on<LoginWithEmailRequested>(_onEmailLogin);
    on<LoginWithGoogleRequested>(_onGoogleLogin);
    on<LoginWithAppleRequested>(_onAppleLogin);
    on<RegisterRequested>(_onRegister);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final LoginWithAppleUseCase _loginWithAppleUseCase;

  Future<void> _onEmailLogin(
    final LoginWithEmailRequested event,
    final Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (exception) => emit(AuthFailure(exception: exception)),
      (token) => emit(AuthSuccess(token: token)),
    );
  }

  Future<void> _onGoogleLogin(
    final LoginWithGoogleRequested event,
    final Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginWithGoogleUseCase(idToken: event.idToken);
    result.fold(
      (exception) => emit(AuthFailure(exception: exception)),
      (token) => emit(AuthSuccess(token: token)),
    );
  }

  Future<void> _onAppleLogin(
    final LoginWithAppleRequested event,
    final Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginWithAppleUseCase(idToken: event.idToken);
    result.fold(
      (exception) => emit(AuthFailure(exception: exception)),
      (token) => emit(AuthSuccess(token: token)),
    );
  }

  Future<void> _onRegister(
    final RegisterRequested event,
    final Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _registerUseCase(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    result.fold(
      (exception) => emit(AuthFailure(exception: exception)),
      (token) => emit(RegisterSuccess(token: token)),
    );
  }

  Future<void> _onForgotPassword(
    final ForgotPasswordRequested event,
    final Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _forgotPasswordUseCase(email: event.email);
    result.fold(
      (exception) => emit(AuthFailure(exception: exception)),
      (_) => emit(const ForgotPasswordSent()),
    );
  }

  Future<void> _onResetPassword(
    final ResetPasswordRequested event,
    final Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _resetPasswordUseCase(
      email: event.email,
      code: event.code,
      newPassword: event.newPassword,
    );
    result.fold(
      (exception) => emit(AuthFailure(exception: exception)),
      (_) => emit(const ResetPasswordSuccess()),
    );
  }
}
