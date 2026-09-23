import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/api_client.dart';
import '../../data/datasources/session_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/skill_repository_impl.dart';
import '../../data/repositories/time_repository_impl.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/skill_usecases.dart';
import '../../domain/usecases/time_usecases.dart';
import '../../domain/usecases/calculate_statistics.dart';
import 'app_config.dart';

class Dependencies {
  Dependencies({
    required this.auth,
    required this.skills,
    required this.times,
    required this.statistics,
  });
  final AuthUseCases auth;
  final SkillUseCases skills;
  final TimeUseCases times;
  final LoadStatistics statistics;

  static Future<Dependencies> create(AppConfig config) async {
    final session = SessionStore(
      const SecureTokenStorage(
        FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        ),
      ),
    );
    await session.restore();
    final api = ApiClient(
      baseUrl: config.apiUrl,
      client: http.Client(),
      session: session,
    );
    final skills = SkillRepositoryImpl(api);
    final times = TimeRepositoryImpl(api);
    return Dependencies(
      auth: AuthUseCases(AuthRepositoryImpl(api, session)),
      skills: SkillUseCases(skills),
      times: TimeUseCases(times, skills),
      statistics: LoadStatistics(skills, times),
    );
  }
}
