import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:fake_async/fake_async.dart';

FirebaseFunctionsException _callableError(String code, [String? message]) =>
    FirebaseFunctionsException(code: code, message: message ?? '');

void main() {
  group('settleWrite', () {
    test('escrita confirmada pelo servidor completa na hora', () {
      fakeAsync((async) {
        final completer = Completer<void>();
        bool done = false;

        settleWrite(completer.future).then((_) => done = true);

        completer.complete();
        async.flushMicrotasks();

        expect(done, isTrue);
      });
    });

    test('sem rede, a espera acaba no prazo em vez de nunca', () {
      fakeAsync((async) {
        // O Firestore offline nunca completa este Future: o dado já está no
        // cache local, mas o servidor não confirmou. Era aqui que o botão
        // ficava girando para sempre.
        final nunca = Completer<void>();
        bool done = false;

        settleWrite(
          nunca.future,
          grace: const Duration(seconds: 5),
        ).then((_) => done = true);

        async.elapse(const Duration(seconds: 4));
        expect(done, isFalse, reason: 'antes do prazo ainda vale esperar');

        async.elapse(const Duration(seconds: 2));
        expect(done, isTrue);
      });
    });

    test('erro dentro do prazo continua chegando à tela', () {
      fakeAsync((async) {
        // Uma negativa das rules precisa virar erro visível, não "salvo".
        final falha = Completer<void>();
        Object? capturado;

        settleWrite(falha.future).catchError((Object e) => capturado = e);

        falha.completeError(StateError('permission-denied'));
        async.elapse(const Duration(seconds: 1));

        expect(capturado, isA<StateError>());
      });
    });

    test('erro depois do prazo não vira exceção sem dono', () {
      fakeAsync((async) {
        final falha = Completer<void>();
        bool done = false;

        settleWrite(
          falha.future,
          grace: const Duration(seconds: 5),
        ).then((_) => done = true);

        async.elapse(const Duration(seconds: 6));
        expect(done, isTrue);

        // A tela já seguiu; o erro atrasado não tem para onde voltar e não
        // pode derrubar a zona do app.
        falha.completeError(StateError('tarde demais'));
        async.elapse(const Duration(seconds: 1));
      });
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
      // Os repositórios convertem para BusinessException guardando o original.
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
