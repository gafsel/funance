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
import 'package:funances/core/widgets/celebration/celebration_host.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'firebase_ambiente.dart';

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
        options: firebaseOptionsDoAmbiente(),
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
      // A tarja de sincronização e a camada de conquistas valem para o app
      // inteiro; pendurá-las aqui evita que cada tela precise lembrar de
      // incluí-las — e é o que faz o XP ganho dentro da Conciliação ou do
      // formulário de transação aparecer, coisa que antes só acontecia com a
      // Home montada.
      //
      // A ordem importa: a tarja empurra o conteúdo para baixo e a camada de
      // conquistas sobrepõe o topo do que sobrou, então os toasts nunca
      // cobrem a tarja nem a barra inferior com o botão de lançar.
      builder: (context, child) => SyncStatusBanner(
        child: CelebrationHost(child: child ?? const SizedBox.shrink()),
      ),
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
