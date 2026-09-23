import 'dart:convert';
import 'dart:math';
import 'package:bttr_client_flutter/src/core/config/dependencies.dart';
import 'package:bttr_client_flutter/src/data/datasources/api_client.dart';
import 'package:bttr_client_flutter/src/data/datasources/session_store.dart';
import 'package:bttr_client_flutter/src/data/repositories/auth_repository_impl.dart';
import 'package:bttr_client_flutter/src/data/repositories/skill_repository_impl.dart';
import 'package:bttr_client_flutter/src/data/repositories/time_repository_impl.dart';
import 'package:bttr_client_flutter/src/domain/usecases/auth_usecases.dart';
import 'package:bttr_client_flutter/src/domain/usecases/calculate_statistics.dart';
import 'package:bttr_client_flutter/src/domain/usecases/skill_usecases.dart';
import 'package:bttr_client_flutter/src/domain/usecases/time_usecases.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryStorage implements TokenStorage {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async {
    if (fail) throw StateError('storage');
    return value;
  }

  @override
  Future<void> write(String token) async {
    if (fail) throw StateError('storage');
    value = token;
  }

  @override
  Future<void> delete() async {
    if (fail) throw StateError('storage');
    value = null;
  }
}

Map<String, dynamic> skillJson(int id, {String? name, int daily = 30}) => {
  'id': id,
  'name': name ?? 'Habilidade $id',
  'daily': daily,
  'created': '2026-09-01T12:00:00Z',
};
Map<String, dynamic> timeJson(
  int id,
  Map<String, dynamic> skill, {
  int minutes = 25,
}) => {
  'id': id,
  'minutes': minutes,
  'created': '2026-09-12T15:30:00Z',
  'skill': skill,
};
final userJson = {
  'id': 1,
  'username': 'Rafael',
  'email': 'rafael@example.com',
  'created': '2026-09-01T12:00:00Z',
};

/// Test-only HTTP backend. Production has no fixture or demo mode.
class TestBackend {
  TestBackend({int skillCount = 1}) {
    skills = List.generate(skillCount, (index) => skillJson(index + 1));
    client = MockClient(handle);
    api = ApiClient(
      baseUrl: Uri.parse('https://api.example.test'),
      client: client,
      session: session,
    );
    final skillRepository = SkillRepositoryImpl(api);
    final timeRepository = TimeRepositoryImpl(api);
    dependencies = Dependencies(
      auth: AuthUseCases(AuthRepositoryImpl(api, session)),
      skills: SkillUseCases(skillRepository),
      times: TimeUseCases(timeRepository, skillRepository),
      statistics: LoadStatistics(skillRepository, timeRepository),
    );
  }
  final storage = MemoryStorage();
  late final session = SessionStore(storage);
  late final MockClient client;
  late final ApiClient api;
  late final Dependencies dependencies;
  late List<Map<String, dynamic>> skills;
  final times = <Map<String, dynamic>>[];
  final requests = <http.Request>[];
  Map<String, dynamic> user = Map.of(userJson);
  int? failNext;

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    if (failNext != null) {
      final status = failNext!;
      failNext = null;
      return response({'message': 'Falha de teste. Tente novamente.'}, status);
    }
    final path = request.url.path;
    final method = request.method;
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    final id = int.tryParse(path.split('/').last);
    if (path == '/users/sign_in') {
      return response({
        'token': 'test-token',
        'user': user,
        'message': 'Bem-vindo',
      });
    }
    if (path == '/users/profile' && method == 'GET') {
      return response({'user': user});
    }
    if (path == '/users/profile' && method == 'PATCH') user.addAll(body);
    if (path == '/skills/skills_by_page') {
      return response(page(skills, request));
    }
    if (path == '/skills/skills_from_user') return response({'skills': skills});
    if (path.startsWith('/skills/skill_by_id/')) {
      return response({'skill': skills.firstWhere((s) => s['id'] == id)});
    }
    if (path == '/skills/create_skill') {
      skills.add({...skillJson(100 + skills.length), ...body});
    }
    if (path.startsWith('/skills/update_skill_by_id/')) {
      skills.firstWhere((s) => s['id'] == id).addAll(body);
    }
    if (path.startsWith('/skills/delete_skill_by_id/')) {
      skills.removeWhere((s) => s['id'] == id);
      times.removeWhere((t) => (t['skill'] as Map)['id'] == id);
    }
    if (path == '/times/times_by_page') return response(page(times, request));
    if (path == '/times/times_by_date') {
      return response({
        'times': times
            .where(
              (t) =>
                  '${(t['skill'] as Map)['id']}' ==
                  request.url.queryParameters['skill_id'],
            )
            .toList(),
      });
    }
    if (path.startsWith('/times/time_by_id/')) {
      return response({'time': times.firstWhere((t) => t['id'] == id)});
    }
    if (path == '/times/create_time') {
      times.insert(
        0,
        timeJson(
          100 + times.length,
          skills.firstWhere((s) => s['id'] == body['skill_id']),
          minutes: body['minutes'] as int,
        ),
      );
    }
    if (path.startsWith('/times/update_time_by_id/')) {
      final entry = times.firstWhere((t) => t['id'] == id);
      entry['minutes'] = body['minutes'];
      entry['skill'] = skills.firstWhere((s) => s['id'] == body['skill_id']);
    }
    if (path.startsWith('/times/delete_time_by_id/')) {
      times.removeWhere((t) => t['id'] == id);
    }
    return response({'message': 'Operação realizada com sucesso.'});
  }

  Map<String, dynamic> page(
    List<Map<String, dynamic>> items,
    http.Request request,
  ) {
    final page = int.parse(request.url.queryParameters['page']!);
    final start = min((page - 1) * 5, items.length),
        end = min(page * 5, items.length);
    return {
      'count': items.length,
      'next': end < items.length
          ? 'https://api.example.test?page=${page + 1}'
          : null,
      'previous': page > 1 ? 'https://api.example.test?page=${page - 1}' : null,
      'results': items.sublist(start, end),
    };
  }

  static http.Response response(Object body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
  Future<void> dispose() async {
    api.close();
    await session.dispose();
  }
}
