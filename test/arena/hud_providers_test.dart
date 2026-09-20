import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/arena/data/repositories/hud_repository_impl.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/domain/repositories/hud_repository.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

import '../support/journey_fakes.dart';

/// A LEITURA do HUD mensal: o teto de data dos saldos e o join do sumário.
///
/// A conta já tem teste próprio (`hud_calculator_test.dart`). O que este
/// arquivo guarda é o caminho até ela, e em especial o defeito que só
/// aparece neste cofre: as contas de cartão têm documento de saldo PROJETADO
/// até 2036. Quem perguntar "o último documento de saldo" recebe o saldo de
/// daqui a dez anos — e a poção, o ovo e a gota passariam a mostrar um futuro
/// como se fosse hoje.

final DateTime _hoje = DateTime(2026, 9, 20, 10);

AccountModel _investimento(String id, String nome) => AccountModel.investment(
  id: id,
  name: nome,
  icon: 'savings',
  color: '#2E7D32',
  initialBalanceDate: DateTime(2026, 1, 1),
  interestRate: 0,
);

AccountModel _divida(String id, String nome) => AccountModel.debt(
  id: id,
  name: nome,
  icon: 'account_balance',
  color: '#B71C1C',
  initialBalanceDate: DateTime(2026, 1, 1),
  interestRate: 0.02,
);

AccountModel _cartao(String id, String nome, {NextInvoice? fatura}) =>
    AccountModel.creditCard(
      id: id,
      name: nome,
      icon: 'credit_card',
      color: '#8A05BE',
      initialBalanceDate: DateTime(2026, 1, 1),
      limit: 7300,
      dueDay: 10,
      closingDay: 4,
      nextInvoice: fatura,
    );

NextInvoice _fatura(
  double valor, {
  required DateTime fechamento,
  DateTime? vencimento,
}) => NextInvoice(
  dueDate: vencimento ?? DateTime(2026, 10, 10),
  closingDate: fechamento,
  cycleStart: DateTime(2026, 9, 4),
  cycleEnd: DateTime(2026, 10, 4),
  amount: valor,
  orderId: 'invoice-x',
  installmentId: 'i-1',
);

/// Repositório de conta com saldos escritos DIA A DIA, como no Firestore —
/// inclusive os do futuro.
class _ContasFake implements IAccountRepository {
  _ContasFake(this.accounts, this.balances);

  final List<AccountModel> accounts;
  final Map<String, Map<String, double>> balances;

  /// As datas que o app pediu. É o que prova QUAL dia ele consultou.
  final List<String> asked = <String>[];

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(
    type == null ? accounts : accounts.where((a) => a.type == type).toList(),
  );

  @override
  Stream<AccountBalanceModel?> getLatestAccountBalanceBeforeDate(
    String workspaceId,
    String accountId,
    DateTime date,
  ) {
    final key = date.toIso8601String().split('T')[0];
    asked.add(key);

    final days =
        (balances[accountId] ?? const <String, double>{}).keys
            .where((day) => day.compareTo(key) <= 0)
            .toList()
          ..sort();

    if (days.isEmpty) return Stream.value(null);

    return Stream.value(
      AccountBalanceModel(
        id: days.last,
        balance: balances[accountId]![days.last]!,
        updatedAt: _hoje,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no HUD');
}

class _SumarioFake implements IPeriodSummaryRepository {
  _SumarioFake(this.month);

  final PeriodSummaryModel? month;

  final List<String> asked = <String>[];

  @override
  Stream<PeriodSummaryModel?> watchMonth(
    String workspaceId,
    int year,
    int month,
  ) {
    asked.add('$year-${month.toString().padLeft(2, '0')}');
    return Stream.value(this.month);
  }

  @override
  Stream<PeriodSummaryModel?> watchWeek(
    String workspaceId,
    int year,
    int week,
  ) => Stream.value(null);
}

class _CategoriasFake implements ICategoryRepository {
  _CategoriasFake(this.categories);

  final List<CategoryModel> categories;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(categories);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no HUD');
}

class _LancamentosFake implements IFinanceRepository {
  _LancamentosFake(this.pending);

  final List<InstallmentModel> pending;

  @override
  Stream<List<InstallmentModel>> watchInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    dynamic type,
    InstallmentStatus? status,
  }) => Stream.value(pending);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no HUD');
}

class _HudFake implements IHudRepository {
  _HudFake({this.income, this.reports = const []});

  final ExpectedIncome? income;
  final List<HudMonthlyReport> reports;

  int? limitPedido;

  @override
  Stream<ExpectedIncome?> watchExpectedIncome(String workspaceId) =>
      Stream.value(income);

  @override
  Stream<List<HudMonthlyReport>> watchMonthlyReports(
    String workspaceId, {
    int limit = 6,
  }) {
    limitPedido = limit;
    return Stream.value(reports);
  }
}

ProviderContainer _container({
  required _ContasFake contas,
  _SumarioFake? sumario,
  _CategoriasFake? categorias,
  _LancamentosFake? lancamentos,
  _HudFake? hud,
}) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _hoje),
      WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-1'),
      AccountDomainProviders.repository.overrideWithValue(contas),
      WorkspaceDomainProviders.repository.overrideWithValue(
        FakeWorkspaceRepository(),
      ),
      PeriodSummaryDomainProviders.repository.overrideWithValue(
        sumario ?? _SumarioFake(null),
      ),
      CategoryDomainProviders.repository.overrideWithValue(
        categorias ?? _CategoriasFake(const []),
      ),
      FinanceDomainProviders.repository.overrideWithValue(
        lancamentos ?? _LancamentosFake(const []),
      ),
      HudDomainProviders.repository.overrideWithValue(hud ?? _HudFake()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<HudState> _estado(ProviderContainer container) async {
  final sub = container.listen(HudViewProviders.state, (_, _) {});
  addTearDown(sub.close);

  for (var i = 0; i < 40; i++) {
    final value = container.read(HudViewProviders.state);
    if (value.hasError) fail('o HUD falhou: ${value.error}');
    final data = value.valueOrNull;
    if (data != null) return data;
    await Future<void>.delayed(Duration.zero);
  }

  fail('o HUD não ficou pronto');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('o teto de data dos saldos', () {
    test('o saldo lido é o de HOJE, e não o documento mais recente', () async {
      // O retrato real: a conta tem documento até 2036 porque há lançamento
      // agendado. "O último" seria R$ 99.999,00.
      final contas = _ContasFake(
        [_investimento('inv', 'Cofrinho Disney')],
        {
          'inv': {'2026-08-13': 263.41, '2036-01-01': 99999},
        },
      );

      final hud = await _estado(_container(contas: contas));

      expect(hud.potion.total, Money.fromDouble(263.41));
      expect(contas.asked, contains('2026-09-20'));

      // O caminho "último documento, sem teto" deixou de existir em
      // `IAccountRepository`: hoje quem tentasse usá-lo não compila. Este
      // teste guarda a outra metade — que o dia pedido é o de HOJE.
    });

    test('a dívida vem do saldo de hoje, em módulo', () async {
      final contas = _ContasFake(
        [_divida('itau', 'Empréstimo Itaú')],
        {
          'itau': {'2026-08-24': -7623.68, '2036-05-01': -100},
        },
      );

      final hud = await _estado(_container(contas: contas));

      expect(hud.drop.total, Money.fromDouble(7623.68));
      expect(hud.drop.isBlinking, isTrue);
    });
  });

  group('o ovo lê nextInvoice', () {
    test('cartão sem resumo do servidor fica de fora', () async {
      // Somar zero por ele encolheria o ovo com uma certeza que não existe.
      final contas = _ContasFake([
        _cartao(
          'a',
          'Com resumo',
          fatura: _fatura(2717.10, fechamento: DateTime(2026, 10, 4)),
        ),
        _cartao('b', 'Sem resumo'),
      ], const {});

      final hud = await _estado(_container(contas: contas));

      expect(hud.egg.invoices.map((i) => i.name), ['Com resumo']);
      expect(hud.egg.total, Money.fromDouble(2717.10));
    });

    test('ciclo ainda aberto é marcado como tal', () async {
      final aberto = _ContasFake([
        _cartao(
          'a',
          'C6',
          fatura: _fatura(2406, fechamento: DateTime(2026, 10, 4)),
        ),
      ], const {});
      final fechado = _ContasFake([
        _cartao(
          'a',
          'Nubank',
          fatura: _fatura(8300.55, fechamento: DateTime(2026, 9, 10)),
        ),
      ], const {});

      expect(
        (await _estado(
          _container(contas: aberto),
        )).egg.invoices.single.isOpenCycle,
        isTrue,
      );
      expect(
        (await _estado(
          _container(contas: fechado),
        )).egg.invoices.single.isOpenCycle,
        isFalse,
      );
    });
  });

  group('a fatura vencida', () {
    test('a Nubank de 17/09, lida no dia 20, venceu há três dias', () async {
      // Ela CONTINUA no ovo: o contrato é Σ nextInvoice, e uma fatura
      // vencida e não paga é a mais devida de todas. O que ela ganha é a
      // marca, e a marca é uma afirmação sobre HOJE — por isso ela sai do
      // relógio do app, e não de um campo do documento.
      final contas = _ContasFake([
        _cartao(
          'nubank2',
          'Cartão Nubank',
          fatura: _fatura(
            8300.55,
            fechamento: DateTime(2026, 9, 10),
            vencimento: DateTime(2026, 9, 17),
          ),
        ),
      ], const {});

      final hud = await _estado(_container(contas: contas));
      final fatura = hud.egg.invoices.single;

      expect(fatura.overdueDays, 3);
      expect(fatura.isOverdue, isTrue);
      expect(hud.egg.total, Money.fromDouble(8300.55));
    });

    test('a que vence HOJE ainda não venceu', () async {
      // O usuário tem o dia inteiro. Marcar como vencida a fatura que vence
      // hoje seria o app cobrando antes do banco.
      final contas = _ContasFake([
        _cartao(
          'c6',
          'Cartão C6',
          fatura: _fatura(
            2406,
            fechamento: DateTime(2026, 9, 10),
            vencimento: DateTime(2026, 9, 20),
          ),
        ),
      ], const {});

      final hud = await _estado(_container(contas: contas));

      expect(hud.egg.invoices.single.overdueDays, 0);
      expect(hud.egg.invoices.single.isOverdue, isFalse);
    });

    test('a que vence adiante não tem marca nenhuma', () async {
      final contas = _ContasFake([
        _cartao(
          'inter',
          'Cartão Inter',
          fatura: _fatura(3634.86, fechamento: DateTime(2026, 10, 4)),
        ),
      ], const {});

      final hud = await _estado(_container(contas: contas));

      expect(hud.egg.invoices.single.overdueDays, 0);
    });
  });

  group('a vila lê o sumário do mês corrente', () {
    test('pede o mês de HOJE e cruza com as categorias', () async {
      final sumario = _SumarioFake(
        PeriodSummaryModel.month(
          year: 2026,
          month: 9,
          lastUpdate: _hoje,
          categories: const {
            'mercado': PeriodSummaryCategoryModel(
              generalPlannedAmount: 3500,
              actualAmount: 1158.20,
            ),
            'assinaturas': PeriodSummaryCategoryModel(actualAmount: 495.25),
            'salario': PeriodSummaryCategoryModel(
              specificPlannedAmount: 17000,
              actualAmount: 17000,
            ),
            'fantasma': PeriodSummaryCategoryModel(generalPlannedAmount: 3800),
          },
        ),
      );

      final categorias = _CategoriasFake([
        const CategoryModel(
          id: 'mercado',
          name: 'Supermercado',
          icon: 'shopping_cart',
          color: '#FF5722',
        ),
        const CategoryModel(
          id: 'assinaturas',
          name: 'Assinaturas',
          icon: 'subscriptions',
          color: '#3F51B5',
        ),
        const CategoryModel(
          id: 'salario',
          name: 'Salário',
          icon: 'payments',
          color: '#4CAF50',
          type: CategoryType.income,
        ),
      ]);

      final hud = await _estado(
        _container(
          contas: _ContasFake(const [], const {}),
          sumario: sumario,
          categorias: categorias,
        ),
      );

      // O conjunto, e não a lista: o provider reassina quando as categorias
      // chegam, e o que importa é que ele nunca pediu outro mês.
      expect(sumario.asked.toSet(), {'2026-09'});
      expect(hud.monthKey, '2026-09');
      expect(hud.village.villagers.map((v) => v.name), ['Supermercado']);
      expect(hud.village.unprotected.map((u) => u.name), ['Assinaturas']);
    });

    test('id de categoria que o app não conhece não vira aldeão', () async {
      // `fantasma` tem R$ 3.800 de orçamento no sumário e nenhum documento de
      // categoria — é uma categoria apagada de vez. Sem o descarte, ela
      // entraria como um aldeão sem nome e inflaria o denominador do anel em
      // R$ 3.800. É a mesma peneira do servidor e a da Visão Geral.
      final hud = await _estado(
        _container(
          contas: _ContasFake(const [], const {}),
          sumario: _SumarioFake(
            PeriodSummaryModel.month(
              year: 2026,
              month: 9,
              lastUpdate: _hoje,
              categories: const {
                'fantasma': PeriodSummaryCategoryModel(
                  generalPlannedAmount: 3800,
                ),
              },
            ),
          ),
          categorias: _CategoriasFake(const []),
        ),
      );

      expect(hud.village.villagers, isEmpty);
      expect(hud.village.plannedTotal, Money.zero);
    });
  });

  group('a receita prevista vem do servidor', () {
    test('ausente é "ainda não sei", e nenhuma razão tem classe', () async {
      final hud = await _estado(
        _container(
          contas: _ContasFake(
            [_investimento('inv', 'Cofrinho')],
            {
              'inv': {'2026-09-01': 5000},
            },
          ),
          hud: _HudFake(),
        ),
      );

      expect(hud.hasIncome, isFalse);
      expect(hud.potion.ratio.tier, isNull);
      expect(hud.potion.total, Money.fromDouble(5000));
    });

    test('presente, ela é o denominador das três razões', () async {
      final hud = await _estado(
        _container(
          contas: _ContasFake(
            [_investimento('inv', 'Cofrinho')],
            {
              'inv': {'2026-09-01': 9275},
            },
          ),
          hud: _HudFake(
            income: ExpectedIncome(
              monthKey: '2026-09',
              amount: Money.fromCents(1855000),
              source: ExpectedIncomeSource.planned,
            ),
          ),
        ),
      );

      expect(hud.potion.ratio.tier, HudTier.semi);
      expect(hud.income!.source, ExpectedIncomeSource.planned);
    });

    test('receita de OUTRO mês não vale como denominador', () async {
      // O cron do dia 1 pode não ter rodado, ou o app pode estar aberto
      // desde ontem e ter virado o mês na mão do usuário. O documento traz
      // `monthKey` exatamente para isto ser detectável.
      final hud = await _estado(
        _container(
          contas: _ContasFake(
            [_investimento('inv', 'Cofrinho')],
            {
              'inv': {'2026-09-01': 9275},
            },
          ),
          hud: _HudFake(
            income: ExpectedIncome(
              monthKey: '2026-08',
              amount: Money.fromCents(1855000),
              source: ExpectedIncomeSource.planned,
            ),
          ),
        ),
      );

      expect(hud.monthKey, '2026-09');
      expect(hud.hasIncome, isFalse);
      expect(hud.potion.ratio.tier, isNull);
      expect(hud.potion.total, Money.fromDouble(9275));
    });

    test('o histórico pede só os últimos meses', () async {
      final fake = _HudFake(
        reports: const [
          HudMonthlyReport(
            monthKey: '2026-08',
            villagersPlanned: 17,
            villagersAlive: 9,
            villageAlive: false,
            xpAwarded: 135,
          ),
        ],
      );

      final hud = await _estado(
        _container(contas: _ContasFake(const [], const {}), hud: fake),
      );

      expect(fake.limitPedido, hudHistoryMonths);
      expect(hud.village.history.single.xpAwarded, 135);
    });
  });

  group('a leitura dos dois documentos do servidor', () {
    test('expectedIncome ausente vira null, não zero', () {
      expect(parseExpectedIncome(null), isNull);
      expect(parseExpectedIncome(<String, Object?>{}), isNull);
    });

    test('expectedIncome sem cents não é previsão nenhuma', () {
      expect(
        parseExpectedIncome(<String, Object?>{'monthKey': '2026-09'}),
        isNull,
      );
    });

    test('expectedIncome negativo é recusado', () {
      // Um denominador negativo inverteria o sinal das três razões.
      expect(
        parseExpectedIncome(<String, Object?>{
          'monthKey': '2026-09',
          'cents': -100,
        }),
        isNull,
      );
    });

    test('expectedIncome completo, com a origem', () {
      final income = parseExpectedIncome(<String, Object?>{
        'monthKey': '2026-09',
        'cents': 1855000,
        'source': 'average',
        'updatedAt': '2026-09-20T08:17:31.572Z',
      });

      expect(income!.amount.cents, 1855000);
      expect(income.source, ExpectedIncomeSource.average);
      expect(income.updatedAt, isNotNull);
    });

    test('origem desconhecida cai em "planejado"', () {
      final income = parseExpectedIncome(<String, Object?>{
        'monthKey': '2026-09',
        'cents': 100,
        'source': 'chute',
      });

      expect(income!.source, ExpectedIncomeSource.planned);
    });

    test('o retrato do mês, com o id valendo de monthKey quando falta', () {
      final report = parseMonthlyReport('2026-08', <String, Object?>{
        'villagersPlanned': 17,
        'villagersAlive': 9,
        'villageAlive': true,
        'xpAwarded': 135,
      });

      expect(report!.monthKey, '2026-08');
      expect(report.villagersAlive, 9);
      expect(report.villageAlive, isTrue);
    });

    test('retrato sem contagem não conta nada: fica de fora', () {
      expect(parseMonthlyReport('2026-08', <String, Object?>{}), isNull);
      expect(parseMonthlyReport('2026-08', null), isNull);
    });
  });
}
