import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Ponto único de envio de erros não tratados.
///
/// O Crashlytics não tem implementação para web: lá o registro cai no
/// `dart:developer`, que aparece no console do navegador. Em debug sempre
/// logamos localmente, porque o painel do Crashlytics só é consultado em
/// release e engolir o erro no desenvolvimento atrapalharia mais do que ajuda.
class CrashReporter {
  const CrashReporter._();

  /// Crashlytics só está disponível fora da web.
  static bool get isSupported => !kIsWeb;

  /// Liga a coleta. Em debug mantemos desligada para não poluir o painel com
  /// erros de desenvolvimento.
  static Future<void> initialize() async {
    if (!isSupported) return;

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  /// Registra um erro do framework (FlutterError.onError).
  static void recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      // Mantém o comportamento padrão do Flutter (erro vermelho no console).
      FlutterError.dumpErrorToConsole(details);
    }

    if (isSupported) {
      FirebaseCrashlytics.instance.recordFlutterError(details, fatal: false);
      return;
    }

    _logLocally(details.exception, details.stack, 'FlutterError');
  }

  /// Registra um erro assíncrono não capturado
  /// (PlatformDispatcher.onError / runZonedGuarded).
  static void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) {
    if (kDebugMode) {
      _logLocally(error, stack, 'UncaughtError');
    }

    if (isSupported) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
      return;
    }

    if (!kDebugMode) {
      _logLocally(error, stack, 'UncaughtError');
    }
  }

  static void _logLocally(Object? error, StackTrace? stack, String name) {
    developer.log(
      error?.toString() ?? 'Erro desconhecido',
      name: 'funances.$name',
      error: error,
      stackTrace: stack,
    );
  }
}
