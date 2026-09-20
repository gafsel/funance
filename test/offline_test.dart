import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/sync_status.dart';
import 'package:funances/core/firestore/write_failures.dart';

FirebaseFunctionsException _callableError(String code, [String? message]) =>
    FirebaseFunctionsException(code: code, message: message ?? '');

/// Roda [body] com a tarja já ouvindo, e devolve o que ela recebeu.
///
/// O `flushMicrotasks` antes do corpo não é enfeite: a assinatura de um
/// `Stream.multi` só fica ativa no microtask seguinte ao `listen`, e sem ele o
/// evento seria guardado para o próximo assinante em vez de entregue a este.
List<WriteFailureReason> _failuresDuring(void Function(FakeAsync) body) {
  final reasons = <WriteFailureReason>[];

  fakeAsync((async) {
    final sub = WriteFailures.stream.listen((f) => reasons.add(f.reason));
    async.flushMicrotasks();

    body(async);

    async.flushMicrotasks();
    sub.cancel();
  });

  return reasons;
}

void main() {
  setUp(() {
    SyncStatusLatch.reset();
    PendingWrites.reset();
    WriteFailures.clear();
  });

  group('settleWrite offline', () {
    test('desiste rápido e devolve "pendente", em vez de nunca', () {
      fakeAsync((async) {
        SyncStatusLatch.update(SyncStatus.offline);

        // O Firestore offline nunca completa este Future: o dado já está no
        // cache local, mas o servidor não confirmou. Era aqui que o botão
        // ficava girando para sempre.
        final nunca = Completer<void>();
        WriteOutcome? outcome;

        settleWrite(
          nunca.future,
          entity: WriteEntity.transaction,
        ).then((o) => outcome = o);

        async.elapse(const Duration(seconds: 1));
        expect(outcome, isNull, reason: 'antes do prazo ainda vale esperar');

        async.elapse(const Duration(seconds: 2));
        expect(outcome, WriteOutcome.pending);
      });
    });

    test(
      'offline não acusa falha: não há nada de errado em estar sem rede',
      () {
        final reasons = _failuresDuring((async) {
          SyncStatusLatch.update(SyncStatus.offline);
          settleWrite(
            Completer<void>().future,
            entity: WriteEntity.transaction,
          );
          async.elapse(const Duration(seconds: 5));
        });

        expect(reasons, isEmpty);
      },
    );

    test('a escrita pendente entra na contagem que alimenta a tarja', () {
      fakeAsync((async) {
        SyncStatusLatch.update(SyncStatus.offline);

        final write = Completer<void>();
        settleWrite(write.future, entity: WriteEntity.transaction);
        async.elapse(const Duration(seconds: 3));

        expect(PendingWrites.count, 1);

        // Rede voltou e o servidor confirmou.
        write.complete();
        async.flushMicrotasks();

        expect(PendingWrites.count, 0);
      });
    });
  });

  group('settleWrite online', () {
    test('negativa das rules com rede lenta ainda chega como ERRO', () {
      fakeAsync((async) {
        // Este era o furo: o prazo curto dava a escrita como salva, o
        // permission-denied chegava depois e o item sumia da lista sem aviso.
        final falha = Completer<void>();
        Object? capturado;

        settleWrite(falha.future, entity: WriteEntity.transaction).catchError((
          Object e,
        ) {
          capturado = e;
          return WriteOutcome.pending;
        });

        async.elapse(const Duration(seconds: 12));
        falha.completeError(StateError('permission-denied'));
        async.elapse(const Duration(seconds: 1));

        expect(capturado, isA<StateError>());
        expect(PendingWrites.count, 0);
      });
    });

    test('confirmação rápida devolve "confirmado"', () {
      fakeAsync((async) {
        final write = Completer<void>();
        WriteOutcome? outcome;

        settleWrite(
          write.future,
          entity: WriteEntity.transaction,
        ).then((o) => outcome = o);

        write.complete();
        async.flushMicrotasks();

        expect(outcome, WriteOutcome.confirmed);
        expect(PendingWrites.count, 0);
      });
    });

    test('30 s sem resposta vira pendente E aviso visível', () {
      WriteOutcome? outcome;

      final reasons = _failuresDuring((async) {
        settleWrite(
          Completer<void>().future,
          entity: WriteEntity.transaction,
        ).then((o) => outcome = o);
        async.elapse(const Duration(seconds: 31));
      });

      // Online e mudo por 30 s não é "sem rede": alguma coisa está errada e o
      // usuário precisa saber que o que ele salvou não subiu.
      expect(outcome, WriteOutcome.pending);
      expect(reasons, [WriteFailureReason.tookTooLong]);
    });

    test('se a rede caiu no meio, o silêncio deixa de ser culpa de alguém', () {
      // Começou online e terminou offline. Em 30 s a conexão cai com
      // facilidade, e uma tarja vermelha aqui culparia o usuário por isso.
      WriteOutcome? outcome;

      final reasons = _failuresDuring((async) {
        settleWrite(
          Completer<void>().future,
          entity: WriteEntity.transaction,
        ).then((o) => outcome = o);

        async.elapse(const Duration(seconds: 10));
        SyncStatusLatch.update(SyncStatus.offline);
        async.elapse(const Duration(seconds: 21));
      });

      expect(outcome, WriteOutcome.pending);
      expect(reasons, isEmpty);
    });
  });

  group('falha tardia', () {
    test('vira aviso visível, e não só uma linha de log', () {
      final reasons = _failuresDuring((async) {
        SyncStatusLatch.update(SyncStatus.offline);

        final falha = Completer<void>();
        settleWrite(falha.future, entity: WriteEntity.transaction);

        async.elapse(const Duration(seconds: 3));
        expect(PendingWrites.count, 1);

        // A tela que salvou já seguiu; o erro não tem mais para onde voltar.
        falha.completeError(StateError('permission-denied'));
        async.elapse(const Duration(seconds: 1));

        expect(PendingWrites.count, 0);
      });

      expect(reasons, [WriteFailureReason.permissionDenied]);
    });

    test('motivo desconhecido não some, só perde o detalhe', () {
      expect(
        writeFailureReasonOf(StateError('deu ruim')),
        WriteFailureReason.unknown,
      );
      expect(
        writeFailureReasonOf(StateError('not-found: sumiu')),
        WriteFailureReason.notFound,
      );
    });

    test('o que nem chegou a sair do aparelho não é culpa do servidor', () {
      // O codec do Firestore recusa um valor que não sabe serializar antes
      // de qualquer rede acontecer. Chamar isso de "o servidor recusou"
      // manda quem for investigar para o lugar errado — foi o que escondeu
      // as pendências que não sumiam.
      expect(
        writeFailureReasonOf(ArgumentError.value('Instance of _CategoryModel')),
        WriteFailureReason.serializationFailed,
      );
      expect(
        writeFailureReasonOf(TypeError()),
        WriteFailureReason.serializationFailed,
      );
    });
  });

  group('estado que a tarja mostra', () {
    test('offline vence pendência: é a informação acionável', () {
      expect(effectiveSyncStatus(SyncStatus.offline, 3), SyncStatus.offline);
    });

    test('pendência em outra coleção aparece mesmo com metadados "online"', () {
      // Os metadados falam só do documento do usuário; a escrita pendente
      // pode estar em qualquer coleção.
      expect(
        effectiveSyncStatus(SyncStatus.online, 1),
        SyncStatus.pendingWrites,
      );
    });

    test('sem pendência e online, a tarja não aparece', () {
      expect(effectiveSyncStatus(SyncStatus.online, 0), SyncStatus.online);
    });
  });

  group('callable sem rede', () {
    test('unavailable é falta de conexão', () {
      expect(isOfflineCallable(_callableError('unavailable')), isTrue);
    });

    test('deadline-exceeded também', () {
      expect(isOfflineCallable(_callableError('deadline-exceeded')), isTrue);
    });

    test('internal sem mensagem só é falta de rede NA WEB', () {
      // O `internal` mudo é a cara de um `fetch` que não saiu — e isso só
      // acontece na web. Fora dela (onde este teste roda) o SDK tem código
      // próprio para falta de rede, e um `internal` sem mensagem é falha do
      // backend: tratá-lo como offline mandaria o usuário conferir a conexão
      // por um problema que não é dele. A regra é guardada por `kIsWeb`.
      expect(isOfflineCallable(_callableError('internal')), isFalse);
      expect(isOfflineCallable(_callableError('internal', '  ')), isFalse);

      // O que vale em qualquer plataforma continua valendo.
      expect(isOfflineCallable(_callableError('unavailable')), isTrue);
      expect(isOfflineCallable(_callableError('deadline-exceeded')), isTrue);
    });

    test('internal COM mensagem é erro do backend, não falta de rede', () {
      expect(
        isOfflineCallable(_callableError('internal', 'Erro ao chamar a IA')),
        isFalse,
      );
    });

    test('erro de negócio embrulhado mantém o diagnóstico', () {
      final wrapped = BusinessException(
        ErrorCode.unknown,
        originalError: _callableError('unavailable'),
      );

      expect(isOfflineCallable(wrapped), isTrue);
    });

    test('limite de IA não é falta de rede', () {
      expect(
        isOfflineCallable(_callableError('resource-exhausted', 'Restam 0.')),
        isFalse,
      );
    });
  });

  group('mensagem do callable', () {
    test('sem rede, a mensagem de offline vence o texto da tela', () {
      expect(
        callableErrorMessage(
          _callableError('unavailable'),
          'Não foi possível analisar o extrato.',
          offlineMessage: 'Precisa de internet.',
        ),
        'Precisa de internet.',
      );
    });

    test('sem rede e sem mensagem de offline, nada muda', () {
      expect(
        callableErrorMessage(_callableError('unavailable'), 'genérica'),
        'genérica',
      );
    });

    test('a mensagem do servidor continua vencendo quando há rede', () {
      expect(
        callableErrorMessage(
          _callableError('resource-exhausted', 'Restam 0 análises hoje.'),
          'genérica',
          offlineMessage: 'Precisa de internet.',
        ),
        'Restam 0 análises hoje.',
      );
    });
  });
}
