part of 'session_bloc.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

final class SessionStarted extends SessionEvent {
  const SessionStarted();
}

final class SessionReloadRequested extends SessionEvent {
  const SessionReloadRequested();
}

final class SessionSignedIn extends SessionEvent {
  const SessionSignedIn({required this.session});

  final AppSession session;

  @override
  List<Object?> get props => [session];
}

final class SessionSignedOutRequested extends SessionEvent {
  const SessionSignedOutRequested();
}
