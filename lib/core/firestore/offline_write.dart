import 'dart:async';

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
Future<WriteOutcome> settleWrite(
  Future<void> write, {
  required WriteEntity entity,
  Duration? grace,
}) {
  final bool startedOffline = SyncStatusLatch.isOffline;
  final Duration deadline =
      grace ?? (startedOffline ? _offlineGrace : _onlineGrace);

  final Completer<WriteOutcome> settled = Completer<WriteOutcome>();
  final Timer timer = Timer(deadline, () {
    if (settled.isCompleted) return;

    PendingWrites.add();

    // O estado é reconsultado AGORA, e não o do começo da escrita: em 30 s a
    // rede cai com facilidade. Quem começou online e terminou offline não fez
    // nada de errado, e um aviso vermelho nesse caso culparia o usuário por
    // uma queda de conexão.
    final bool stillOnline = !startedOffline && !SyncStatusLatch.isOffline;

    // Online do início ao fim e mesmo assim o servidor ficou mudo por 30 s.
    // Isso não é "sem rede": alguma coisa está errada e o usuário precisa
    // saber que o que ele salvou ainda não subiu.
    if (stillOnline) {
      WriteFailures.report(entity, WriteFailureReason.tookTooLong);
    }

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
      WriteFailures.report(entity, writeFailureReasonOf(error));
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

  /// Zera a contagem.
  ///
  /// Na troca de sessão: o que estava pendente pertencia ao usuário anterior.
  static void reset() {
    _count = 0;
    _emit();
  }
}

/// Guarda o resultado da última escrita de um formulário.
///
/// A tela precisa saber se o servidor confirmou para escolher o que prometer:
/// "salvo" e "salvo neste dispositivo" são promessas diferentes.
///
/// Fica no notifier e não no estado do formulário de propósito: o estado
/// descreve o que a tela DESENHA, e isto é um fato sobre o último save. Um
/// campo de estado ainda seria carregado para frente por `copyWith` — que é
/// justamente como um save confirmado acabava herdando o "pendente" do save
/// anterior.
mixin TracksWriteOutcome {
  WriteOutcome _lastWriteOutcome = WriteOutcome.confirmed;

  /// Se o SERVIDOR confirmou o último save.
  WriteOutcome get lastWriteOutcome => _lastWriteOutcome;

  /// true quando o último save ficou só no cache local.
  bool get lastWriteIsPending => _lastWriteOutcome == WriteOutcome.pending;

  /// Começa um save. Cada um responde por si.
  void beginWrite() => _lastWriteOutcome = WriteOutcome.confirmed;

  /// Registra o pior resultado do save: um formulário pode escrever mais de
  /// uma vez, e basta uma escrita pendente para a promessa mudar.
  void recordWrite(WriteOutcome outcome) {
    if (outcome == WriteOutcome.pending) _lastWriteOutcome = outcome;
  }
}
