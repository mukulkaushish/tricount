part of 'session_bloc.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

final class SessionInitial extends SessionState {
  const SessionInitial();
}

final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated({required this.session});

  final AppSession session;

  @override
  List<Object?> get props => [session];
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

final class SessionFailure extends SessionState {
  const SessionFailure({required this.failure});

  final AppException failure;

  @override
  List<Object?> get props => [failure];
}
