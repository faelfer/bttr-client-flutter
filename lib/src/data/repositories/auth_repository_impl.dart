import '../../core/utils/app_exception.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/api_client.dart';
import '../datasources/session_store.dart';
import '../models/api_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.api, this.session);
  final ApiClient api;
  final SessionStore session;
  @override
  bool get authenticated => session.authenticated;
  @override
  Stream<bool> get sessionChanges => session.changes;
  @override
  Future<void> signIn(String email, String password) async {
    final result = await api.request(
      'POST',
      '/users/sign_in',
      public: true,
      body: {'email': email, 'password': password},
    );
    final token = result['token'];
    if (token is! String || token.trim().isEmpty) {
      throw const AppException('O servidor não retornou uma sessão válida.');
    }
    await session.set(token);
  }

  @override
  Future<String> signUp(String username, String email, String password) =>
      api.message(
        'POST',
        '/users/sign_up',
        public: true,
        body: {'username': username, 'email': email, 'password': password},
      );
  @override
  Future<String> forgotPassword(String email) => api.message(
    'POST',
    '/users/forgot_password',
    public: true,
    body: {'email': email},
  );
  @override
  Future<User> profile() async => ApiModels.user(
    (await api.request('GET', '/users/profile'))['user']
        as Map<String, dynamic>,
  );
  @override
  Future<String> updateProfile(String username, String email) => api.message(
    'PATCH',
    '/users/profile',
    body: {'username': username, 'email': email},
  );
  @override
  Future<String> deleteProfile() async {
    final message = await api.message('DELETE', '/users/profile');
    await session.clear();
    return message;
  }

  @override
  Future<String> redefinePassword(String password, String newPassword) =>
      api.message(
        'POST',
        '/users/redefine_password',
        body: {'password': password, 'new_password': newPassword},
      );
  @override
  Future<void> signOut() => session.clear();
}
