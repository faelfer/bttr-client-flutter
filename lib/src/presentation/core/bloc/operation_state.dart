class OperationState<T> {
  const OperationState({
    this.data,
    this.busy = false,
    this.loaded = false,
    this.error,
    this.success,
  });
  final T? data;
  final bool busy, loaded;
  final String? error, success;
}
