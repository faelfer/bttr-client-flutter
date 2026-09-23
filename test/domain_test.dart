import 'package:bttr_client_flutter/src/core/config/app_config.dart';
import 'package:bttr_client_flutter/src/core/enums/environment.dart';
import 'package:bttr_client_flutter/src/core/utils/app_exception.dart';
import 'package:bttr_client_flutter/src/core/utils/formatters.dart';
import 'package:bttr_client_flutter/src/domain/entities/skill.dart';
import 'package:bttr_client_flutter/src/domain/usecases/calculate_statistics.dart';
import 'package:bttr_client_flutter/src/domain/usecases/validation.dart';
import 'package:bttr_client_flutter/src/presentation/core/routes/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_backend.dart';

void main() {
  final skill = Skill(
    id: 1,
    name: 'Inglês',
    daily: 30,
    created: DateTime(2026),
  );
  group('Estatísticas preservadas do Angular', () {
    test('dias úteis e ano bissexto', () {
      expect(workingDays(2024, 2, 29), 21);
      expect(workingDays(2026, 9, 30), 22);
    });
    test('consulta inclui último milissegundo no fuso local', () {
      final range = monthRange(DateTime(2024, 2, 10));
      expect(range.initial, DateTime(2024, 2));
      expect(range.end, DateTime(2024, 2, 29, 23, 59, 59, 999));
    });
    test('sábado não entra nos dias restantes', () {
      final stats = calculateStatistics(skill, 120, DateTime(2026, 9, 12));
      expect(
        [
          stats.goal,
          stats.ideal,
          stats.missing,
          stats.remaining,
          stats.percentage,
          stats.suggestion,
        ],
        [660, 270, 150, 540, 18, 42],
      );
    });
    test('inclui hoje na sugestão quando é dia útil', () {
      expect(
        calculateStatistics(skill, 0, DateTime(2026, 9, 1)).suggestion,
        30,
      );
    });
    test('ultrapassar meta preserva percentual acima de 100', () {
      final stats = calculateStatistics(skill, 800, DateTime(2026, 9, 30));
      expect(
        [stats.percentage, stats.missing, stats.remaining, stats.suggestion],
        [121, 0, 0, 0],
      );
    });
    test('último fim de semana não divide por zero', () {
      expect(
        calculateStatistics(skill, 0, DateTime(2026, 1, 31)).suggestion,
        660,
      );
    });
    for (final entry in {
      0: '0min',
      30: '30min',
      60: '1h',
      125: '2h 5min',
      1440: '24h',
    }.entries) {
      test(
        'formata ${entry.key} minutos',
        () => expect(durationLabel(entry.key), entry.value),
      );
    }
  });

  group('Validações', () {
    test('nomes, espaços e limites', () {
      expect(Validation.name('  '), isNotNull);
      expect(Validation.name(' a '), isNotNull);
      expect(Validation.name('  Rafael  '), isNull);
      expect(Validation.name('a' * 101), isNotNull);
      expect(Validation.name('a' * 120, max: 120), isNull);
    });
    test('senha existente não impõe composição; senha nova exige', () {
      expect(Validation.password('simples'), isNull);
      expect(Validation.password('simples', isNew: true), isNotNull);
      expect(Validation.password('Ab1!', isNew: true), isNull);
      expect(Validation.password('Aa1!${'a' * 125}', isNew: true), isNotNull);
    });
    test('e-mail válido com limite de 254', () {
      expect(Validation.email('voce@example.com'), isNull);
      expect(Validation.email('email-invalido'), isNotNull);
      expect(Validation.email('${'a' * 250}@x.com'), isNotNull);
    });
    for (final value in ['0', '-1', '1441', '1.5', '', 'abc']) {
      test(
        'rejeita minutos $value',
        () => expect(Validation.minutes(value), isNotNull),
      );
    }
    test('aceita limites inclusivos de minutos', () {
      expect(Validation.minutes('1'), isNull);
      expect(Validation.minutes('1440'), isNull);
    });
    test(
      'casos de uso validam antes de chamar API e removem espaços',
      () async {
        final backend = TestBackend();
        addTearDown(backend.dispose);
        expect(
          () => backend.dependencies.skills.save(name: 'X', daily: 30),
          throwsA(isA<AppException>()),
        );
        expect(
          () => backend.dependencies.times.save(skillId: 0, minutes: 20),
          throwsA(isA<AppException>()),
        );
        expect(
          () => backend.dependencies.auth.redefinePassword(
            'old',
            'Ab1!',
            'different',
          ),
          throwsA(isA<AppException>()),
        );
        expect(backend.requests, isEmpty);
        await backend.dependencies.skills.save(name: '  Inglês  ', daily: 30);
        expect(backend.skills.last['name'], 'Inglês');
      },
    );
  });

  group('Ambientes e navegação', () {
    test('aliases e padrão de produção', () {
      expect(Environment.parse('development'), Environment.dev);
      expect(Environment.parse('homolog'), Environment.qa);
      expect(Environment.parse('staging'), Environment.qa);
      expect(Environment.parse(''), Environment.prod);
    });
    test('URL obrigatória e HTTPS fora de DEV', () {
      expect(
        () => AppConfig.fromValues(Environment.prod, ''),
        throwsFormatException,
      );
      expect(
        () => AppConfig.fromValues(Environment.qa, 'http://api.example.com'),
        throwsFormatException,
      );
      expect(
        AppConfig.fromValues(
          Environment.dev,
          'http://localhost:8000/',
        ).apiUrl.toString(),
        'http://localhost:8000',
      );
      expect(
        AppConfig.fromValues(
          Environment.prod,
          'https://api.example.com/api',
        ).apiUrl.path,
        '/api',
      );
      expect(
        () => AppConfig.fromValues(
          Environment.prod,
          'https://user:secret@example.com',
        ),
        throwsFormatException,
      );
    });
    test('retorno apenas para rotas privadas conhecidas', () {
      expect(
        safeReturnUrl('/times/create?skillId=3'),
        '/times/create?skillId=3',
      );
      expect(safeReturnUrl('/skills/3/statistic'), '/skills/3/statistic');
      for (final target in [
        'https://evil.test',
        '//evil.test',
        '/skills/../evil',
        '/homeevil',
        '/sign-up',
        '/times\\evil',
        '/skills/-1/update',
      ]) {
        expect(safeReturnUrl(target), '/home');
      }
    });
  });
}
