import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/auth_usecases.dart';
import 'session_event.dart';
import 'session_state.dart';
export 'session_event.dart';
export 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc(AuthUseCases auth) : super(SessionState(auth.authenticated)) {
    on<SessionChanged>(
      (event, emit) => emit(SessionState(event.authenticated)),
    );
    on<SignOutRequested>((event, emit) async => auth.signOut());
    _subscription = auth.sessionChanges.listen(
      (value) => add(SessionChanged(value)),
    );
  }
  late final StreamSubscription<bool> _subscription;
  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
