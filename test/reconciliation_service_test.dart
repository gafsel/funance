import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/files/picked_document.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/reconciliation_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/reconciliation_ids.dart';
import 'package:funances/features/finance/domain/services/reconciliation_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// F4.10 §6.5 — `ReconciliationService` é o serviço de maior risco do app e
/// não tinha um único teste. Ele casa dinheiro de verdade com parcelas de
/// verdade, liquida o que casou e grava o documento que paga XP no servidor.
///
/// Convenção dos valores: o extrator devolve o valor SEMPRE positivo e a
/// direção no `type` (ver o prompt `reconciliation` em `ai.config.ts`). O
/// casamento compara valor com valor, sem sinal.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _ExtratoFake with _NaoUsado implements IAccountRepository {
  _ExtratoFake(this.linhas);

  final List<ReconciliationTransaction> linhas;

  @override
  Future<List<ReconciliationTransaction>> analyzeReconciliationDocument(
    String workspaceId,
    PickedDocument document, {
    String? uploadId,
  }) async => linhas;
}

class _CategoriasFake with _NaoUsado implements ICategoryRepository {
  _CategoriasFake([this.existentes = const []]);

  final List<CategoryModel> existentes;
  final List<CategoryModel> criadas = [];

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value([...existentes, ...criadas]);

  @override
  Future<Written<CategoryModel>> createCategory(
    String workspaceId,
    CategoryModel category,
  ) async {
    criadas.add(category);
    return (value: category, outcome: WriteOutcome.confirmed);
  }
}

class _ContasFake with _NaoUsado implements IAccountRepository {}

class _WorkspaceFake with _NaoUsado implements IWorkspaceRepository {}

/// Um Firestore de mentira, mas com a mesma semântica que importa aqui:
/// `set` num id que já existe SOBRESCREVE; não duplica.
class _LancamentosFake with _NaoUsado implements IFinanceRepository {
  _LancamentosFake({this.parcelas = const []});

  final List<InstallmentModel> parcelas;

  final Map<String, OrderModel> ordersPorId = {};
  int chamadasDeAddOrder = 0;
  final List<InstallmentModel> parcelasAtualizadas = [];
  final List<String> parcelasCanceladas = [];

  @override
  Future<QueryChunk<InstallmentModel>> queryInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    bool descending = true,
    dynamic chunkRef,
  }) async => QueryChunk(items: parcelas);

  @override
  Future<Written<OrderModel>> addOrder(
    String workspaceId,
    OrderModel order, {
    String? documentId,
  }) async {
    chamadasDeAddOrder++;
    final id = documentId ?? 'auto-${ordersPorId.length}';
    ordersPorId[id] = order.copyWith(id: id);
    return (value: order.copyWith(id: id), outcome: WriteOutcome.confirmed);
  }

  @override
  Future<WriteOutcome> updateInstallment(
    String workspaceId,
    InstallmentModel installment,
  ) async {
    parcelasAtualizadas.add(installment);
    return WriteOutcome.confirmed;
  }

  @override
  Future<InstallmentModel> getInstallment(
    String workspaceId,
    String installmentId,
  ) async => parcelas.firstWhere((p) => p.id == installmentId);
}

class _ResumosFake with _NaoUsado implements IReconciliationRepository {
  final Map<String, ({int confirmados, int processados, int criados})>
  porId = {};
  int chamadas = 0;

  @override
  Future<void> saveUploadProgress(
    String workspaceId,
    String uploadId,
    UploadProgressModel progress,
  ) async {}

  @override
  Future<void> saveReconciliationSummary(
    String workspaceId,
    String recId, {
    required int confirmedMatchesCount,
    required int totalTransactionsProcessed,
    required int createdTransactionsCount,
  }) async {
    chamadas++;
    porId[recId] = (
      confirmados: confirmedMatchesCount,
      processados: totalTransactionsProcessed,
      criados: createdTransactionsCount,
    );
  }
}

final _conta = AccountModel.checking(
  id: 'acc-1',
  name: 'Conta Corrente',
  icon: 'account_balance',
  color: '#1565C0',
  initialBalanceDate: DateTime(2026, 1, 1),
);

ReconciliationTransaction _linha({
  required String descricao,
  required double valor,
  required int dia,
  OrderType tipo = OrderType.expense,
}) => ReconciliationTransaction(
  description: descricao,
  amount: valor,
  date: DateTime(2026, 3, dia, 12),
  type: tipo,
);

InstallmentModel _parcela({
  required String id,
  required double valor,
  required int dia,
  String descricao = 'Parcela',
}) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  amount: valor,
  description: descricao,
  dueDate: DateTime(2026, 3, dia, 12),
  status: InstallmentStatus.pending,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
  accounts: const {'acc-1': AccountImpact.debt},
);

({
  ReconciliationService servico,
  _LancamentosFake lancamentos,
  _ResumosFake resumos,
  _CategoriasFake categorias,
})
_montar({
  List<ReconciliationTransaction> extrato = const [],
  List<InstallmentModel> parcelas = const [],
  List<CategoryModel> categoriasExistentes = const [],
}) {
  final lancamentos = _LancamentosFake(parcelas: parcelas);
  final resumos = _ResumosFake();
  final categorias = _CategoriasFake(categoriasExistentes);

  return (
    servico: ReconciliationService(
      workspaceId: 'ws',
      repository: resumos,
      accountService: AccountService(
        workspaceId: 'ws',
        repository: _ExtratoFake(extrato),
        workspaceRepository: _WorkspaceFake(),
      ),
      financeService: FinanceService(
        workspaceId: 'ws',
        repository: lancamentos,
        accountRepository: _ContasFake(),
        categoryRepository: categorias,
      ),
      categoryService: CategoryService(
        workspaceId: 'ws',
        repository: categorias,
      ),
    ),
    lancamentos: lancamentos,
    resumos: resumos,
    categorias: categorias,
  );
}

/// O id de uma linha SOZINHA num extrato — a primeira (e única) ocorrência.
String _idDe(ReconciliationTransaction linha, {String conta = 'acc-1'}) =>
    ReconciliationIds.orderIdsFor(conta, [
      ReconciliationMatch(documentTransaction: linha),
    ]).single!;

Future<List<ReconciliationMatch>> _ler(
  ReconciliationService servico,
) => servico.loadMatchesForDocument(
  document: PickedDocument(name: 'extrato.ofx', bytes: Uint8List(0)),
  accountId: 'acc-1',
);

void main() {
  group('casamento automático', () {
    test('mesmo valor e ±1 dia é CASADO, sem perguntar', () async {
      final ambiente = _montar(
        extrato: [_linha(descricao: 'MERCADO', valor: 250, dia: 10)],
        parcelas: [_parcela(id: 'i1', valor: 250, dia: 11)],
      );

      final matches = await _ler(ambiente.servico);

      expect(matches, hasLength(1));
      expect(matches.first.status, ReconciliationMatchStatus.matched);
      expect(matches.first.systemInstallment?.id, 'i1');
    });

    test('mesmo valor dentro de 7 dias é SUGESTÃO, que o usuário confirma',
        () async {
      final ambiente = _montar(
        extrato: [_linha(descricao: 'MERCADO', valor: 250, dia: 10)],
        parcelas: [_parcela(id: 'i1', valor: 250, dia: 15)],
      );

      final matches = await _ler(ambiente.servico);

      expect(matches.first.status, ReconciliationMatchStatus.suggested);
    });

    test('fora da janela de 7 dias não casa', () async {
      final ambiente = _montar(
        extrato: [_linha(descricao: 'MERCADO', valor: 250, dia: 1)],
        parcelas: [_parcela(id: 'i1', valor: 250, dia: 20)],
      );

      final matches = await _ler(ambiente.servico);

      // Duas linhas: a do extrato sem par e a do sistema sem par.
      expect(matches, hasLength(2));
      expect(
        matches.map((m) => m.status),
        everyElement(ReconciliationMatchStatus.unmatched),
      );
    });

    test('valor diferente não casa, nem por um centavo', () async {
      // A tolerância de um centavo que havia aqui não descrevia regra
      // nenhuma: era medo do resto do `double`. Em centavos inteiros a
      // comparação é exata.
      final ambiente = _montar(
        extrato: [_linha(descricao: 'MERCADO', valor: 250.01, dia: 10)],
        parcelas: [_parcela(id: 'i1', valor: 250, dia: 10)],
      );

      final matches = await _ler(ambiente.servico);

      expect(matches, hasLength(2));
    });

    test('uma parcela casa com UMA linha só — a lista é consumida', () async {
      // Duas compras iguais no mesmo dia e uma parcela só: a primeira leva a
      // parcela, a segunda fica sem par. Sem o consumo da lista, as duas
      // casariam com a mesma parcela e a liquidação aconteceria duas vezes.
      final ambiente = _montar(
        extrato: [
          _linha(descricao: 'MERCADO 1', valor: 250, dia: 10),
          _linha(descricao: 'MERCADO 2', valor: 250, dia: 10),
        ],
        parcelas: [_parcela(id: 'i1', valor: 250, dia: 10)],
      );

      final matches = await _ler(ambiente.servico);

      expect(matches, hasLength(2));
      expect(
        matches.where((m) => m.systemInstallment != null),
        hasLength(1),
      );
    });

    test('parcela do sistema que o extrato não tem entra na lista', () async {
      final ambiente = _montar(
        extrato: [_linha(descricao: 'MERCADO', valor: 250, dia: 10)],
        parcelas: [
          _parcela(id: 'i1', valor: 250, dia: 10),
          _parcela(id: 'i2', valor: 99, dia: 12, descricao: 'Assinatura'),
        ],
      );

      final matches = await _ler(ambiente.servico);

      final soDoSistema = matches.where(
        (m) => m.documentTransaction == null && m.systemInstallment != null,
      );
      expect(soDoSistema, hasLength(1));
      expect(soDoSistema.first.systemInstallment?.id, 'i2');
    });

    test('a lista sai ordenada por data', () async {
      final ambiente = _montar(
        extrato: [
          _linha(descricao: 'C', valor: 30, dia: 20),
          _linha(descricao: 'A', valor: 10, dia: 3),
          _linha(descricao: 'B', valor: 20, dia: 11),
        ],
      );

      final matches = await _ler(ambiente.servico);

      expect(
        matches.map((m) => m.documentTransaction!.description),
        ['A', 'B', 'C'],
      );
    });
  });

  group('idempotência da confirmação', () {
    ReconciliationMatch semPar(ReconciliationTransaction linha) =>
        ReconciliationMatch(
          documentTransaction: linha,
          status: ReconciliationMatchStatus.unmatched,
        );

    test('confirmar DUAS vezes não cria dois lançamentos', () async {
      // O risco que este teste existe para reproduzir: `confirmReconciliation`
      // sorteava `Uuid().v4()` a cada chamada e não tinha guarda nenhuma. Um
      // duplo toque no botão, ou um retry de escrita offline, criava o mesmo
      // gasto duas vezes no extrato do usuário.
      final linha = _linha(descricao: 'PADARIA', valor: 48.9, dia: 5);
      final ambiente = _montar();

      for (var tentativa = 0; tentativa < 2; tentativa++) {
        await ambiente.servico.confirmReconciliation(
          selectedAccount: _conta,
          matches: [semPar(linha)],
          uncategorizedLabel: 'Outros',
        );
      }

      expect(ambiente.lancamentos.chamadasDeAddOrder, 2);
      // Duas chamadas, UM documento: a segunda sobrescreveu a primeira.
      expect(ambiente.lancamentos.ordersPorId, hasLength(1));
      expect(ambiente.lancamentos.ordersPorId.keys.single, _idDe(linha));
    });

    test('confirmar DUAS vezes não grava dois resumos (XP em dobro)', () async {
      final linha = _linha(descricao: 'PADARIA', valor: 48.9, dia: 5);
      final ambiente = _montar();

      for (var tentativa = 0; tentativa < 2; tentativa++) {
        await ambiente.servico.confirmReconciliation(
          selectedAccount: _conta,
          matches: [semPar(linha)],
          uncategorizedLabel: 'Outros',
        );
      }

      expect(ambiente.resumos.chamadas, 2);
      // `reconciliations/{id}` é o gatilho de XP no servidor: dois documentos
      // seriam XP duas vezes pela mesma conciliação.
      expect(ambiente.resumos.porId, hasLength(1));
    });

    test('linhas diferentes continuam sendo lançamentos diferentes', () async {
      final ambiente = _montar();

      await ambiente.servico.confirmReconciliation(
        selectedAccount: _conta,
        matches: [
          semPar(_linha(descricao: 'PADARIA', valor: 48.9, dia: 5)),
          semPar(_linha(descricao: 'MERCADO', valor: 250, dia: 6)),
          // Mesma descrição e mesmo valor, outro dia: é outro gasto.
          semPar(_linha(descricao: 'PADARIA', valor: 48.9, dia: 7)),
        ],
        uncategorizedLabel: 'Outros',
      );

      expect(ambiente.lancamentos.ordersPorId, hasLength(3));
    });

    test('DUAS LINHAS IDÊNTICAS no mesmo extrato são dois lançamentos', () async {
      // Dois cafés de R$ 5 no mesmo dia, mesma descrição, mesmo tipo: o
      // extrato traz duas linhas com a MESMA chave de conteúdo. Com o id
      // derivado só do conteúdo, o segundo `set` sobrescrevia o primeiro — o
      // usuário confirmava dois gastos e via um só, enquanto o resumo dizia
      // que tinha criado dois.
      final cafe = _linha(descricao: 'CAFETERIA', valor: 5, dia: 7);
      final ambiente = _montar();

      await ambiente.servico.confirmReconciliation(
        selectedAccount: _conta,
        matches: [semPar(cafe), semPar(cafe)],
        uncategorizedLabel: 'Outros',
      );

      expect(ambiente.lancamentos.chamadasDeAddOrder, 2);
      expect(ambiente.lancamentos.ordersPorId, hasLength(2));
      // E o contador do resumo concorda com o que foi gravado.
      expect(ambiente.resumos.porId.values.single.criados, 2);
    });

    test('reconfirmar o extrato com linhas idênticas continua com dois',
        () async {
      final cafe = _linha(descricao: 'CAFETERIA', valor: 5, dia: 7);
      final ambiente = _montar();

      for (var tentativa = 0; tentativa < 2; tentativa++) {
        await ambiente.servico.confirmReconciliation(
          selectedAccount: _conta,
          matches: [semPar(cafe), semPar(cafe)],
          uncategorizedLabel: 'Outros',
        );
      }

      expect(ambiente.lancamentos.chamadasDeAddOrder, 4);
      // Quatro chamadas, DOIS documentos: a idempotência continua de pé.
      expect(ambiente.lancamentos.ordersPorId, hasLength(2));
    });

    test('os ids das linhas idênticas são estáveis entre execuções', () {
      final cafe = _linha(descricao: 'CAFETERIA', valor: 5, dia: 7);
      final extrato = [semPar(cafe), semPar(cafe), semPar(cafe)];

      final primeira = ReconciliationIds.orderIdsFor('acc-1', extrato);
      final segunda = ReconciliationIds.orderIdsFor('acc-1', extrato);

      expect(primeira, segunda);
      // Três linhas iguais, três ids distintos, na ordem.
      expect(primeira.toSet(), hasLength(3));
    });

    test('marcar uma das linhas idênticas como ignorada não renumera as outras',
        () {
      // A contagem de ocorrência passa por TODAS as linhas de extrato, e não
      // só pelas que viram lançamento: se ela dependesse do status, ignorar a
      // primeira mudaria o id da segunda e o retry duplicaria.
      final cafe = _linha(descricao: 'CAFETERIA', valor: 5, dia: 7);

      final todas = ReconciliationIds.orderIdsFor('acc-1', [
        semPar(cafe),
        semPar(cafe),
      ]);
      final comUmaIgnorada = ReconciliationIds.orderIdsFor('acc-1', [
        ReconciliationMatch(
          documentTransaction: cafe,
          status: ReconciliationMatchStatus.ignored,
        ),
        semPar(cafe),
      ]);

      expect(comUmaIgnorada, todas);
    });

    test('uma linha só do SISTEMA não consome número de ocorrência', () {
      final cafe = _linha(descricao: 'CAFETERIA', valor: 5, dia: 7);

      final ids = ReconciliationIds.orderIdsFor('acc-1', [
        ReconciliationMatch(
          systemInstallment: _parcela(id: 'i1', valor: 99, dia: 2),
        ),
        semPar(cafe),
      ]);

      expect(ids.first, isNull);
      expect(ids.last, _idDe(cafe));
    });

    test('extratos com uma e com duas linhas iguais têm resumos diferentes',
        () {
      final cafe = _linha(descricao: 'CAFETERIA', valor: 5, dia: 7);

      expect(
        ReconciliationIds.summaryIdFor('acc-1', [semPar(cafe)]),
        isNot(
          ReconciliationIds.summaryIdFor('acc-1', [semPar(cafe), semPar(cafe)]),
        ),
      );
    });

    test('a mesma linha em CONTAS diferentes são lançamentos diferentes', () {
      final linha = _linha(descricao: 'PADARIA', valor: 48.9, dia: 5);

      expect(_idDe(linha), isNot(_idDe(linha, conta: 'acc-2')));
    });

    test('a hora inventada pelo parser não muda o id', () {
      // O conversor do extrato normaliza a hora para meio-dia; se o id
      // dependesse dela, uma mudança nessa convenção duplicaria tudo.
      final base = ReconciliationTransaction(
        description: 'PADARIA',
        amount: 48.9,
        date: DateTime(2026, 3, 5, 12),
        type: OrderType.expense,
      );
      final outraHora = base.copyWith(date: DateTime(2026, 3, 5, 23, 59));

      expect(_idDe(base), _idDe(outraHora));
    });

    test('o resumo não depende da ORDEM em que o parser devolveu as linhas',
        () {
      final a = _linha(descricao: 'A', valor: 10, dia: 3);
      final b = _linha(descricao: 'B', valor: 20, dia: 11);

      ReconciliationMatch m(ReconciliationTransaction tx) =>
          ReconciliationMatch(documentTransaction: tx);

      expect(
        ReconciliationIds.summaryIdFor('acc-1', [m(a), m(b)]),
        ReconciliationIds.summaryIdFor('acc-1', [m(b), m(a)]),
      );
    });
  });

  group('o ramo destrutivo: ignorar uma parcela do sistema', () {
    test('"remover" cancela a parcela — e só ela', () async {
      final ambiente = _montar(
        parcelas: [
          _parcela(id: 'i1', valor: 250, dia: 10),
          _parcela(id: 'i2', valor: 99, dia: 12),
        ],
      );

      await ambiente.servico.confirmReconciliation(
        selectedAccount: _conta,
        matches: [
          ReconciliationMatch(
            systemInstallment: _parcela(id: 'i1', valor: 250, dia: 10),
            status: ReconciliationMatchStatus.ignored,
          ),
          ReconciliationMatch(
            systemInstallment: _parcela(id: 'i2', valor: 99, dia: 12),
            status: ReconciliationMatchStatus.matched,
          ),
        ],
        uncategorizedLabel: 'Outros',
      );

      final removidas = ambiente.lancamentos.parcelasAtualizadas
          .where((p) => p.status == InstallmentStatus.removed)
          .map((p) => p.id);
      expect(removidas, ['i1']);
    });

    test('ignorar uma linha do EXTRATO não apaga nada', () async {
      final ambiente = _montar();

      await ambiente.servico.confirmReconciliation(
        selectedAccount: _conta,
        matches: [
          ReconciliationMatch(
            documentTransaction: _linha(
              descricao: 'ESTORNO',
              valor: 90,
              dia: 12,
              tipo: OrderType.income,
            ),
            status: ReconciliationMatchStatus.ignored,
          ),
        ],
        uncategorizedLabel: 'Outros',
      );

      expect(ambiente.lancamentos.parcelasAtualizadas, isEmpty);
      expect(ambiente.lancamentos.ordersPorId, isEmpty);
    });
  });

  group('os contadores do resumo — eles alimentam XP', () {
    test('contam casamentos, criações e o total processado', () async {
      final ambiente = _montar();

      await ambiente.servico.confirmReconciliation(
        selectedAccount: _conta,
        matches: [
          // casado com parcela: conta como confirmado
          ReconciliationMatch(
            documentTransaction: _linha(descricao: 'A', valor: 10, dia: 3),
            systemInstallment: _parcela(id: 'i1', valor: 10, dia: 3),
            status: ReconciliationMatchStatus.matched,
          ),
          // sem par: conta como criado
          ReconciliationMatch(
            documentTransaction: _linha(descricao: 'B', valor: 20, dia: 4),
            status: ReconciliationMatchStatus.unmatched,
          ),
          // ignorado: não conta em nada
          ReconciliationMatch(
            documentTransaction: _linha(descricao: 'C', valor: 30, dia: 5),
            status: ReconciliationMatchStatus.ignored,
          ),
        ],
        uncategorizedLabel: 'Outros',
      );

      final resumo = ambiente.resumos.porId.values.single;
      expect(resumo.confirmados, 1);
      expect(resumo.criados, 1);
      expect(resumo.processados, 2);
    });
  });

  group('categoria do lançamento criado', () {
    test('sem categoria no extrato, usa o rótulo que a TELA mandou', () async {
      final ambiente = _montar();

      await ambiente.servico.confirmReconciliation(
        selectedAccount: _conta,
        matches: [
          ReconciliationMatch(
            documentTransaction: _linha(descricao: 'A', valor: 10, dia: 3),
            status: ReconciliationMatchStatus.unmatched,
          ),
        ],
        // O serviço NÃO escolhe a palavra: ela é gravada no Firestore, e
        // escrevê-la aqui gravaria português no workspace de quem usa o app
        // em inglês.
        uncategorizedLabel: 'Uncategorized',
      );

      expect(ambiente.categorias.criadas.single.name, 'Uncategorized');
    });

    test('categoria existente é reaproveitada, ignorando acento e caixa',
        () async {
      final ambiente = _montar(
        categoriasExistentes: const [
          CategoryModel(
            id: 'cat-alimentacao',
            name: 'Alimentação',
            icon: 'restaurant',
            color: '#FF0000',
          ),
        ],
      );

      await ambiente.servico.confirmReconciliation(
        selectedAccount: _conta,
        matches: [
          ReconciliationMatch(
            documentTransaction: ReconciliationTransaction(
              description: 'RESTAURANTE',
              amount: 55,
              date: DateTime(2026, 3, 8, 12),
              type: OrderType.expense,
              category: const CategoryModel(
                id: 'ia-1',
                name: 'alimentacao',
                icon: 'restaurant',
                color: '#FF0000',
              ),
            ),
            status: ReconciliationMatchStatus.unmatched,
          ),
        ],
        uncategorizedLabel: 'Outros',
      );

      expect(ambiente.categorias.criadas, isEmpty);
      expect(
        ambiente.lancamentos.ordersPorId.values.single.category?.id,
        'cat-alimentacao',
      );
    });
  });
}
