import 'dart:async';
import 'package:bttr_client_flutter/src/core/utils/app_exception.dart';
import 'package:bttr_client_flutter/src/presentation/core/bloc/operation_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'bloqueia envios duplicados e mantém dados quando mutação falha',
    () async {
      final bloc = OperationBloc<String>(
        initialData: 'formulário',
        initiallyLoaded: true,
      );
      addTearDown(bloc.close);
      final pending = Completer<String>();
      var calls = 0;
      Future<String> mutate() {
        calls++;
        return pending.future;
      }

      bloc.add(MutationRequested(mutate));
      bloc.add(MutationRequested(mutate));
      await bloc.stream.firstWhere((state) => state.busy);
      final failed = bloc.stream.firstWhere((state) => state.error != null);
      pending.completeError(const AppException('Não foi possível salvar.'));
      final state = await failed;
      expect(calls, 1);
      expect(state.data, 'formulário');
      expect(state.loaded, isTrue);
      expect(state.busy, isFalse);
      expect(state.error, 'Não foi possível salvar.');
    },
  );

  test('falha de leitura permite carregar novamente', () async {
    final bloc = OperationBloc<int>();
    addTearDown(bloc.close);
    bloc.add(LoadRequested(() async => throw const AppException('offline')));
    await bloc.stream.firstWhere((state) => state.error != null);
    expect(bloc.state.loaded, isFalse);
    bloc.add(LoadRequested(() async => 42));
    await bloc.stream.firstWhere((state) => state.loaded);
    expect(bloc.state.data, 42);
    expect(bloc.state.error, isNull);
  });
}
