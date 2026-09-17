import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:funances/core/observability/web_console.dart';

/// Ponto único de envio de erros não tratados.
///
/// Fora da web quem recebe é o Crashlytics. Na web ele não existe — e por
/// muito tempo "não existe" virou "ninguém fica sabendo": o registro caía num
/// `developer.log` que, em release, não deixa rastro no DevTools. Uma falha na
/// web sumia sem nenhuma linha no console.
///
/// Agora a web tem dois destinos próprios: o `console.error`, para quem estiver
/// com o DevTools aberto, e um evento `web_error` no Analytics, para que uma
/// quebra que ninguém viu acontecer ainda assim apareça em algum número.
class CrashReporter {
  const CrashReporter._();

  /// Crashlytics só está disponível fora da web.
  static bool get isSupported => !kIsWeb;

  /// Nome do evento que conta erros da web. Fica aqui, e não no
  /// `AnalyticsEvents`, porque não é um evento de produto: ninguém deve
  /// misturá-lo com o funil.
  @visibleForTesting
  static const String webErrorEvent = 'web_error';

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
      _toCrashlytics(
        () => FirebaseCrashlytics.instance.recordFlutterError(
          details,
          fatal: false,
        ),
      );
      return;
    }

    _recordOnWeb(
      details.exception,
      details.stack,
      kind: 'flutter',
      context: details.context?.toDescription(),
    );
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
      _toCrashlytics(
        () => FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: fatal,
        ),
      );
      return;
    }

    _recordOnWeb(error, stack, kind: fatal ? 'fatal' : 'uncaught');
  }

  /// Relatar erro não pode ser mais uma fonte de erro.
  ///
  /// Se o Crashlytics não estiver de pé — Firebase ainda não inicializado, ou
  /// uma falha logo no arranque — a exceção dele voltaria pelo mesmo
  /// `runZonedGuarded` que nos chamou, e o app entraria em laço tentando
  /// relatar a falha de relatar a falha.
  static void _toCrashlytics(void Function() send) {
    try {
      send();
    } catch (error, stack) {
      _logLocally(error, stack, 'CrashReporter');
    }
  }

  static void _recordOnWeb(
    Object? error,
    StackTrace? stack, {
    required String kind,
    String? context,
  }) {
    final String label = context == null ? kind : '$kind: $context';

    if (!kDebugMode) _logLocally(error, stack, 'UncaughtError');

    reportToBrowserConsole(label, error, stack);
    unawaited(_logWebErrorEvent(error, kind));
  }

  /// Manda ao Analytics só o suficiente para CONTAR o erro.
  ///
  /// Nada do texto do erro vai junto: a mensagem de uma exceção do app pode
  /// carregar valor, descrição digitada ou id de documento, e o Analytics não
  /// é lugar para dado financeiro. O tipo da exceção é um nome de classe, e
  /// `kind` diz de que handler ela veio — dá para ver que algo quebrou e onde
  /// olhar, sem nenhum dado do usuário.
  static Future<void> _logWebErrorEvent(Object? error, String kind) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: webErrorEvent,
        parameters: <String, Object>{
          'kind': kind,
          'error_type': webErrorType(error),
        },
      );
    } catch (_) {
      // Um erro ao relatar erro não pode virar um segundo erro: o
      // runZonedGuarded chamaria este mesmo método de novo.
    }
  }

  /// Tipo da exceção, cortado no limite que o Analytics aceita por parâmetro.
  @visibleForTesting
  static String webErrorType(Object? error) {
    if (error == null) return 'unknown';

    final String type = error.runtimeType.toString();

    return type.length <= 100 ? type : type.substring(0, 100);
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
