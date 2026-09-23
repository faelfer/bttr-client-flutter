import 'dart:convert';
import 'package:bttr_client_flutter/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'support/test_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  late TestBackend backend;
  setUp(() => backend = TestBackend());
  tearDown(() => backend.dispose());

  Future<void> mount(
    WidgetTester tester, {
    bool authenticated = true,
    String route = '/home',
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (authenticated) {
      await tester.runAsync(() => backend.session.set('test-token'));
    }
    await tester.pumpWidget(
      BttrApp(dependencies: backend.dependencies, initialLocation: route),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder button(String label) => find.widgetWithText(FilledButton, label);
  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  testWidgets('login valida campos, autentica e permite sair', (tester) async {
    final semantics = tester.ensureSemantics();
    await mount(tester, authenticated: false, route: '/');
    expect(find.bySemanticsIdentifier('bttr.auth.email'), findsOneWidget);
    expect(find.bySemanticsIdentifier('bttr.auth.password'), findsOneWidget);
    expect(find.bySemanticsIdentifier('bttr.auth.signIn'), findsOneWidget);
    await tap(tester, button('Entrar'));
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(backend.requests, isEmpty);
    await enter(tester, 'E-mail', 'rafael@example.com');
    await enter(tester, 'Senha', 'minha-senha');
    await tap(tester, button('Entrar'));
    expect(find.text('Minhas habilidades'), findsOneWidget);
    expect(find.text('Habilidade 1'), findsOneWidget);
    expect(find.bySemanticsIdentifier('bttr.skills.new'), findsOneWidget);
    expect(find.bySemanticsIdentifier('bttr.auth.signOut'), findsOneWidget);
    await tap(tester, find.byTooltip('Sair da conta'));
    expect(find.text('Bom ter você\nde volta.'), findsOneWidget);
    expect(backend.storage.value, isNull);
    semantics.dispose();
  });

  testWidgets('rota protegida retorna às estatísticas após autenticar', (
    tester,
  ) async {
    await mount(tester, authenticated: false, route: '/skills/1/statistic');
    expect(find.text('Bom ter você\nde volta.'), findsOneWidget);
    await enter(tester, 'E-mail', 'rafael@example.com');
    await enter(tester, 'Senha', 'senha');
    await tap(tester, button('Entrar'));
    expect(find.text('Habilidade 1'), findsOneWidget);
    expect(find.text('Tempo dedicado no mês'), findsOneWidget);
    expect(
      backend.requests.any((r) => r.url.path == '/times/times_by_date'),
      isTrue,
    );
  });

  testWidgets('cadastro e recuperação retornam ao login', (tester) async {
    await mount(tester, authenticated: false, route: '/sign-up');
    await enter(tester, 'Nome de usuário', 'Rafael');
    await enter(tester, 'E-mail', 'rafael@example.com');
    await enter(tester, 'Senha', 'Ab1!');
    await tap(tester, button('Criar minha conta'));
    expect(find.text('Bom ter você\nde volta.'), findsOneWidget);
    expect(backend.requests.last.url.path, '/users/sign_up');
    await tap(tester, find.text('Esqueceu a senha?'));
    await enter(tester, 'E-mail', 'rafael@example.com');
    await tap(tester, button('Enviar link de recuperação'));
    expect(backend.requests.last.url.path, '/users/forgot_password');
    expect(find.text('Bom ter você\nde volta.'), findsOneWidget);
  });

  testWidgets(
    'habilidade: criação, erro preserva edição, atualização e exclusão confirmada',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mount(tester);
      await tap(tester, button('Nova habilidade'));
      expect(find.bySemanticsIdentifier('bttr.skills.name'), findsOneWidget);
      expect(find.bySemanticsIdentifier('bttr.skills.daily'), findsOneWidget);
      expect(find.bySemanticsIdentifier('bttr.skills.create'), findsOneWidget);
      await enter(tester, 'Nome da habilidade', 'Violão');
      await enter(tester, 'Meta diária em minutos', '20');
      await tap(tester, button('Criar habilidade'));
      expect(find.text('Violão'), findsOneWidget);
      await tap(tester, find.byTooltip('Editar Violão'));
      await enter(tester, 'Nome da habilidade', 'Violão clássico');
      backend.failNext = 500;
      await tap(tester, button('Salvar alterações'));
      expect(find.text('Falha de teste. Tente novamente.'), findsOneWidget);
      expect(find.text('Violão clássico'), findsOneWidget);
      await tap(tester, button('Salvar alterações'));
      expect(find.text('Violão clássico'), findsOneWidget);
      expect(find.text('Minhas habilidades'), findsOneWidget);
      await tap(tester, find.byTooltip('Editar Violão clássico'));
      await tap(tester, find.widgetWithText(TextButton, 'Excluir habilidade'));
      expect(
        find.textContaining('todos os seus registros de tempo?'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(TextButton, 'Cancelar').last);
      expect(backend.skills.length, 2);
      await tap(tester, find.widgetWithText(TextButton, 'Excluir habilidade'));
      await tap(tester, button('Sim, excluir'));
      expect(backend.skills.length, 1);
      expect(find.text('Violão clássico'), findsNothing);
      expect(find.text('Minhas habilidades'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'tempo: pré-seleção nas estatísticas, criação, edição e exclusão',
    (tester) async {
      await mount(tester, route: '/skills/1/statistic');
      await tap(tester, button('Registrar tempo'));
      expect(find.text('Habilidade 1'), findsOneWidget);
      await enter(tester, 'Tempo dedicado em minutos', '45');
      await tap(tester, button('Registrar tempo'));
      expect(find.text('Histórico de tempo'), findsOneWidget);
      expect(find.text('45min'), findsOneWidget);
      final created = backend.times.single['created'];
      await tap(tester, find.byTooltip('Editar registro de Habilidade 1'));
      await enter(tester, 'Tempo dedicado em minutos', '60');
      await tap(tester, button('Salvar alterações'));
      expect(find.text('1h'), findsOneWidget);
      expect(backend.times.single['created'], created);
      final update = backend.requests.lastWhere((r) => r.method == 'PUT');
      expect(jsonDecode(update.body), {'skill_id': 1, 'minutes': 60});
      await tap(tester, find.byTooltip('Editar registro de Habilidade 1'));
      await tap(tester, find.widgetWithText(TextButton, 'Excluir registro'));
      await tap(tester, button('Sim, excluir'));
      expect(backend.times, isEmpty);
      expect(find.text('Seu tempo conta uma história.'), findsOneWidget);
    },
  );

  testWidgets(
    'perfil: salva dados, valida confirmação de senha e exclui conta',
    (tester) async {
      await mount(tester, route: '/profile');
      await enter(tester, 'Nome de usuário', 'Rafa');
      await tap(tester, button('Salvar alterações'));
      expect(backend.user['username'], 'Rafa');
      await tap(tester, find.widgetWithText(TextButton, 'Alterar senha'));
      await enter(tester, 'Senha atual', 'old');
      await enter(tester, 'Nova senha', 'New1!');
      await enter(tester, 'Confirmar nova senha', 'Wrong1!');
      await tap(tester, button('Salvar nova senha'));
      expect(find.text('As senhas não coincidem.'), findsOneWidget);
      expect(
        backend.requests.where((r) => r.url.path == '/users/redefine_password'),
        isEmpty,
      );
      await enter(tester, 'Confirmar nova senha', 'New1!');
      await tap(tester, button('Salvar nova senha'));
      expect(find.text('Informações pessoais'), findsOneWidget);
      await tap(
        tester,
        find.widgetWithText(OutlinedButton, 'Excluir minha conta'),
      );
      await tap(tester, button('Sim, excluir'));
      expect(find.text('Bom ter você\nde volta.'), findsOneWidget);
      expect(backend.session.authenticated, isFalse);
    },
  );

  testWidgets('paginação usa páginas de 5 itens e índices a partir de 1', (
    tester,
  ) async {
    backend.skills = List.generate(6, (i) => skillJson(i + 1));
    await mount(tester);
    expect(find.text('Habilidade 5'), findsOneWidget);
    expect(find.text('Habilidade 6'), findsNothing);
    await tap(tester, find.byTooltip('Próxima página'));
    expect(find.text('Habilidade 6'), findsOneWidget);
    expect(find.text('Página 2 de 2'), findsOneWidget);
    expect(backend.requests.last.url.queryParameters['page'], '2');
    await tap(tester, find.byTooltip('Página anterior'));
    expect(find.text('Habilidade 1'), findsOneWidget);
  });

  testWidgets(
    'falha de leitura permite tentar novamente e registrar tempo exige habilidade',
    (tester) async {
      backend.skills.clear();
      backend.failNext = 500;
      await mount(tester);
      await tap(tester, find.text('Tentar novamente'));
      expect(find.text('Sua próxima habilidade começa aqui.'), findsOneWidget);
      await tap(tester, find.text('Registrar meu tempo'));
      expect(
        find.text('Primeiro, escolha o que quer aprender.'),
        findsOneWidget,
      );
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    },
  );

  testWidgets('resposta 401 em rota privada volta ao login', (tester) async {
    backend.failNext = 401;
    await mount(tester, route: '/profile');
    expect(find.text('Bom ter você\nde volta.'), findsOneWidget);
    expect(backend.session.token, isNull);
  });

  testWidgets('botão voltar do Android retorna à lista de habilidades', (
    tester,
  ) async {
    await mount(tester, route: '/skills/create');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Minhas habilidades'), findsOneWidget);
  });

  for (final size in [const Size(320, 640), const Size(820, 1180)]) {
    testWidgets(
      'layout sem overflow em ${size.width.toInt()}px e texto ampliado',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await mount(tester, size: size);
        await tap(tester, find.text('Ver estatísticas'));
        await tap(tester, button('Registrar tempo'));
      },
    );
  }
}
