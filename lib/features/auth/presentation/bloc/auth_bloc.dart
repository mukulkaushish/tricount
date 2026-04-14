import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/features/auth/domain/domain.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_event.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required SendPasswordResetOtpUseCase sendPasswordResetOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithAppleUseCase signInWithAppleUseCase,
    required SignInWithPasskeyUseCase signInWithPasskeyUseCase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _sendPasswordResetOtpUseCase = sendPasswordResetOtpUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signInWithAppleUseCase = signInWithAppleUseCase,
       _signInWithPasskeyUseCase = signInWithPasskeyUseCase,
       super(const AuthState.initial()) {
    on<AppleSignInRequested>(
      _onAppleSignInRequested,
      transformer: droppable(),
    );
    on<AuthStatusCleared>(_onAuthStatusCleared);
    on<ForgotPasswordOtpRequested>(
      _onForgotPasswordOtpRequested,
      transformer: droppable(),
    );
    on<GoogleSignInRequested>(
      _onGoogleSignInRequested,
      transformer: droppable(),
    );
    on<LoginSubmitted>(_onLoginSubmitted, transformer: droppable());
    on<PasskeySignInRequested>(
      _onPasskeySignInRequested,
      transformer: droppable(),
    );
    on<RegisterSubmitted>(_onRegisterSubmitted, transformer: droppable());
    on<ResetPasswordSubmitted>(
      _onResetPasswordSubmitted,
      transformer: droppable(),
    );
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final SendPasswordResetOtpUseCase _sendPasswordResetOtpUseCase;
  final SignInWithAppleUseCase _signInWithAppleUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithPasskeyUseCase _signInWithPasskeyUseCase;

  Future<void> _onAppleSignInRequested(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.apple,
        resetFailure: true,
        resetSession: true,
        status: AuthStatus.submitting,
      ),
    );

    final result = await _signInWithAppleUseCase();
    result.match(
      (failure) => emit(
        state.copyWith(
          action: AuthAction.apple,
          failure: failure,
          resetSession: true,
          status: AuthStatus.failure,
        ),
      ),
      (session) => emit(
        state.copyWith(
          action: AuthAction.apple,
          resetFailure: true,
          session: session,
          status: AuthStatus.authenticated,
        ),
      ),
    );
  }

  void _onAuthStatusCleared(
    AuthStatusCleared event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        resetFailure: true,
        resetPasswordResetEmail: true,
        resetSession: true,
        status: AuthStatus.idle,
      ),
    );
  }

  Future<void> _onForgotPasswordOtpRequested(
    ForgotPasswordOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.requestPasswordResetOtp,
        passwordResetEmail: event.email,
        resetFailure: true,
        status: AuthStatus.submitting,
      ),
    );

    final result = await _sendPasswordResetOtpUseCase(email: event.email);
    result.match(
      (failure) => emit(
        state.copyWith(
          action: AuthAction.requestPasswordResetOtp,
          failure: failure,
          status: AuthStatus.failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          action: AuthAction.requestPasswordResetOtp,
          passwordResetEmail: event.email,
          resetFailure: true,
          status: AuthStatus.otpSent,
        ),
      ),
    );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.google,
        resetFailure: true,
        resetSession: true,
        status: AuthStatus.submitting,
      ),
    );

    final result = await _signInWithGoogleUseCase();
    result.match(
      (failure) => emit(
        state.copyWith(
          action: AuthAction.google,
          failure: failure,
          resetSession: true,
          status: AuthStatus.failure,
        ),
      ),
      (session) => emit(
        state.copyWith(
          action: AuthAction.google,
          resetFailure: true,
          session: session,
          status: AuthStatus.authenticated,
        ),
      ),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.login,
        resetFailure: true,
        resetSession: true,
        status: AuthStatus.submitting,
      ),
    );

    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          action: AuthAction.login,
          failure: failure,
          resetSession: true,
          status: AuthStatus.failure,
        ),
      ),
      (session) => emit(
        state.copyWith(
          action: AuthAction.login,
          resetFailure: true,
          session: session,
          status: AuthStatus.authenticated,
        ),
      ),
    );
  }

  Future<void> _onPasskeySignInRequested(
    PasskeySignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.passkey,
        resetFailure: true,
        resetSession: true,
        status: AuthStatus.submitting,
      ),
    );

    final result = await _signInWithPasskeyUseCase(email: event.email);
    result.match(
      (failure) => emit(
        state.copyWith(
          action: AuthAction.passkey,
          failure: failure,
          resetSession: true,
          status: AuthStatus.failure,
        ),
      ),
      (session) => emit(
        state.copyWith(
          action: AuthAction.passkey,
          resetFailure: true,
          session: session,
          status: AuthStatus.authenticated,
        ),
      ),
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.register,
        resetFailure: true,
        resetSession: true,
        status: AuthStatus.submitting,
      ),
    );

    final result = await _registerUseCase(
      displayName: event.displayName,
      email: event.email,
      password: event.password,
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          action: AuthAction.register,
          failure: failure,
          resetSession: true,
          status: AuthStatus.failure,
        ),
      ),
      (session) => emit(
        state.copyWith(
          action: AuthAction.register,
          resetFailure: true,
          session: session,
          status: AuthStatus.authenticated,
        ),
      ),
    );
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        action: AuthAction.resetPassword,
        passwordResetEmail: event.email,
        resetFailure: true,
        status: AuthStatus.submitting,
      ),
    );

    final result = await _resetPasswordUseCase(
      email: event.email,
      otpCode: event.otpCode,
      newPassword: event.newPassword,
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          action: AuthAction.resetPassword,
          failure: failure,
          status: AuthStatus.failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          action: AuthAction.resetPassword,
          passwordResetEmail: event.email,
          resetFailure: true,
          status: AuthStatus.passwordReset,
        ),
      ),
    );
  }
}
