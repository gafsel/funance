import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/firestore_setup.dart';
import 'package:funances/core/observability/crash_reporter.dart';
import 'package:funances/core/router/app_router.dart';
import 'package:funances/core/router/url_strategy.dart';
import 'package:funances/core/widgets/app_error_widget.dart';
import 'package:funances/core/widgets/sync_status_banner.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'firebase_options.dart';

void main() {
  // runZonedGuarded captura os erros assíncronos que escapam das zonas do
  // Flutter; os handlers abaixo cobrem o framework e a plataforma.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Antes do runApp: o go_router lê a URL na primeira rota, e trocar a
      // estratégia depois disso faria a rota inicial ser resolvida com `#`.
      configureUrlStrategy();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await CrashReporter.initialize();
      configureFirestorePersistence();

      FlutterError.onError = CrashReporter.recordFlutterError;

      PlatformDispatcher.instance.onError = (error, stack) {
        CrashReporter.recordError(error, stack, fatal: true);
        return true;
      };

      // Em release a faixa vermelha de erro vira uma mensagem amigável; em
      // debug o widget padrão do Flutter continua sendo mais útil.
      if (kReleaseMode) {
        ErrorWidget.builder = (details) => const AppErrorWidget();
      }

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) => CrashReporter.recordError(error, stack, fatal: true),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(ThemeProviders.mode);

    return MaterialApp.router(
      routerConfig: router,
      // A tarja de sincronização vale para o app inteiro; pendurá-la aqui
      // evita que cada tela precise lembrar de incluí-la.
      builder: (context, child) =>
          SyncStatusBanner(child: child ?? const SizedBox.shrink()),
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', ''), Locale('en', '')],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
    );
  }
}
