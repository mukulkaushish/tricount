import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/auth/app_session.dart';
import 'package:tricount/core/auth/auth_session_store.dart';
import 'package:tricount/core/network/network.dart';
import 'package:tricount/features/auth/domain/domain.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required AuthSessionStore sessionStore,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _sessionStore = sessionStore,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       super(const SessionInitial()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionReloadRequested>(_onSessionStarted);
    on<SessionSignedIn>(_onSessionSignedIn);
    on<SessionSignedOutRequested>(_onSessionSignedOutRequested);
  }

  final AuthSessionStore _sessionStore;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> _onSessionSignedIn(
    SessionSignedIn event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionAuthenticated(session: event.session));
  }

  Future<void> _onSessionSignedOutRequested(
    SessionSignedOutRequested event,
    Emitter<SessionState> emit,
  ) async {
    await _sessionStore.clearTokens();
    emit(const SessionUnauthenticated());
  }

  Future<void> _onSessionStarted(
    SessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final tokens = await _sessionStore.readTokens();
    if (tokens == null) {
      emit(const SessionUnauthenticated());
      return;
    }

    final result = await _getCurrentUserUseCase();
    result.match(
      (failure) async {
        await _sessionStore.clearTokens();
        emit(SessionFailure(failure: failure));
      },
      (user) => emit(
        SessionAuthenticated(
          session: AppSession(tokens: tokens, user: user),
        ),
      ),
    );
  }
}
