// ignore: implementation_imports
import 'package:cloud_firestore_platform_interface/src/method_channel/utils/firestore_message_codec.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/core/observability/crash_reporter.dart';
import 'package:funances/features/finance/data/models/automatic_transaction_mapper.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';
import 'package:funances/features/finance/domain/services/automatic_transaction_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/notification_listener_service.dart';
import 'package:funances/features/finance/presentation/controllers/automatic_transaction_notifier.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// O bug que o dono relatou: "alguns lançamentos identificados que simplesmente
/// não consigo apagar".
///
/// Em produção a correlação era perfeita — 163 pendências triadas com sucesso,
/// TODAS sem sugestão; 18 empacadas, TODAS com `suggestedCategory`. O motivo
/// estava no `toJson` gerado: sem `explicit_to_json`, `json_serializable`
/// devolvia o OBJETO `CategoryModel`/`AccountModel` dentro do mapa, e o codec
/// do Firestore — que não conhece esses tipos — recusava a escrita inteira.
/// Ignorar não ignorava nada, e como a exceção morria num `VoidCallback` o
/// dono não via erro nenhum: só o item teimando na lista.
///
/// Estes testes prendem as três pernas do conserto: o payload volta a ser
/// gravável, a falha de escrita volta a ser VISÍVEL, e o `nextInvoice` copiado
/// cru para dentro da pendência volta a parsear.

/// A pendência real que ficou presa: cartão sugerido com o `nextInvoice` que o
/// servidor gravou com `Timestamp` nativo, copiado cru pelo leitor.
Map<String, dynamic> _pendenciaComCartaoSugerido() => {
  'id': '018469dd',
  'description': 'Compra aprovada no cartão',
  'amount': 399.97,
  'date': '2026-09-18T16:42:13.521176',
  'type': 'expense',
  'originNotificationId': '21',
  'packageName': 'com.itau',
  'isConsolidated': false,
  'isIgnored': false,
  'suggestedCategory': {
    'id': 'mEBDvj28pajhnY13gMoP',
    'name': 'Compras',
    'icon': 'shopping_cart',
    'color': '#4CAF50',
    'type': 'expense',
  },
  'suggestedAccount': {
    'runtimeType': 'creditCard',
    'id': 'TcBacuoQufLWTZ3BTtgP',
    'name': 'Cartão Itaú',
    'icon': 'credit_card',
    'color': '#EC7000',
    'isDeleted': false,
    'initialBalance': 0,
    'initialBalanceDate': '2026-06-02T12:00:00.000',
    'limit': 8000,
    'dueDay': 10,
    'closingDay': 4,
    'bankLogo': 'itau',
    'ownerIds': ['i7NfnPTD6FPTmotfWy1dCoXoE942'],
    'nextInvoice': {
      'dueDate': Timestamp.fromDate(DateTime.utc(2026, 10, 10, 3)),
      'closingDate': Timestamp.fromDate(DateTime.utc(2026, 10, 4, 3)),
      'cycleStart': Timestamp.fromDate(DateTime.utc(2026, 9, 4, 3)),
      'cycleEnd': Timestamp.fromDate(
        DateTime.utc(2026, 10, 4, 2, 59, 59, 999),
      ),
      'amount': 2843.07,
      'orderId': 'invoice-TcBacuoQufLWTZ3BTtgP-2026-10-10',
      'installmentId': '50f7ykr8HkfINXXW7dYg',
      'status': 'pending',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 16, 12)),
    },
  },
};

/// As outras 15 presas: sugestão completa, mas SEM a cópia do `nextInvoice`.
///
/// Elas parseavam bem e apareciam na lista — só não sumiam. Isolar este caso é
/// o que separa os dois defeitos: aqui não há `Timestamp` nenhum, e a escrita
/// falhava mesmo assim.
Map<String, dynamic> _pendenciaComContaSemFatura() {
  final Map<String, dynamic> doc = _pendenciaComCartaoSugerido();
  doc['id'] = 'auto-sem-fatura';
  (doc['suggestedAccount']! as Map<String, dynamic>).remove('nextInvoice');
  return doc;
}

/// A pendência sem sugestão nenhuma — a que SEMPRE deu certo de ignorar.
Map<String, dynamic> _pendenciaCrua() => {
  'id': 'auto-crua',
  'description': 'PIX ENVIADO',
  'amount': 88.98,
  'date': '2026-09-04T10:50:47.466240',
  'type': 'expense',
  'isConsolidated': false,
  'isIgnored': false,
};

/// O codec REAL — o mesmo que o `cloud_firestore` usa para mandar a escrita
/// pelo canal de plataforma.
///
/// Ele é `const` e não precisa de canal nenhum para codificar, então dá para
/// exercitá-lo direto: `Timestamp`, `GeoPoint` e companhia ele conhece; tudo
/// que não conhece cai no `writeValue` do `StandardMessageCodec`, que recusa
/// com `ArgumentError`. É exatamente esse caminho que engolia a triagem.
void _codificaComoOFirestore(Object payload) {
  const FirestoreMessageCodec().encodeMessage(payload);
}

class _RepositorioFalso implements IAutomaticTransactionRepository {
  _RepositorioFalso(this.pendentes);

  List<AutomaticTransactionModel> pendentes;

  /// Quando presente, TODA escrita falha com isto.
  Object? falha;

  /// Quando presente, a RELEITURA falha com isto.
  Object? falhaNaLeitura;

  final List<String> escritas = <String>[];

  @override
  Future<List<AutomaticTransactionModel>> getPendingTransactions(
    String _,
  ) async {
    final Object? erro = falhaNaLeitura;
    if (erro != null) throw erro;
    return pendentes;
  }

  @override
  Future<void> updateTransaction(
    String workspaceId,
    AutomaticTransactionModel transaction,
  ) async {
    escritas.add('update:${transaction.id}');
    final Object? erro = falha;
    if (erro != null) throw erro;
    pendentes = pendentes.where((t) => t.id != transaction.id).toList();
  }

  @override
  Future<void> moveTransaction(
    String fromWorkspaceId,
    String toWorkspaceId,
    AutomaticTransactionModel transaction,
  ) async {
    escritas.add('move:${transaction.id}');
    final Object? erro = falha;
    if (erro != null) throw erro;
    pendentes = pendentes.where((t) => t.id != transaction.id).toList();
  }

  @override
  Future<void> saveTransaction(String _, AutomaticTransactionModel _) async {}

  @override
  Future<void> deleteTransaction(String _, String _) async {}

  @override
  Future<bool> existsByNotificationId(String _, String _) async => false;
}

class _FinanceServiceParado implements FinanceService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _NotificacoesParadas implements INotificationListenerService {
  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<bool> isPermissionGranted() async => false;

  @override
  Future<void> openPermissionSettings() async {}
}

AutomaticTransactionNotifier _notifier(_RepositorioFalso repositorio) {
  return AutomaticTransactionNotifier(
    service: AutomaticTransactionService(
      workspaceId: 'ws-1',
      repository: repositorio,
    ),
    financeService: _FinanceServiceParado(),
    notificationService: _NotificacoesParadas(),
  );
}

void main() {
  group('o payload de triagem é gravável', () {
    test('o mapa não leva NENHUM objeto de modelo para o Firestore', () {
      final Map<String, dynamic> payload = AutomaticTransactionModel.fromJson(
        _pendenciaComCartaoSugerido(),
      ).toJson();

      expect(payload['suggestedCategory'], isA<Map<String, dynamic>>());
      expect(payload['suggestedAccount'], isA<Map<String, dynamic>>());
    });

    test('o codec do Firestore aceita a pendência COM sugestão', () {
      final Map<String, dynamic> payload = AutomaticTransactionModel.fromJson(
        _pendenciaComCartaoSugerido(),
      ).copyWith(isIgnored: true).toJson();

      // Antes do conserto isto era `Invalid argument(s): Instance of
      // 'CreditCardAccount'` — a escrita inteira recusada, e com ela o
      // `isIgnored: true` que o dono tinha pedido.
      expect(() => _codificaComoOFirestore(payload), returnsNormally);
    });

    test('o codec aceita a pendência com sugestão e SEM fatura embutida', () {
      // O caso que separa os dois defeitos: sem `Timestamp` nenhum no
      // documento, o parse sempre funcionou — e a escrita falhava mesmo
      // assim, porque o objeto `CheckingAccount`/`CreditCardAccount` ia cru
      // dentro do mapa. São 15 das 18 pendências presas em produção.
      final Map<String, dynamic> payload = AutomaticTransactionModel.fromJson(
        _pendenciaComContaSemFatura(),
      ).copyWith(isIgnored: true).toJson();

      expect(() => _codificaComoOFirestore(payload), returnsNormally);
    });

    test('a pendência SEM sugestão continua gravável, como sempre esteve', () {
      final Map<String, dynamic> payload = AutomaticTransactionModel.fromJson(
        _pendenciaCrua(),
      ).copyWith(isIgnored: true).toJson();

      expect(() => _codificaComoOFirestore(payload), returnsNormally);
    });

    test('a forma gravada é a MESMA que o modelo aninhado produz', () {
      final AutomaticTransactionModel pendencia =
          AutomaticTransactionModel.fromJson(_pendenciaComCartaoSugerido());
      final Map<String, dynamic> payload = pendencia.toJson();

      expect(payload['suggestedCategory'], pendencia.suggestedCategory!.toJson());
      expect(payload['suggestedAccount'], pendencia.suggestedAccount!.toJson());
      expect(
        (payload['suggestedAccount']! as Map<String, dynamic>)['runtimeType'],
        'creditCard',
        reason: 'a união precisa do discriminador para voltar do Firestore',
      );
    });

    test('ida e volta: o que foi gravado volta igual', () {
      final AutomaticTransactionModel original =
          AutomaticTransactionModel.fromJson(_pendenciaComCartaoSugerido());

      final AutomaticTransactionModel voltou = AutomaticTransactionModel.fromJson(
        original.toJson(),
      );

      expect(voltou.suggestedCategory, original.suggestedCategory);
      expect(voltou.id, original.id);
      expect(voltou.amount, original.amount);
      expect(
        (voltou.suggestedAccount! as CreditCardAccount).nextInvoice,
        isNull,
        reason:
            'a ida e volta NÃO preserva nextInvoice, e isso é de propósito: '
            '`includeToJson: false` apara a cópia embutida na primeira '
            'regravação. A fonte da verdade da fatura é `accounts/{id}`, que '
            'o servidor mantém; uma segunda cópia aqui só envelheceria',
      );
    });
  });

  group('a triagem que falha APARECE', () {
    late List<WriteFailure> falhas;
    late List<Object> reportados;

    setUp(() {
      WriteFailures.clear();
      falhas = <WriteFailure>[];
      reportados = <Object>[];
      WriteFailures.stream.listen(falhas.add);
      CrashReporter.onRecord = (error, stack, reason) => reportados.add(error);
    });

    tearDown(() {
      CrashReporter.onRecord = null;
      WriteFailures.clear();
    });

    test('ignorar com escrita OK tira o item da lista e não acusa nada', () async {
      final _RepositorioFalso repositorio = _RepositorioFalso([
        AutomaticTransactionModel.fromJson(_pendenciaComCartaoSugerido()),
      ]);
      final AutomaticTransactionNotifier notifier = _notifier(repositorio);
      await notifier.loadTransactions();

      await notifier.ignore(notifier.state.pendingTransactions.single);

      expect(notifier.state.pendingTransactions, isEmpty);
      expect(falhas, isEmpty);
    });

    test('ignorar com escrita recusada mantém o item E acende a tarja', () async {
      final _RepositorioFalso repositorio = _RepositorioFalso([
        AutomaticTransactionModel.fromJson(_pendenciaComCartaoSugerido()),
      ]);
      repositorio.falha = ArgumentError.value(
        'Instance of CreditCardAccount',
        'value',
        'Invalid argument',
      );
      final AutomaticTransactionNotifier notifier = _notifier(repositorio);
      await notifier.loadTransactions();

      await notifier.ignore(notifier.state.pendingTransactions.single);

      expect(
        notifier.state.pendingTransactions.map((t) => t.id),
        ['018469dd'],
        reason: 'nada mudou no servidor, então o item VOLTA — essa é a verdade',
      );
      expect(falhas.single.entity, WriteEntity.automaticTransaction);
      expect(
        falhas.single.reason,
        WriteFailureReason.serializationFailed,
        reason:
            'a escrita nunca saiu do aparelho — dizer "o servidor recusou" '
            'mandaria o dono investigar o lugar errado',
      );
      expect(reportados, hasLength(1));
    });

    test('releitura que falha não escapa, e a lista anterior fica', () async {
      // O `finally` do `_triage` chama `loadTransactions`, e os botões que
      // chamam a triagem são `VoidCallback`: se a releitura lançasse, o erro
      // não teria para onde voltar — a mesma porta por onde o bug original
      // ficou invisível.
      final _RepositorioFalso repositorio = _RepositorioFalso([
        AutomaticTransactionModel.fromJson(_pendenciaCrua()),
      ]);
      final AutomaticTransactionNotifier notifier = _notifier(repositorio);
      await notifier.loadTransactions();

      repositorio.falhaNaLeitura = StateError('servidor fora do ar');

      await expectLater(
        notifier.ignore(notifier.state.pendingTransactions.single),
        completes,
      );
      expect(
        notifier.state.pendingTransactions.map((t) => t.id),
        ['auto-crua'],
        reason: 'stale, mas é o último estado que o servidor confirmou',
      );
      expect(notifier.state.isLoading, isFalse);
      expect(reportados, hasLength(1), reason: 'some da tela, não do relatório');
      expect(
        falhas,
        isEmpty,
        reason:
            'a escrita deu certo; acender "não foi possível salvar" por uma '
            'LEITURA que falhou seria mentira',
      );
    });

    test('a recusa das rules chega com o motivo certo', () async {
      final _RepositorioFalso repositorio = _RepositorioFalso([
        AutomaticTransactionModel.fromJson(_pendenciaCrua()),
      ]);
      repositorio.falha = Exception(
        '[cloud_firestore/permission-denied] Missing or insufficient permissions.',
      );
      final AutomaticTransactionNotifier notifier = _notifier(repositorio);
      await notifier.loadTransactions();

      await notifier.ignore(notifier.state.pendingTransactions.single);

      expect(falhas.single.reason, WriteFailureReason.permissionDenied);
    });

    test('mover para outro cofre também avisa quando falha', () async {
      final _RepositorioFalso repositorio = _RepositorioFalso([
        AutomaticTransactionModel.fromJson(_pendenciaCrua()),
      ]);
      repositorio.falha = StateError('sem rede');
      final AutomaticTransactionNotifier notifier = _notifier(repositorio);
      await notifier.loadTransactions();

      await notifier.moveToWorkspace(
        notifier.state.pendingTransactions.single,
        'ws-2',
      );

      expect(repositorio.escritas, ['move:auto-crua']);
      expect(notifier.state.pendingTransactions, hasLength(1));
      expect(falhas.single.entity, WriteEntity.automaticTransaction);
    });
  });

  group('nextInvoice aceita Timestamp E texto ISO', () {
    test('o documento que estava ESCONDIDO volta a aparecer', () {
      final List<String> ilegiveis = <String>[];

      final List<AutomaticTransactionModel> itens = parsePendingTransactions(
        [(id: '018469dd', data: _pendenciaComCartaoSugerido())],
        onInvalid: (id, error, stack) => ilegiveis.add(id),
      );

      expect(
        ilegiveis,
        isEmpty,
        reason:
            "antes: type 'Timestamp' is not a subtype of type 'String' in "
            'type cast, em _\$NextInvoiceFromJson',
      );
      expect(itens.single.id, '018469dd');
    });

    test('Timestamp e ISO dão o MESMO instante', () {
      final DateTime instante = DateTime.utc(2026, 10, 10, 3);

      final NextInvoice deTimestamp = NextInvoice.fromJson({
        'dueDate': Timestamp.fromDate(instante),
        'closingDate': Timestamp.fromDate(instante),
        'cycleStart': Timestamp.fromDate(instante),
        'cycleEnd': Timestamp.fromDate(instante),
      });
      final NextInvoice deTexto = NextInvoice.fromJson({
        'dueDate': instante.toIso8601String(),
        'closingDate': instante.toIso8601String(),
        'cycleStart': instante.toIso8601String(),
        'cycleEnd': instante.toIso8601String(),
      });

      expect(deTimestamp.dueDate.toUtc(), instante);
      expect(deTimestamp, deTexto);
    });

    test('a hora exata do ciclo não é normalizada', () {
      final DateTime fim = DateTime.utc(2026, 10, 4, 2, 59, 59, 999);

      final NextInvoice fatura = NextInvoice.fromJson({
        'dueDate': Timestamp.fromDate(DateTime.utc(2026, 10, 10, 3)),
        'closingDate': Timestamp.fromDate(DateTime.utc(2026, 10, 4, 3)),
        'cycleStart': Timestamp.fromDate(DateTime.utc(2026, 9, 4, 3)),
        'cycleEnd': Timestamp.fromDate(fim),
      });

      expect(fatura.cycleEnd.toUtc(), fim);
    });

    test('a SAÍDA continua sendo texto ISO — a gravação não mudou', () {
      final NextInvoice fatura = NextInvoice.fromJson({
        'dueDate': Timestamp.fromDate(DateTime.utc(2026, 10, 10, 3)),
        'closingDate': Timestamp.fromDate(DateTime.utc(2026, 10, 4, 3)),
        'cycleStart': Timestamp.fromDate(DateTime.utc(2026, 9, 4, 3)),
        'cycleEnd': Timestamp.fromDate(DateTime.utc(2026, 10, 4, 3)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 16, 12)),
      });

      final Map<String, dynamic> json = fatura.toJson();

      expect(json['dueDate'], isA<String>());
      expect(json['updatedAt'], isA<String>());
      expect(() => _codificaComoOFirestore(json), returnsNormally);
    });

    test('updatedAt ausente continua null, e não explode', () {
      final NextInvoice fatura = NextInvoice.fromJson({
        'dueDate': '2026-10-10T00:00:00.000Z',
        'closingDate': '2026-10-04T00:00:00.000Z',
        'cycleStart': '2026-09-04T00:00:00.000Z',
        'cycleEnd': '2026-10-04T00:00:00.000Z',
      });

      expect(fatura.updatedAt, isNull);
    });

    test('um tipo que não é data diz QUAL tipo veio', () {
      expect(
        () => NextInvoice.fromJson({
          'dueDate': 1791633600,
          'closingDate': '2026-10-04T00:00:00.000Z',
          'cycleStart': '2026-09-04T00:00:00.000Z',
          'cycleEnd': '2026-10-04T00:00:00.000Z',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('int'),
          ),
        ),
      );
    });
  });

  /// Item 2 do QA: o conserto não pode abrir a mesma porta de novo.
  ///
  /// `TimestampOrIsoConverter` lança em valor inesperado, e um `nextInvoice`
  /// pela metade dentro de `suggestedAccount` derrubaria a conta, a pendência
  /// e o documento inteiro — exatamente o defeito de origem. A regra
  /// "fatura incompleta é DESCARTADA" saiu do mapper da camada de dados e
  /// passou a viver no modelo, onde vale para os dois caminhos.
  group('fatura pela metade não derruba a pendência', () {
    Map<String, dynamic> pendenciaComFaturaQuebrada(
      void Function(Map<String, dynamic> fatura) estraga,
    ) {
      final Map<String, dynamic> doc = _pendenciaComCartaoSugerido();
      final conta = doc['suggestedAccount']! as Map<String, dynamic>;
      estraga(conta['nextInvoice']! as Map<String, dynamic>);
      return doc;
    }

    test('nextInvoice sem dueDate: a pendência APARECE, sem a fatura', () {
      final List<String> ilegiveis = <String>[];

      final itens = parsePendingTransactions(
        [
          (
            id: '018469dd',
            data: pendenciaComFaturaQuebrada((f) => f.remove('dueDate')),
          ),
        ],
        onInvalid: (id, error, stack) => ilegiveis.add('$id: $error'),
      );

      expect(ilegiveis, isEmpty);
      final conta = itens.single.suggestedAccount! as CreditCardAccount;
      expect(conta.name, 'Cartão Itaú', reason: 'a conta continua parseando');
      expect(
        conta.nextInvoice,
        isNull,
        reason: 'melhor "calculando" do que uma fatura com borda pela metade',
      );
    });

    test('nextInvoice com data de tipo impossível também degrada', () {
      final itens = parsePendingTransactions([
        (
          id: '018469dd',
          data: pendenciaComFaturaQuebrada((f) => f['cycleEnd'] = 42),
        ),
      ], onInvalid: (id, error, stack) => fail('não deveria pular: $error'));

      expect(
        (itens.single.suggestedAccount! as CreditCardAccount).nextInvoice,
        isNull,
      );
    });

    test('nextInvoice que não é mapa não derruba nada', () {
      final Map<String, dynamic> doc = _pendenciaComCartaoSugerido();
      (doc['suggestedAccount']! as Map<String, dynamic>)['nextInvoice'] =
          'era para ser um mapa';

      final itens = parsePendingTransactions([
        (id: '018469dd', data: doc),
      ], onInvalid: (id, error, stack) => fail('não deveria pular: $error'));

      expect(
        (itens.single.suggestedAccount! as CreditCardAccount).nextInvoice,
        isNull,
      );
    });

    test('a fatura ÍNTEIRA continua chegando inteira', () {
      final itens = parsePendingTransactions([
        (id: '018469dd', data: _pendenciaComCartaoSugerido()),
      ]);

      final fatura = (itens.single.suggestedAccount! as CreditCardAccount)
          .nextInvoice!;
      expect(fatura.amount, 2843.07);
      expect(fatura.dueDate.toUtc(), DateTime.utc(2026, 10, 10, 3));
    });
  });

  /// Item 1 do QA: os gêmeos latentes. Mesmo defeito, ainda adormecido porque
  /// hoje só são LIDOS — e foi assim que o de `automatic_transactions` passou
  /// meses invisível.
  group('os modelos aninhados vizinhos também são gravaveis', () {
    test('ReconciliationTransaction passa pelo codec real', () {
      final ReconciliationTransaction transacao = ReconciliationTransaction(
        description: 'MERCADO CENTRAL',
        amount: 132.4,
        date: DateTime.utc(2026, 3, 15, 15),
        type: OrderType.expense,
        category: const CategoryModel(
          id: 'mercado',
          name: 'Mercado',
          icon: 'shopping_cart',
          color: '#2E7D32',
        ),
      );

      final Map<String, dynamic> json = transacao.toJson();

      expect(json['category'], isA<Map<String, dynamic>>());
      expect(() => _codificaComoOFirestore(json), returnsNormally);
    });

    test('AccountDocumentAnalysisResult passa pelo codec real', () {
      final AccountDocumentAnalysisResult resultado =
          AccountDocumentAnalysisResult(
            account: AccountModel.fromJson(
              (_pendenciaComContaSemFatura()['suggestedAccount']!
                  as Map<String, dynamic>),
            ),
          );

      final Map<String, dynamic> json = resultado.toJson();

      expect(json['account'], isA<Map<String, dynamic>>());
      expect(json['orders'], isEmpty);
      expect(() => _codificaComoOFirestore(json), returnsNormally);
    });
  });
}
