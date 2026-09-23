sealed class SessionEvent {}

class SessionChanged extends SessionEvent {
  SessionChanged(this.authenticated);
  final bool authenticated;
}

class SignOutRequested extends SessionEvent {}
