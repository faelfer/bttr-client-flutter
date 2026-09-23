import '../entities/user.dart';

abstract interface class AuthRepository {
  bool get authenticated;
  Stream<bool> get sessionChanges;
  Future<void> signIn(String email, String password);
  Future<String> signUp(String username, String email, String password);
  Future<String> forgotPassword(String email);
  Future<User> profile();
  Future<String> updateProfile(String username, String email);
  Future<String> deleteProfile();
  Future<String> redefinePassword(String password, String newPassword);
  Future<void> signOut();
}
