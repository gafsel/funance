import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:funances/core/firestore/sync_status.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/core/observability/crash_reporter.dart';

/// O que aconteceu com uma escrita do ponto de vista de quem a pediu.
enum WriteOutcome {
  /// O servidor confirmou. O dado existe para todo mundo.
  confirmed,

  /// O dado está no cache local e sobe quando a conexão voltar. Para o app já
  /// está salvo; para o servidor, ainda não.
  pending,
}

/// Escrita e valor produzido por ela.
typedef Written<T> = ({T value, WriteOutcome outcome});

/// Prazo quando o Firestore já está respondendo pelo cache.
///
/// Curto: offline a confirmação não vem, e esperar só deixa o botão girando.
const Duration _offlineGrace = Duration(seconds: 2);

/// Prazo quando acreditamos estar online.
///
/// Longo de propósito. Com rede lenta, um `permission-denied` pode levar vários
/// segundos para chegar — e ele PRECISA chegar como erro na tela, não como
/// "salvo". O prazo curto de antes transformava negativa das rules em sucesso
/// silencioso, e o item sumia da lista sem aviso.
const Duration _onlineGrace = Duration(seconds: 30);

/// Espera a escrita do Firestore, mas não para sempre.
///
/// O Firestore aplica a escrita no cache local no mesmo instante: o dado já
/// está salvo e já aparece nas telas. O `Future` que ele devolve, porém, só
/// completa quando o SERVIDOR confirma — offline, nunca. Como os botões do app
/// ficam girando enquanto esperam esse `Future`, uma escrita sem rede deixava o
/// botão em carregamento eterno, e o usuário achava que tinha perdido o que
/// digitou (quando na verdade já estava salvo e sincronizaria sozinho).
///
/// O prazo é escolhido pelo estado de sincronização, e essa é a parte que
/// importa: offline desistimos rápido, porque não há o que esperar; online
/// esperamos de verdade, porque uma recusa do servidor não pode ser confundida
/// com falta de rede.
///
/// O retorno diz qual dos dois casos aconteceu, para quem chamou poder
/// prometer a coisa certa ao usuário. Um "pendente" não é sucesso pleno: há
/// efeito de servidor — as parcelas de um lançamento, por exemplo — que só
/// acontece quando a escrita sobe.
Future<WriteOutcome> settleWrite(Future<void> write, {Duration? grace}) {
  final bool wasOffline = SyncStatusLatch.isOffline;
  final Duration deadline =
      grace ?? (wasOffline ? _offlineGrace : _onlineGrace);

  final Completer<WriteOutcome> settled = Completer<WriteOutcome>();
  final Timer timer = Timer(deadline, () {
    if (settled.isCompleted) return;

    PendingWrites.add();

    // Estávamos online e mesmo assim o servidor não respondeu em 30s. Não dá
    // para chamar isso de "sem rede": alguma coisa está errada e o usuário
    // precisa saber que o que ele salvou ainda não subiu.
    if (!wasOffline) WriteFailures.report(WriteFailureReason.tookTooLong);

    settled.complete(WriteOutcome.pending);
  });

  write.then(
    (_) {
      timer.cancel();

      if (!settled.isCompleted) {
        settled.complete(WriteOutcome.confirmed);
        return;
      }

      // Confirmação atrasada de algo que já havia sido dado como pendente.
      PendingWrites.resolve();
    },
    onError: (Object error, StackTrace stack) {
      timer.cancel();

      if (!settled.isCompleted) {
        settled.completeError(error, stack);
        return;
      }

      // A tela que salvou já seguiu. O erro não tem mais para onde voltar,
      // então vai para a tarja — que vive acima de todas as rotas — em vez de
      // morrer num log que ninguém lê.
      PendingWrites.resolve();
      WriteFailures.report(writeFailureReasonOf(error));
      CrashReporter.recordError(error, stack);
    },
  );

  return settled.future;
}

/// Quantas escritas foram dadas como pendentes e ainda não se resolveram.
///
/// Os metadados do Firestore só contam a história do documento observado; esta
/// conta cobre qualquer escrita do app, inclusive em coleções que nenhuma tela
/// esteja olhando.
abstract final class PendingWrites {
  static int _count = 0;
  static final StreamController<int> _controller =
      StreamController<int>.broadcast();

  static int get count => _count;

  /// Emite a contagem atual e cada mudança seguinte.
  static Stream<int> get changes async* {
    yield _count;
    yield* _controller.stream;
  }

  static void add() {
    _count++;
    _emit();
  }

  static void resolve() {
    if (_count > 0) _count--;
    _emit();
  }

  static void _emit() {
    if (_controller.hasListener) _controller.add(_count);
  }

  @visibleForTesting
  static void reset() {
    _count = 0;
    _emit();
  }
}
