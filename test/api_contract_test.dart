import 'dart:async';
import 'dart:convert';
import 'package:bttr_client_flutter/src/core/utils/app_exception.dart';
import 'package:bttr_client_flutter/src/data/datasources/api_client.dart';
import 'package:bttr_client_flutter/src/data/datasources/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'support/test_backend.dart';

void main() {
  late TestBackend backend;
  setUp(() => backend = TestBackend());
  tearDown(() => backend.dispose());

  test('todos os métodos, caminhos e payloads do Angular', () async {
    final auth = backend.dependencies.auth;
    final skills = backend.dependencies.skills;
    final times = backend.dependencies.times;
    await auth.signIn('rafael@example.com', 'old-password');
    await auth.signUp('Rafael', 'rafael@example.com', 'Aa1!');
    await auth.forgotPassword('rafael@example.com');
    expect((await auth.profile()).username, 'Rafael');
    await auth.updateProfile('Rafa', 'rafa@example.com');
    await auth.redefinePassword('old', 'New1!', 'New1!');
    expect((await skills.list(1)).count, 1);
    await skills.all();
    await skills.get(1);
    await skills.save(name: 'Violão', daily: 30);
    await skills.save(id: 1, name: 'Inglês', daily: 45);
    await times.save(skillId: 1, minutes: 25);
    expect((await times.list(1)).results.single.minutes, 25);
    final form = await times.loadForm(id: 100);
    expect(form.selectedSkillId, 1);
    await times.save(id: 100, skillId: 1, minutes: 60);
    final stats = await backend.dependencies.statistics(
      1,
      now: DateTime(2026, 9, 12),
    );
    expect(stats.total, 60);
    await times.delete(100);
    await skills.delete(1);
    await auth.deleteProfile();

    expect(backend.requests.map((r) => '${r.method} ${r.url.path}'), [
      'POST /users/sign_in',
      'POST /users/sign_up',
      'POST /users/forgot_password',
      'GET /users/profile',
      'PATCH /users/profile',
      'POST /users/redefine_password',
      'GET /skills/skills_by_page',
      'GET /skills/skills_from_user',
      'GET /skills/skill_by_id/1',
      'POST /skills/create_skill',
      'PUT /skills/update_skill_by_id/1',
      'POST /times/create_time',
      'GET /times/times_by_page',
      'GET /skills/skills_from_user',
      'GET /times/time_by_id/100',
      'PUT /times/update_time_by_id/100',
      'GET /skills/skill_by_id/1',
      'GET /times/times_by_date',
      'DELETE /times/delete_time_by_id/100',
      'DELETE /skills/delete_skill_by_id/1',
      'DELETE /users/profile',
    ]);
    expect(jsonDecode(backend.requests[0].body), {
      'email': 'rafael@example.com',
      'password': 'old-password',
    });
    expect(jsonDecode(backend.requests[1].body), {
      'username': 'Rafael',
      'email': 'rafael@example.com',
      'password': 'Aa1!',
    });
    expect(jsonDecode(backend.requests[2].body), {
      'email': 'rafael@example.com',
    });
    expect(jsonDecode(backend.requests[4].body), {
      'username': 'Rafa',
      'email': 'rafa@example.com',
    });
    expect(jsonDecode(backend.requests[5].body), {
      'password': 'old',
      'new_password': 'New1!',
    });
    expect(jsonDecode(backend.requests[9].body), {
      'name': 'Violão',
      'daily': 30,
    });
    expect(jsonDecode(backend.requests[10].body), {
      'name': 'Inglês',
      'daily': 45,
    });
    expect(jsonDecode(backend.requests[11].body), {
      'skill_id': 1,
      'minutes': 25,
    });
    expect(jsonDecode(backend.requests[15].body), {
      'skill_id': 1,
      'minutes': 60,
    });
    expect(backend.requests[6].url.queryParameters, {'page': '1'});
    expect(backend.requests[12].url.queryParameters, {'page': '1'});
    final query = backend.requests[17].url.queryParameters;
    expect(query['skill_id'], '1');
    expect(DateTime.parse(query['date_initial']!).toLocal(), DateTime(2026, 9));
    expect(
      DateTime.parse(query['date_final']!).toLocal(),
      DateTime(2026, 9, 30, 23, 59, 59, 999),
    );
    for (final request in backend.requests.take(3)) {
      expect(request.headers['Authorization'], isNull);
    }
    for (final request in backend.requests.skip(3)) {
      expect(request.headers['Authorization'], 'Token test-token');
    }
    for (final request in backend.requests.where(
      (r) => r.method == 'DELETE' || r.method == 'GET',
    )) {
      expect(request.body, isEmpty);
    }
    expect(backend.session.authenticated, isFalse);
    expect(backend.storage.value, isNull);
  });

  test('401 privado encerra sessão; 401 público preserva sessão', () async {
    await backend.session.set('active');
    backend.failNext = 401;
    await expectLater(
      backend.dependencies.auth.signIn('a@b.com', 'senha'),
      throwsA(isA<AppException>()),
    );
    expect(backend.session.token, 'active');
    backend.failNext = 401;
    await expectLater(
      backend.dependencies.auth.profile(),
      throwsA(isA<AppException>()),
    );
    expect(backend.session.token, isNull);
  });

  test('401 atrasado de sessão antiga não encerra nova sessão', () async {
    final response = Completer<http.Response>();
    final client = ApiClient(
      baseUrl: Uri.parse('https://api.example.test'),
      session: backend.session,
      client: MockClient((_) => response.future),
    );
    addTearDown(client.close);
    await backend.session.set('old');
    final request = client.request('GET', '/users/profile');
    await backend.session.set('new');
    response.complete(http.Response('{}', 401));
    await expectLater(request, throwsA(isA<AppException>()));
    expect(backend.session.token, 'new');
  });

  test(
    'requisições recusam URL externa e desabilitam redirecionamento',
    () async {
      await expectLater(
        backend.api.request('GET', '//evil.test'),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        backend.api.request('GET', 'https://evil.test'),
        throwsA(isA<AppException>()),
      );
      await backend.dependencies.skills.all();
      expect(backend.requests.single.followRedirects, isFalse);
    },
  );

  test(
    'erros de rede, timeout e respostas inválidas têm mensagens utilizáveis',
    () async {
      for (final mode in ['network', 'timeout', 'html']) {
        final client = ApiClient(
          baseUrl: Uri.parse('https://api.example.test'),
          session: backend.session,
          timeout: const Duration(milliseconds: 1),
          client: MockClient((_) async {
            if (mode == 'network') throw http.ClientException('offline');
            if (mode == 'timeout') {
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
            return http.Response('<html>Proxy error</html>', 502);
          }),
        );
        await expectLater(
          client.request('GET', '/users/profile'),
          throwsA(isA<AppException>()),
        );
        client.close();
      }
    },
  );

  test('seleção inicial de habilidade precisa existir na lista', () async {
    expect(
      (await backend.dependencies.times.loadForm(
        selectedSkillId: 999,
      )).selectedSkillId,
      isNull,
    );
    expect(
      (await backend.dependencies.times.loadForm(
        selectedSkillId: 1,
      )).selectedSkillId,
      1,
    );
  });

  test(
    'restaura token; armazenamento indisponível mantém sessão em memória',
    () async {
      final storage = MemoryStorage()..value = 'saved';
      final session = SessionStore(storage);
      addTearDown(session.dispose);
      await session.restore();
      expect(session.token, 'saved');
      storage.fail = true;
      await session.set('in-memory');
      expect(session.token, 'in-memory');
      await session.clear();
      expect(session.authenticated, isFalse);
    },
  );
}
