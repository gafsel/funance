import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/observability/app_logger.dart';
import 'package:funances/core/observability/crash_reporter.dart';
import 'package:funances/features/finance/data/models/automatic_transaction_mapper.dart';

/// M2 — a mensagem era descartada antes de chegar ao relatório.
///
/// `AppLogger.error` recebe o que o app SABIA quando pegou a falha — qual
/// documento, qual operação — e mandava isso só para o `developer.log` de
/// debug. Em release o Crashlytics recebia a exceção sozinha, que quase
/// sempre é um `TypeError` genérico: o relatório dizia que algo quebrou e não
/// dizia onde procurar.
void main() {
  late List<({Object error, String? reason})> registrados;

  setUp(() {
    registrados = [];
    CrashReporter.onRecord = (error, stack, reason) =>
        registrados.add((error: error, reason: reason));
  });

  tearDown(() => CrashReporter.onRecord = null);

  test('a mensagem viaja como reason', () {
    final falha = StateError('campo ausente');

    AppLogger.error(
      'automatic_transactions: documento ilegível ignorado (auto-8f2c)',
      falha,
      StackTrace.current,
    );

    expect(registrados, hasLength(1));
    expect(registrados.single.error, same(falha));
    expect(
      registrados.single.reason,
      contains('auto-8f2c'),
      reason: 'o id é a única parte que permite ACHAR o documento',
    );
  });

  test('o caminho real do parse também leva o id', () {
    parsePendingTransactions([
      (id: 'auto-quebrado', data: const {'id': 42}),
    ]);

    expect(registrados, hasLength(1));
    expect(registrados.single.reason, contains('auto-quebrado'));
    expect(
      registrados.single.reason,
      isNot(contains('COMPRA')),
      reason:
          'o CONTEÚDO do documento não entra no relatório: ele carrega '
          'descrição de compra e valor',
    );
  });

  group('a linha do log local', () {
    test('põe o motivo na frente da exceção', () {
      expect(
        CrashReporter.localMessage(
          StateError('campo ausente'),
          'documento ilegível (auto-8f2c)',
        ),
        'documento ilegível (auto-8f2c) — Bad state: campo ausente',
      );
    });

    test('sem motivo, é só a exceção', () {
      expect(
        CrashReporter.localMessage(StateError('x'), null),
        'Bad state: x',
      );
      expect(CrashReporter.localMessage(StateError('x'), ''), 'Bad state: x');
    });

    test('erro nulo não vira linha vazia', () {
      expect(CrashReporter.localMessage(null, null), 'Erro desconhecido');
    });
  });
}
