import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/design/app_theme.dart';
import '../pages/auth/bloc/session_bloc.dart';
import 'common.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = path.startsWith('/times')
        ? 1
        : path == '/profile' || path == '/redefine-password'
        ? 2
        : 0;
    return PopScope(
      canPop: path == '/home',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(
          path.startsWith('/times/')
              ? '/times'
              : path == '/redefine-password'
              ? '/profile'
              : '/home',
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Brand(),
          toolbarHeight: 76,
          actions: [
            Semantics(
              identifier: 'bttr.auth.signOut',
              child: IconButton(
                tooltip: 'Sair da conta',
                onPressed: () =>
                    context.read<SessionBloc>().add(SignOutRequested()),
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(top: false, child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (index) =>
              context.go(['/home', '/times', '/profile'][index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Habilidades',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Histórico',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Meu perfil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrolling belongs inside each route, never around the shell's Navigator.
class PageViewport extends StatelessWidget {
  const PageViewport({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 14),
            const Text(
              'Feito de tempo, dedicação e você.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: BttrColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
