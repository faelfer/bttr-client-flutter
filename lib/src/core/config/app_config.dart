import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../enums/environment.dart';

class AppConfig {
  const AppConfig({required this.environment, required this.apiUrl});
  final Environment environment;
  final Uri apiUrl;

  static Future<AppConfig> load() async {
    final environment = Environment.parse(
      const String.fromEnvironment('FLUTTER_ENV', defaultValue: 'prod'),
    );
    await dotenv.load(fileName: environment.asset);
    const override = String.fromEnvironment('API_URL');
    final value = override.isNotEmpty ? override : dotenv.env['API_URL'] ?? '';
    return AppConfig.fromValues(environment, value);
  }

  factory AppConfig.fromValues(Environment environment, String value) {
    final uri = Uri.tryParse(value.trim().replaceAll(RegExp(r'/+$'), ''));
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException(
        'Configure API_URL com a URL completa da API. '
        'Para desenvolvimento, execute com --dart-define=FLUTTER_ENV=dev.',
      );
    }
    if (environment != Environment.dev && uri.scheme != 'https') {
      throw const FormatException('Use HTTPS para a API de QA e produção.');
    }
    return AppConfig(environment: environment, apiUrl: uri);
  }
}
