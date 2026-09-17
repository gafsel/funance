import 'dart:async';

/// Por que uma escrita que já tinha sido dada como guardada acabou falhando.
///
/// É um enum, e não o texto do erro, porque quem mostra precisa traduzir — e
/// porque mensagem crua do Firestore não é frase para o usuário.
enum WriteFailureReason {
  /// As rules negaram. O dado não existe no servidor e não vai existir.
  permissionDenied,

  /// O documento sumiu entre a leitura e a escrita.
  notFound,

  /// Estávamos online e o servidor não confirmou dentro do prazo longo.
  tookTooLong,

  /// Qualquer outra recusa do servidor.
  unknown,
}

/// Uma escrita que o usuário acreditava salva e que o servidor recusou.
class WriteFailure {
  const WriteFailure(this.reason);

  final WriteFailureReason reason;
}

/// Canal por onde uma falha tardia de escrita chega até a tela.
///
/// Existe porque `settleWrite` pode devolver "pendente" e só depois descobrir
/// que o servidor recusou. Nesse ponto a tela que salvou já fechou: não há mais
/// `Future` para completar com erro nem `context` para uma snackbar. Antes isso
/// virava só uma linha no CrashReporter e o item sumia da lista sem que
/// ninguém soubesse.
///
/// A tarja de sincronização, que vive acima de todas as rotas, escuta daqui.
abstract final class WriteFailures {
  static final StreamController<WriteFailure> _controller =
      StreamController<WriteFailure>.broadcast();

  static Stream<WriteFailure> get stream => _controller.stream;

  static void report(WriteFailureReason reason) {
    if (_controller.hasListener) _controller.add(WriteFailure(reason));
  }
}

/// Lê o motivo a partir do erro do Firestore.
///
/// O `code` do `FirebaseException` chega aqui como texto para não obrigar este
/// arquivo a conhecer o pacote do Firestore — e para o teste poder exercitá-lo
/// sem um Firestore vivo.
WriteFailureReason writeFailureReasonOf(Object error) {
  final String text = error.toString();

  if (text.contains('permission-denied')) {
    return WriteFailureReason.permissionDenied;
  }
  if (text.contains('not-found')) return WriteFailureReason.notFound;

  return WriteFailureReason.unknown;
}
