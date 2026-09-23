import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../pages/auth/auth_page.dart';
import '../../pages/auth/bloc/session_bloc.dart';
import '../../pages/not_found_page.dart';
import '../../pages/profile/password_page.dart';
import '../../pages/profile/profile_page.dart';
import '../../pages/skills/skill_form_page.dart';
import '../../pages/skills/skills_page.dart';
import '../../pages/skills/statistics_page.dart';
import '../../pages/times/time_form_page.dart';
import '../../pages/times/times_page.dart';
import '../../widgets/app_shell.dart';

String safeReturnUrl(String? value) {
  final uri = value == null ? null : Uri.tryParse(value);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasFragment ||
      value!.contains('\\')) {
    return '/home';
  }
  final path = uri.path;
  if ([
        '/home',
        '/profile',
        '/redefine-password',
        '/times',
        '/times/create',
        '/skills/create',
      ].contains(path) ||
      RegExp(r'^/skills/[1-9][0-9]*/(update|statistic)$').hasMatch(path) ||
      RegExp(r'^/times/[1-9][0-9]*/update$').hasMatch(path)) {
    return uri.toString();
  }
  return '/home';
}

class AppRouter extends ChangeNotifier {
  AppRouter(this.session, {String? initialLocation}) {
    _subscription = session.stream.listen((_) => notifyListeners());
    router = GoRouter(
      initialLocation: initialLocation,
      refreshListenable: this,
      redirect: (context, state) {
        final public = [
          '/',
          '/sign-up',
          '/forgot-password',
        ].contains(state.uri.path);
        if (!session.state.authenticated && !public) {
          return Uri(
            path: '/',
            queryParameters: {'returnUrl': safeReturnUrl(state.uri.toString())},
          ).toString();
        }
        if (session.state.authenticated && public) {
          return safeReturnUrl(state.uri.queryParameters['returnUrl']);
        }
        return null;
      },
      errorBuilder: (_, _) => const NotFoundPage(),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, state) =>
              AuthPage(key: state.pageKey, mode: AuthMode.signIn),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (_, state) =>
              AuthPage(key: state.pageKey, mode: AuthMode.signUp),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, state) =>
              AuthPage(key: state.pageKey, mode: AuthMode.forgot),
        ),
        ShellRoute(
          builder: (_, _, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, state) =>
                  PageViewport(child: SkillsPage(key: state.pageKey)),
            ),
            GoRoute(
              path: '/skills/create',
              builder: (_, state) =>
                  PageViewport(child: SkillFormPage(key: state.pageKey)),
            ),
            GoRoute(
              path: '/skills/:id/update',
              builder: (_, state) => _withId(
                state,
                (id) => SkillFormPage(key: ValueKey('skill-$id'), id: id),
              ),
            ),
            GoRoute(
              path: '/skills/:id/statistic',
              builder: (_, state) => _withId(
                state,
                (id) => StatisticsPage(key: ValueKey('stats-$id'), id: id),
              ),
            ),
            GoRoute(
              path: '/times',
              builder: (_, state) =>
                  PageViewport(child: TimesPage(key: state.pageKey)),
            ),
            GoRoute(
              path: '/times/create',
              builder: (_, state) => PageViewport(
                child: TimeFormPage(
                  key: ValueKey(state.uri.toString()),
                  skillId: int.tryParse(
                    state.uri.queryParameters['skillId'] ?? '',
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/times/:id/update',
              builder: (_, state) => _withId(
                state,
                (id) => TimeFormPage(key: ValueKey('time-$id'), id: id),
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, state) =>
                  PageViewport(child: ProfilePage(key: state.pageKey)),
            ),
            GoRoute(
              path: '/redefine-password',
              builder: (_, state) =>
                  PageViewport(child: PasswordPage(key: state.pageKey)),
            ),
          ],
        ),
      ],
    );
  }
  final SessionBloc session;
  late final GoRouter router;
  late final StreamSubscription<SessionState> _subscription;

  static Widget _withId(GoRouterState state, Widget Function(int) builder) {
    final id = int.tryParse(state.pathParameters['id'] ?? '');
    return PageViewport(
      child: id != null && id > 0
          ? builder(id)
          : const Text('Registro não encontrado.'),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    router.dispose();
    super.dispose();
  }
}
