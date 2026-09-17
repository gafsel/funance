import 'package:funances/core/async/latched_events.dart';

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

/// O QUE não pôde ser salvo.
///
/// "Uma alteração não pôde ser salva" não diz ao usuário o que ele perdeu nem
/// onde conferir. O tipo da entidade é o mínimo que torna o aviso acionável, e
/// é o que se consegue dizer de dentro de um repositório — onde não há
/// `BuildContext` para montar um rótulo com o nome do item.
enum WriteEntity {
  transaction,
  installment,
  planning,
  account,
  category,
  goal,
  invite,
  workspace,
  profile,
  automaticTransaction,
  reconciliation,
}

/// Uma escrita que o usuário acreditava salva e que o servidor recusou.
class WriteFailure {
  const WriteFailure(this.entity, this.reason);

  final WriteEntity entity;
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
/// A tarja de sincronização, que vive acima de todas as rotas, escuta daqui. O
/// canal guarda o último evento porque a falha pode chegar antes de a tarja
/// existir — e aí um `broadcast` comum a descartaria.
abstract final class WriteFailures {
  static final LatchedEvents<WriteFailure> _events =
      LatchedEvents<WriteFailure>();

  static Stream<WriteFailure> get stream => _events.stream;

  static void report(WriteEntity entity, WriteFailureReason reason) {
    _events.add(WriteFailure(entity, reason));
  }

  /// Esquece a falha guardada.
  ///
  /// No logout: o erro de escrita de uma sessão não é assunto da próxima.
  static void clear() => _events.clear();
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
