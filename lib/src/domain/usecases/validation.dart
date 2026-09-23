import '../../core/utils/app_exception.dart';

abstract final class Validation {
  static String? name(String? value, {int max = 100}) {
    final name = value?.trim() ?? '';
    return name.length >= 2 && name.length <= max
        ? null
        : 'Informe um nome entre 2 e $max caracteres.';
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    return email.length <= 254 &&
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : 'Informe um e-mail válido.';
  }

  static String? password(String? value, {bool isNew = false}) {
    final password = value ?? '';
    if (password.isEmpty || password.length > 128) {
      return 'Informe sua senha (até 128 caracteres).';
    }
    if (isNew &&
        (password.length < 4 ||
            !RegExp('[a-z]').hasMatch(password) ||
            !RegExp('[A-Z]').hasMatch(password) ||
            !RegExp('[0-9]').hasMatch(password) ||
            !RegExp('[^a-zA-Z0-9]').hasMatch(password))) {
      return 'Use de 4 a 128 caracteres, com maiúscula, minúscula, número e símbolo.';
    }
    return null;
  }

  static String? minutes(String? value) {
    final number = int.tryParse(value ?? '');
    return number != null && number >= 1 && number <= 1440
        ? null
        : 'Informe minutos inteiros entre 1 e 1440.';
  }

  static void require(String? error) {
    if (error != null) throw AppException(error);
  }
}
