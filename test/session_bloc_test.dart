import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bttr_client_flutter/src/domain/repositories/auth_repository.dart';
import 'package:bttr_client_flutter/src/domain/usecases/auth_usecases.dart';
import 'package:bttr_client_flutter/src/presentation/pages/auth/bloc/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late StreamController<bool> sessionChanges;

  setUp(() {
    repository = MockAuthRepository();
    sessionChanges = StreamController<bool>.broadcast(sync: true);
    when(
      () => repository.sessionChanges,
    ).thenAnswer((_) => sessionChanges.stream);
  });

  tearDown(() => sessionChanges.close());

  blocTest<SessionBloc, SessionState>(
    'acompanha entrada e saída informadas pelo repositório',
    setUp: () => when(() => repository.authenticated).thenReturn(false),
    build: () => SessionBloc(AuthUseCases(repository)),
    act: (_) {
      sessionChanges.add(true);
      sessionChanges.add(false);
    },
    expect: () => [
      isA<SessionState>().having(
        (state) => state.authenticated,
        'authenticated',
        isTrue,
      ),
      isA<SessionState>().having(
        (state) => state.authenticated,
        'authenticated',
        isFalse,
      ),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'pedido de saída chama o repositório e atualiza a sessão',
    setUp: () {
      when(() => repository.authenticated).thenReturn(true);
      when(() => repository.signOut()).thenAnswer((_) async {
        sessionChanges.add(false);
      });
    },
    build: () => SessionBloc(AuthUseCases(repository)),
    act: (bloc) => bloc.add(SignOutRequested()),
    expect: () => [
      isA<SessionState>().having(
        (state) => state.authenticated,
        'authenticated',
        isFalse,
      ),
    ],
    verify: (_) => verify(() => repository.signOut()).called(1),
  );
}
