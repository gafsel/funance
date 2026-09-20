import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:funances/core/observability/crash_reporter.dart';

/// O logger do app. Um só.
///
/// Antes havia três: `print`/`debugPrint` em alguns lugares, o
/// `package:logger` em outro e o `developer.log` que o `CrashReporter` já
/// usava. Três destinos diferentes querem dizer que, ao investigar uma falha,
/// não há um lugar para olhar — e o `package:logger` ainda escrevia em release,
/// com stack colorido, no console de quem estivesse com o aparelho na mão.
///
/// A regra aqui: [debug] e [info] só existem em debug e nunca saem do console
/// de desenvolvimento; [error] vai para o [CrashReporter], que é quem sabe
/// falar com o Crashlytics fora da web e com o console/Analytics na web. Não
/// existe terceiro caminho.
class AppLogger {
  const AppLogger._();

  static const String _namespace = 'funances';

  /// Detalhe de desenvolvimento. Some por completo em release.
  static void debug(String message, {String name = 'app'}) {
    if (!kDebugMode) return;
    developer.log(message, name: '$_namespace.$name', level: 500);
  }

  /// Marco de fluxo (trocou de workspace, carregou a lista). Só em debug: em
  /// release ninguém lê, e o texto pode carregar nome de conta ou de categoria.
  static void info(String message, {String name = 'app'}) {
    if (!kDebugMode) return;
    developer.log(message, name: '$_namespace.$name', level: 800);
  }

  /// Falha tratada que ainda assim precisa ser investigável.
  ///
  /// Vai para o mesmo lugar dos erros não tratados — é o que permite descobrir
  /// que uma tela "funcionando" está engolindo exceção desde a semana passada.
  ///
  /// A [message] é o que o app SABIA quando pegou a falha: qual documento,
  /// qual operação. Ela ia só para o log de debug, e em release o relatório
  /// recebia a exceção sozinha — quase sempre um `TypeError` genérico, sem
  /// nada que permitisse achar o caso. Agora ela viaja como `reason`.
  static void error(String message, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: '$_namespace.app',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }

    CrashReporter.recordError(error, stackTrace, reason: message);
  }
}
