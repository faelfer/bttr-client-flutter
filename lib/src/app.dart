import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/dependencies.dart';
import 'core/enums/environment.dart';
import 'presentation/core/design/app_theme.dart';
import 'presentation/core/routes/app_router.dart';
import 'presentation/pages/auth/bloc/session_bloc.dart';

class BttrApp extends StatefulWidget {
  const BttrApp({
    super.key,
    required this.dependencies,
    this.environment = Environment.prod,
    this.initialLocation,
  });
  final Dependencies dependencies;
  final Environment environment;
  final String? initialLocation;
  @override
  State<BttrApp> createState() => _BttrAppState();
}

class _BttrAppState extends State<BttrApp> {
  late final _session = SessionBloc(widget.dependencies.auth);
  late final _router = AppRouter(
    _session,
    initialLocation: widget.initialLocation,
  );
  @override
  void dispose() {
    _router.dispose();
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: widget.dependencies,
    child: BlocProvider.value(
      value: _session,
      child: MaterialApp.router(
        title: 'Bttr',
        debugShowCheckedModeBanner: false,
        theme: bttrTheme(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router.router,
        builder: (context, child) => widget.environment == Environment.prod
            ? child!
            : Banner(
                message: widget.environment.name.toUpperCase(),
                location: BannerLocation.topEnd,
                color: BttrColors.green,
                child: child!,
              ),
      ),
    ),
  );
}
