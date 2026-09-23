import '../../core/utils/app_exception.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import 'validation.dart';

class AuthUseCases {
  const AuthUseCases(this.repository);
  final AuthRepository repository;
  bool get authenticated => repository.authenticated;
  Stream<bool> get sessionChanges => repository.sessionChanges;

  Future<void> signIn(String email, String password) {
    Validation.require(Validation.email(email));
    Validation.require(Validation.password(password));
    return repository.signIn(email.trim(), password);
  }

  Future<String> signUp(String name, String email, String password) {
    Validation.require(Validation.name(name));
    Validation.require(Validation.email(email));
    Validation.require(Validation.password(password, isNew: true));
    return repository.signUp(name.trim(), email.trim(), password);
  }

  Future<String> forgotPassword(String email) {
    Validation.require(Validation.email(email));
    return repository.forgotPassword(email.trim());
  }

  Future<User> profile() => repository.profile();
  Future<String> updateProfile(String name, String email) {
    Validation.require(Validation.name(name));
    Validation.require(Validation.email(email));
    return repository.updateProfile(name.trim(), email.trim());
  }

  Future<String> redefinePassword(
    String current,
    String next,
    String confirmation,
  ) {
    Validation.require(Validation.password(current));
    Validation.require(Validation.password(next, isNew: true));
    if (next != confirmation) {
      throw const AppException('As senhas não coincidem.');
    }
    return repository.redefinePassword(current, next);
  }

  Future<String> deleteProfile() => repository.deleteProfile();
  Future<void> signOut() => repository.signOut();
}
