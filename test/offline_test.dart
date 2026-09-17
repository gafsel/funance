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

/// Coleta o que a tarja receberia enquanto o corpo roda.
List<WriteFailureReason> _collectFailures(void Function() body) {
  final reasons = <WriteFailureReason>[];
  final sub = WriteFailures.stream.listen((f) => reasons.add(f.reason));

  try {
    body();
  } finally {
    sub.cancel();
  }

  return reasons;
}

void main() {
  setUp(() {
    SyncStatusLatch.reset();
    PendingWrites.reset();
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

        settleWrite(nunca.future).then((o) => outcome = o);

        async.elapse(const Duration(seconds: 1));
        expect(outcome, isNull, reason: 'antes do prazo ainda vale esperar');

        async.elapse(const Duration(seconds: 2));
        expect(outcome, WriteOutcome.pending);
      });
    });

    test('offline não acusa falha: não há nada de errado em estar sem rede', () {
      final reasons = _collectFailures(() {
        fakeAsync((async) {
          SyncStatusLatch.update(SyncStatus.offline);
          settleWrite(Completer<void>().future);
          async.elapse(const Duration(seconds: 5));
        });
      });

      expect(reasons, isEmpty);
    });

    test('a escrita pendente entra na contagem que alimenta a tarja', () {
      fakeAsync((async) {
        SyncStatusLatch.update(SyncStatus.offline);

        final write = Completer<void>();
        settleWrite(write.future);
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

        settleWrite(falha.future).catchError((Object e) {
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

        settleWrite(write.future).then((o) => outcome = o);

        write.complete();
        async.flushMicrotasks();

        expect(outcome, WriteOutcome.confirmed);
        expect(PendingWrites.count, 0);
      });
    });

    test('30 s sem resposta vira pendente E aviso visível', () {
      late List<WriteFailureReason> reasons;
      WriteOutcome? outcome;

      reasons = _collectFailures(() {
        fakeAsync((async) {
          settleWrite(Completer<void>().future).then((o) => outcome = o);
          async.elapse(const Duration(seconds: 31));
        });
      });

      // Online e mudo por 30 s não é "sem rede": alguma coisa está errada e o
      // usuário precisa saber que o que ele salvou não subiu.
      expect(outcome, WriteOutcome.pending);
      expect(reasons, [WriteFailureReason.tookTooLong]);
    });
  });

  group('falha tardia', () {
    test('vira aviso visível, e não só uma linha de log', () {
      final reasons = _collectFailures(() {
        fakeAsync((async) {
          SyncStatusLatch.update(SyncStatus.offline);

          final falha = Completer<void>();
          settleWrite(falha.future);

          async.elapse(const Duration(seconds: 3));
          expect(PendingWrites.count, 1);

          // A tela que salvou já seguiu; o erro não tem mais para onde voltar.
          falha.completeError(StateError('permission-denied'));
          async.elapse(const Duration(seconds: 1));

          expect(PendingWrites.count, 0);
        });
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

    test('internal sem mensagem é o fetch da web que não saiu', () {
      expect(isOfflineCallable(_callableError('internal')), isTrue);
      expect(isOfflineCallable(_callableError('internal', '  ')), isTrue);
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
