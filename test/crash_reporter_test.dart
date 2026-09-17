import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/observability/crash_reporter.dart';

/// Um erro na web costuma vir em rajada: um `build` que falha repete a cada
/// quadro. Sem teto, uma tela quebrada geraria milhares de eventos, estouraria
/// a cota do Analytics e afogaria os eventos de produto.
void main() {
  setUp(CrashReporter.resetWebErrorBudget);

  test('o mesmo erro só conta uma vez', () {
    expect(CrashReporter.shouldSendWebError('StateError'), isTrue);
    expect(CrashReporter.shouldSendWebError('StateError'), isFalse);
    expect(CrashReporter.shouldSendWebError('StateError'), isFalse);
  });

  test('tipos diferentes são coisas diferentes e todos passam', () {
    expect(CrashReporter.shouldSendWebError('StateError'), isTrue);
    expect(CrashReporter.shouldSendWebError('RangeError'), isTrue);
    expect(CrashReporter.shouldSendWebError('FormatException'), isTrue);
  });

  test('passados 20 tipos distintos, a sessão para de mandar', () {
    for (int i = 0; i < 20; i++) {
      expect(
        CrashReporter.shouldSendWebError('Erro$i'),
        isTrue,
        reason: 'os 20 primeiros cabem no orçamento',
      );
    }

    expect(CrashReporter.shouldSendWebError('Erro20'), isFalse);
  });

  group('tipo do erro', () {
    test('é o nome da classe, e não a mensagem', () {
      // A mensagem de uma exceção do app pode carregar valor, descrição
      // digitada ou id de documento. O Analytics não é lugar para isso.
      expect(
        CrashReporter.webErrorType(StateError('saldo de R\$ 1.234,56')),
        'StateError',
      );
    });

    test('erro nulo não vira string vazia', () {
      expect(CrashReporter.webErrorType(null), 'unknown');
    });

    test('nome absurdamente longo é cortado no limite do Analytics', () {
      final longo = Object();
      expect(CrashReporter.webErrorType(longo).length, lessThanOrEqualTo(100));
    });
  });
}
