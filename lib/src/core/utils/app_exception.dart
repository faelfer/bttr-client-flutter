class AppException implements Exception {
  const AppException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

String errorMessage(Object error) => error is AppException
    ? error.message
    : 'Não foi possível concluir a operação. Tente novamente.';
