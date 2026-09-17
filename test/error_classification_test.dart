import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';

/// F4.5 — o erro que chega à tela precisa dizer O QUE aconteceu. Enquanto toda
/// falha virava `unknown`, a tela mais comum de todas (sem internet) mostrava
/// "ocorreu um erro inesperado", que é a única coisa que ela não era.
void main() {
  FirebaseException firestore(String code) =>
      FirebaseException(plugin: 'cloud_firestore', code: code);

  group('erro do Firestore vira código do app', () {
    test('unavailable é offline', () {
      expect(errorCodeFor(firestore('unavailable')), ErrorCode.offline);
      expect(isOfflineError(firestore('unavailable')), isTrue);
    });

    test('permission-denied, not-found, unauthenticated e os outros', () {
      expect(
        errorCodeFor(firestore('permission-denied')),
        ErrorCode.permissionDenied,
      );
      expect(errorCodeFor(firestore('not-found')), ErrorCode.notFound);
      expect(
        errorCodeFor(firestore('unauthenticated')),
        ErrorCode.notAuthenticated,
      );
      expect(
        errorCodeFor(firestore('resource-exhausted')),
        ErrorCode.quotaExhausted,
      );
      expect(
        errorCodeFor(firestore('deadline-exceeded')),
        ErrorCode.timeout,
      );
    });

    test('código que não conhecemos continua unknown', () {
      expect(errorCodeFor(firestore('aborted')), ErrorCode.unknown);
      expect(errorCodeFor(Exception('qualquer coisa')), ErrorCode.unknown);
      expect(errorCodeFor(null), ErrorCode.unknown);
    });
  });

  group('callable', () {
    test('internal mudo NÃO é offline fora da web', () {
      // Estes testes rodam na VM (`kIsWeb` falso), que é justamente o caso em
      // que o SDK tem código próprio para falta de rede (`unavailable`). Ali,
      // um `internal` sem mensagem é falha do backend — chamá-la de offline
      // mandaria o usuário conferir a conexão por um problema que não é dele.
      // A exceção da web continua valendo lá, onde o `fetch` que não sai chega
      // exatamente assim.
      final mudo = FirebaseFunctionsException(code: 'internal', message: '');

      expect(errorCodeFor(mudo), ErrorCode.unknown);
      expect(isOfflineCallable(mudo), isFalse);
    });

    test('internal COM mensagem é erro do servidor, não offline', () {
      final doServidor = FirebaseFunctionsException(
        code: 'internal',
        message: 'o modelo recusou a entrada',
      );
      expect(errorCodeFor(doServidor), ErrorCode.unknown);
      expect(isOfflineCallable(doServidor), isFalse);
    });

    test('unavailable e deadline-exceeded são offline em qualquer plataforma', () {
      expect(
        isOfflineCallable(
          FirebaseFunctionsException(code: 'unavailable', message: ''),
        ),
        isTrue,
      );
      expect(
        errorCodeFor(
          FirebaseFunctionsException(code: 'unavailable', message: ''),
        ),
        ErrorCode.offline,
      );
    });
  });

  group('BusinessException.from', () {
    test('classifica o erro original e guarda o rastro', () {
      final stack = StackTrace.current;
      final ex = BusinessException.from(firestore('unavailable'), stack);

      expect(ex.code, ErrorCode.offline);
      expect(ex.stackTrace, stack);
      expect(ex.originalError, isA<FirebaseException>());
    });

    test('não reembrulha o que já é BusinessException', () {
      final original = BusinessException(ErrorCode.goalNotFound);
      expect(
        BusinessException.from(original, StackTrace.current),
        same(original),
      );
      expect(errorCodeFor(original), ErrorCode.goalNotFound);
    });
  });
}
