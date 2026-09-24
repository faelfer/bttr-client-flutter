import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/config/dependencies.dart';
import 'src/core/utils/performance_recorder.dart';
import 'src/presentation/core/design/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  startPerformanceRecorder();
  try {
    final config = await AppConfig.load();
    await initializeDateFormatting('pt_BR');
    final dependencies = await Dependencies.create(config);
    runApp(
      BttrApp(dependencies: dependencies, environment: config.environment),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: bttrTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_outlined, size: 40),
                    const SizedBox(height: 20),
                    const Text(
                      'Não foi possível iniciar o Bttr.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error is FormatException
                          ? error.message
                          : 'Verifique a configuração do aplicativo e tente novamente.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
