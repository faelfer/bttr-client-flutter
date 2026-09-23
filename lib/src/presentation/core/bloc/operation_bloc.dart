import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_exception.dart';
import 'operation_event.dart';
import 'operation_state.dart';
export 'operation_event.dart';
export 'operation_state.dart';

/// Shared request lifecycle; domain decisions stay in the injected use cases.
class OperationBloc<T> extends Bloc<OperationEvent<T>, OperationState<T>> {
  OperationBloc({T? initialData, bool initiallyLoaded = false})
    : super(OperationState(data: initialData, loaded: initiallyLoaded)) {
    on<LoadRequested<T>>((event, emit) async {
      if (state.busy) return;
      emit(OperationState(data: state.data, busy: true));
      try {
        final data = await event.load();
        emit(OperationState(data: data, loaded: true));
      } catch (error) {
        emit(OperationState(error: errorMessage(error)));
      }
    });
    on<MutationRequested<T>>((event, emit) async {
      if (state.busy) return;
      emit(OperationState(data: state.data, loaded: state.loaded, busy: true));
      try {
        final message = await event.execute();
        emit(
          OperationState(
            data: state.data,
            loaded: state.loaded,
            success: message,
          ),
        );
      } catch (error) {
        emit(
          OperationState(
            data: state.data,
            loaded: state.loaded,
            error: errorMessage(error),
          ),
        );
      }
    });
  }
}
