sealed class OperationEvent<T> {}

class LoadRequested<T> extends OperationEvent<T> {
  LoadRequested(this.load);
  final Future<T> Function() load;
}

class MutationRequested<T> extends OperationEvent<T> {
  MutationRequested(this.execute);
  final Future<String> Function() execute;
}
