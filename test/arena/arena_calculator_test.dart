import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/domain/services/arena_calculator.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

/// A conta da Arena é a única parte da POC que precisa estar CERTA.
///
/// O resto — pose, tremor, partícula — se confere olhando a tela. Um HP que
/// diverge da soma dos compromissos, não: ele parece plausível e mente.
///
/// A mecânica que estes testes guardam:
///
/// - o monstro é feito do que **sai das contas líquidas** na semana, mais o
///   atraso. Não é "toda parcela de despesa": compra no cartão não move o
///   caixa, e incluí-la fazia "pagar custa vida" virar mentira;
/// - os heróis têm o SALDO como vida, medido do domingo até agora. HP máximo
///   é o saldo do começo da semana; HP atual é o de agora;
/// - pagar um compromisso tira vida dos DOIS: do monstro porque a dívida
///   some, dos heróis porque o dinheiro sai. É o custo do golpe.

const String _week = '2026-W38';

/// Domingo da semana 38 de 2026, ao meio-dia (a hora que o app usa para
/// vencimento).
final DateTime _sunday = DateTime(2026, 9, 20, 12);

/// Quarta-feira: o "hoje" padrão dos testes — quarto dia da semana.
final DateTime _wednesday = DateTime(2026, 9, 23, 10);

InstallmentModel _expense({
  required String id,
  required double amount,
  int dayOffset = 0,
  InstallmentStatus status = InstallmentStatus.pending,
  double? paidAmount,
  DateTime? paidDate,
}) => InstallmentModel(
  id: id,
  orderId: 'order-$id',
  amount: amount,
  description: id,
  dueDate: _sunday.add(Duration(days: dayOffset)),
  paidAmount: paidAmount,
  paidDate: paidDate,
  status: status,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
  accounts: const {'corrente': AccountImpact.debt},
);

InstallmentModel _income({
  required String id,
  required double amount,
  InstallmentStatus status = InstallmentStatus.paid,
}) => InstallmentModel(
  id: id,
  orderId: 'order-$id',
  amount: amount,
  description: id,
  dueDate: _sunday.add(const Duration(days: 1)),
  paidDate: _sunday.add(const Duration(days: 1)),
  status: status,
  type: OrderType.income,
  installmentType: InstallmentType.single,
  accounts: const {'corrente': AccountImpact.credit},
);

/// O retrato real do cofre do dono: uma corrente, um investimento, um cartão
/// e um empréstimo.
const Map<String, AccountType> _contas = <String, AccountType>{
  'corrente': AccountType.checking,
  'investimento': AccountType.investment,
  'cartao': AccountType.creditCard,
  'emprestimo': AccountType.debt,
};

/// Uma parcela de despesa saindo de [from].
InstallmentModel _expenseFrom(
  String from, {
  required String id,
  required double amount,
  int dayOffset = 0,
  InstallmentStatus status = InstallmentStatus.pending,
  DateTime? paidDate,
}) => InstallmentModel(
  id: id,
  orderId: 'order-$id',
  amount: amount,
  description: id,
  dueDate: _sunday.add(Duration(days: dayOffset)),
  paidDate: paidDate,
  status: status,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
  accounts: {from: AccountImpact.debt},
);

/// Uma transferência de [from] para [to] — é assim que o app registra o
/// pagamento de fatura e a parcela de empréstimo.
InstallmentModel _transfer({
  required String id,
  required String from,
  required String to,
  required double amount,
  int dayOffset = 0,
  InstallmentStatus status = InstallmentStatus.pending,
}) => InstallmentModel(
  id: id,
  orderId: 'order-$id',
  amount: amount,
  description: id,
  dueDate: _sunday.add(Duration(days: dayOffset)),
  status: status,
  type: OrderType.transfer,
  installmentType: InstallmentType.single,
  accounts: {from: AccountImpact.debt, to: AccountImpact.credit},
);

/// Uma fatura EM ABERTO, do jeito que o servidor a grava.
///
/// `accounts` só com o lado de crédito do cartão: a conta que vai pagar não
/// foi escolhida ainda, e por isso `accountIdSource` é nulo.
InstallmentModel _pendingInvoice({
  required String id,
  required double amount,
  int dayOffset = 0,
  String card = 'cartao',
}) => InstallmentModel(
  id: id,
  orderId: 'order-$id',
  amount: amount,
  description: 'Fatura',
  dueDate: _sunday.add(Duration(days: dayOffset)),
  status: InstallmentStatus.pending,
  type: OrderType.transfer,
  installmentType: InstallmentType.single,
  isInvoice: true,
  accounts: {card: AccountImpact.credit},
);

ArenaAccountReading _account(
  String id, {
  String? name,
  double initial = 0,
  double current = 0,
}) => ArenaAccountReading(
  accountId: id,
  name: name ?? id,
  initial: initial,
  current: current,
);

UserModel _member(String id, {String? name, String email = ''}) => UserModel(
  id: id,
  email: email.isEmpty ? '$id@funances.test' : email,
  displayName: name,
  createdAt: _sunday,
);

ArenaInputs _inputs({
  List<ArenaAccountReading> accounts = const [],
  List<InstallmentModel> week = const [],
  List<InstallmentModel> overdue = const [],
  List<UserModel> members = const [],
  DateTime? today,
  double weeklyXp = 0,
  Map<String, AccountType> types = _contas,
}) => ArenaInputs(
  weekId: _week,
  today: today ?? _wednesday,
  accounts: accounts,
  weekInstallments: week,
  overdueInstallments: overdue,
  members: members,
  accountTypes: types,
  weeklyXp: weeklyXp,
);

void main() {
  group('HP do monstro: só compromisso agendado', () {
    test('nasce da soma das parcelas de despesa da semana', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'aluguel', amount: 1200),
            _expense(id: 'luz', amount: 180, dayOffset: 3),
          ],
        ),
      );

      expect(state.monsterMaxHp, 1380);
      expect(state.monsterHp, 1380);
      expect(state.monsterHpRatio, 1);
    });

    test('orçamento de categoria NÃO entra: o monstro só conhece dívida', () {
      // A POC 1 somava o rateio de `period_summaries` ao HP. O mesmo gasto
      // aparecia no monstro e na faixa de comprometido do herói, e a barra
      // andava duas vezes pelo mesmo real. A calculadora nova nem recebe o
      // resumo — não há como a dupla contagem voltar por descuido.
      final state = ArenaCalculator.from(
        _inputs(week: [_expense(id: 'aluguel', amount: 1200)]),
      );

      expect(state.monsterMaxHp, 1200);
    });

    test('pagar um compromisso tira exatamente o valor dele', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'aluguel',
              amount: 1200,
              status: InstallmentStatus.paid,
              paidDate: _sunday.add(const Duration(days: 1)),
            ),
            _expense(id: 'luz', amount: 180, dayOffset: 3),
          ],
        ),
      );

      expect(state.monsterMaxHp, 1380, reason: 'o pago continua no inicial');
      expect(state.monsterHp, 180);
      expect(state.paidSoFar, 1200);
    });

    test('pagar a mais não ENGORDA o monstro', () {
      // O inicial é o PLANO — o que a semana se propôs a pagar. Uma conta de
      // R\$ 180 quitada por R\$ 183,45 não fazia a semana dever R\$ 183,45: o
      // que ela devia continua sendo R\$ 180, e os R\$ 3,45 a mais são um
      // detalhe da linha.
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'luz',
              amount: 180,
              paidAmount: 183.45,
              status: InstallmentStatus.paid,
              paidDate: _sunday.add(const Duration(days: 1)),
            ),
          ],
        ),
      );

      expect(state.monsterMaxHp, 180);
      expect(state.monsterHp, 0);
      expect(state.isDefeated, isTrue);
      expect(state.commitments.single.overpaid, closeTo(3.45, 0.001));
    });

    test('receita não alimenta o monstro', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _income(id: 'salario', amount: 6000),
            _expense(id: 'luz', amount: 180),
          ],
        ),
      );

      expect(state.monsterMaxHp, 180);
    });

    test('transferência entre contas líquidas não é compromisso', () {
      // Tirar da corrente e pôr no investimento não é dívida paga: o dinheiro
      // continua no caixa, e a soma das contas líquidas nem muda.
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _transfer(
              id: 'aporte',
              from: 'corrente',
              to: 'investimento',
              amount: 900,
              status: InstallmentStatus.paid,
            ),
          ],
        ),
      );

      expect(state.monsterMaxHp, 0);
      expect(state.healedThisWeek, 0);
    });

    test('a soma é em centavos: doze parcelas de 0,10 dão 1,20 exato', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            for (var i = 0; i < 12; i++) _expense(id: 'p$i', amount: 0.10),
          ],
        ),
      );

      expect(state.monsterMaxHp, 1.20);
    });

    test('semana sem compromisso nenhum não conta como vitória', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('c', initial: 900, current: 900)]),
      );

      expect(state.monsterMaxHp, 0);
      expect(state.isDefeated, isFalse);
    });
  });

  group('o que SAI DO CAIXA — o retrato real do cofre', () {
    /// A semana do cofre do dono, com as contas de verdade.
    ///
    /// Quatro compras no cartão, a fatura ABERTA, a parcela do empréstimo e
    /// um débito automático. Na rodada 1 as sete linhas entravam no monstro e
    /// a barra dizia um número que o caixa não ia pagar; aqui só as três que
    /// tiram dinheiro da conta entram.
    ///
    /// A fatura é escrita como o SERVIDOR a escreve: `accounts` só com o lado
    /// de crédito do cartão. Ver `_pendingInvoice`.
    List<InstallmentModel> retratoReal() => [
      _expenseFrom('cartao', id: 'mercado', amount: 412.90, dayOffset: 1),
      _expenseFrom('cartao', id: 'farmacia', amount: 87.40, dayOffset: 2),
      _expenseFrom('cartao', id: 'aplicativo', amount: 39.90, dayOffset: 3),
      _expenseFrom('cartao', id: 'restaurante', amount: 156.00, dayOffset: 3),
      _pendingInvoice(id: 'fatura', amount: 8300, dayOffset: 4),
      _transfer(
        id: 'emprestimo',
        from: 'corrente',
        to: 'emprestimo',
        amount: 3811,
        dayOffset: 5,
      ),
      _expenseFrom('corrente', id: 'Segurança C6', amount: 29.90, dayOffset: 2),
    ];

    test('compra NO cartão fica de fora: ela não move o caixa hoje', () {
      final state = ArenaCalculator.from(_inputs(week: retratoReal()));

      final ids = state.commitments.map((c) => c.installment.id).toSet();

      expect(ids, isNot(contains('mercado')));
      expect(ids, isNot(contains('farmacia')));
      expect(ids, isNot(contains('aplicativo')));
      expect(ids, isNot(contains('restaurante')));
    });

    test('a fatura e o empréstimo SÃO os golpes da semana', () {
      final state = ArenaCalculator.from(_inputs(week: retratoReal()));

      final ids = state.commitments.map((c) => c.installment.id).toList();

      expect(ids, containsAll(<String>['fatura', 'emprestimo']));
      // 8.300 + 3.811 + 29,90 — e não os 12.827,20 das sete linhas.
      expect(state.monsterMaxHp, 12140.90);
    });

    test('débito automático em conta corrente entra', () {
      final state = ArenaCalculator.from(_inputs(week: retratoReal()));

      expect(
        state.commitments.map((c) => c.installment.id),
        contains('Segurança C6'),
      );
    });

    test('a fatura ABERTA entra, mesmo sem conta de saída', () {
      // O defeito da rodada 2, e ele era estrutural: o servidor cria a order
      // da fatura com `accounts: {cartão: "credit"}` e nada mais. A conta que
      // vai pagar só entra na quitação.
      //
      // Com a leitura antiga ("sem conta de saída, não é compromisso"), o
      // MAIOR compromisso da semana ficava fora e a barra mostrava um terço
      // da dívida real.
      final fatura = _pendingInvoice(id: 'fatura', amount: 8300.55);

      expect(fatura.accountIdSource, isNull, reason: 'é a forma real');
      expect(fatura.accounts, {'cartao': AccountImpact.credit});

      final state = ArenaCalculator.from(_inputs(week: [fatura]));

      expect(state.monsterMaxHp, 8300.55);
      expect(state.monsterHp, 8300.55);
    });

    test('a fatura PAGA vale o mesmo, agora pela conta que a pagou', () {
      // Na quitação o documento ganha o lado debt com a conta pagadora. Os
      // dois caminhos têm de dar o mesmo número — senão a barra pularia no
      // instante do pagamento.
      final paga = _transfer(
        id: 'fatura',
        from: 'corrente',
        to: 'cartao',
        amount: 8300.55,
        status: InstallmentStatus.paid,
      );

      final state = ArenaCalculator.from(_inputs(week: [paga]));

      expect(state.monsterMaxHp, 8300.55);
      expect(state.monsterHp, 0);
    });

    test('a fatura atrasada enfurece o monstro', () {
      // A fatura do dono venceu antes do domingo e continua pendente.
      final state = ArenaCalculator.from(
        _inputs(
          overdue: [
            _pendingInvoice(id: 'fatura', amount: 8300.55, dayOffset: -3),
          ],
          week: [_expense(id: 'c6', amount: 10, dayOffset: 4)],
        ),
      );

      expect(state.overdueAmount, 8300.55);
      expect(state.isEnraged, isTrue);
      expect(state.monsterMaxHp, 8310.55);
    });

    test('compromisso pendente de DÍVIDA sem origem também entra', () {
      // Hoje só a fatura nasce sem conta de saída. A regra é escrita pela
      // FORMA — sem origem, destino de dívida — e não por `isInvoice`, para o
      // dia em que o servidor criar a parcela de um empréstimo do mesmo
      // jeito.
      final semOrigem = InstallmentModel(
        id: 'parcela-emprestimo',
        orderId: 'order-parcela',
        amount: 3811.78,
        description: 'Parcela do empréstimo',
        dueDate: _sunday.add(const Duration(days: 4)),
        status: InstallmentStatus.pending,
        type: OrderType.transfer,
        installmentType: InstallmentType.single,
        accounts: const {'emprestimo': AccountImpact.credit},
      );

      expect(
        ArenaCalculator.from(_inputs(week: [semOrigem])).monsterMaxHp,
        3811.78,
      );
    });

    test('sem origem E sem destino de dívida continua fora', () {
      // A abertura para a fatura não pode virar uma porta para qualquer
      // documento malformado: um lançamento com o lado de crédito numa conta
      // CORRENTE é uma receita disfarçada, não um compromisso.
      final estranho = InstallmentModel(
        id: 'estranho',
        orderId: 'order-estranho',
        amount: 500,
        description: 'estranho',
        dueDate: _sunday,
        status: InstallmentStatus.pending,
        type: OrderType.transfer,
        installmentType: InstallmentType.single,
        accounts: const {'corrente': AccountImpact.credit},
      );

      expect(ArenaCalculator.from(_inputs(week: [estranho])).monsterMaxHp, 0);
    });

    test('pagar a fatura custa vida: o golpe tira dos DOIS', () {
      // É a propriedade que a rodada 1 perdeu. Com compra de cartão no
      // monstro, quitar uma delas derrubava a barra do bicho sem mexer no
      // caixa — e a leitura "pagar custa vida" virava mentira.
      final antes = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 20000, current: 20000)],
          week: retratoReal(),
        ),
      );

      final depois = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 20000, current: 11700)],
          week: [
            for (final i in retratoReal())
              if (i.id == 'fatura')
                // Quitada: o documento ganha o lado debt com a conta que
                // pagou.
                _transfer(
                  id: 'fatura',
                  from: 'corrente',
                  to: 'cartao',
                  amount: 8300,
                  dayOffset: 4,
                  status: InstallmentStatus.paid,
                )
              else
                i,
          ],
        ),
      );

      expect(antes.monsterHp - depois.monsterHp, 8300);
      expect(antes.currentBalance - depois.currentBalance, 8300);
    });

    test('conta de origem desconhecida não entra: o app não adivinha', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [_expenseFrom('conta-que-nao-existe', id: 'x', amount: 100)],
        ),
      );

      expect(state.monsterMaxHp, 0);
    });

    test('parcela sem conta nenhuma não entra', () {
      final semConta = InstallmentModel(
        id: 'orfa',
        orderId: 'order-orfa',
        amount: 100,
        description: 'orfa',
        dueDate: _sunday,
        status: InstallmentStatus.pending,
        type: OrderType.expense,
        installmentType: InstallmentType.single,
      );

      expect(ArenaCalculator.from(_inputs(week: [semConta])).monsterMaxHp, 0);
    });
  });

  group('quitação PARCIAL', () {
    /// Uma fatura com pagamento parcial, do jeito que a base a guarda.
    ///
    /// Numa fatura o `amount` SOBREVIVE à quitação — ele é o que o cartão
    /// cobrou. É a diferença que fazia `referenceAmount` (`paidAmount ??
    /// amount`) mentir: ele devolvia o valor PAGO como se fosse o plano.
    InstallmentModel invoicePaid({
      required String id,
      required double amount,
      required double paid,
      int dayOffset = 0,
    }) => InstallmentModel(
      id: id,
      orderId: 'order-$id',
      amount: amount,
      paidAmount: paid,
      paidDate: _sunday.add(Duration(days: dayOffset)),
      description: 'Fatura $id',
      dueDate: _sunday.add(Duration(days: dayOffset)),
      status: InstallmentStatus.paid,
      type: OrderType.transfer,
      installmentType: InstallmentType.single,
      isInvoice: true,
      accounts: const {
        'corrente': AccountImpact.debt,
        'cartao': AccountImpact.credit,
      },
    );

    test('a fatura paga pela metade NÃO derruba o monstro', () {
      // O caso que reprovou a rodada 3: Cartão Inter, R\$ 12.130,09 cobrados,
      // R\$ 1.000 pagos. Com `referenceAmount`, o inicial virava R\$ 1.000, o
      // monstro perdia onze mil de vida e COMEMORAVA.
      final state = ArenaCalculator.from(
        _inputs(week: [invoicePaid(id: 'inter', amount: 12130.09, paid: 1000)]),
      );

      expect(state.monsterMaxHp, 12130.09);
      expect(state.monsterHp, 11130.09);
      expect(state.isDefeated, isFalse, reason: 'ninguém venceu nada aqui');

      final linha = state.commitments.single;
      expect(linha.planned, 12130.09);
      expect(linha.struck, 1000);
      expect(linha.remaining, 11130.09);
      expect(linha.isPartial, isTrue);
      expect(linha.isStruck, isFalse);
    });

    test('os cinco pagamentos parciais da base, um a um', () {
      const casos = <({double cobrado, double pago, double falta})>[
        (cobrado: 12130.09, pago: 1000, falta: 11130.09),
        (cobrado: 7208.17, pago: 3710, falta: 3498.17),
        (cobrado: 8075.61, pago: 7521.50, falta: 554.11),
        // Pagou a MAIS: o monstro cai até o zero e não além.
        (cobrado: 286.21, pago: 296.61, falta: 0),
        (cobrado: 4687.77, pago: 4687.82, falta: 0),
      ];

      for (final caso in casos) {
        final state = ArenaCalculator.from(
          _inputs(
            week: [invoicePaid(id: 'f', amount: caso.cobrado, paid: caso.pago)],
          ),
        );

        expect(
          state.monsterMaxHp,
          caso.cobrado,
          reason: 'o inicial é o PLANO, não o que foi pago',
        );
        expect(state.monsterHp, caso.falta, reason: '${caso.cobrado}');
      }
    });

    test('pagar a mais não derruba além do compromisso', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            invoicePaid(id: 'f1', amount: 286.21, paid: 296.61),
            _expense(id: 'luz', amount: 180, dayOffset: 2),
          ],
        ),
      );

      // Os R\$ 10,40 a mais NÃO abatem a conta de luz.
      expect(state.monsterMaxHp, 466.21);
      expect(state.monsterHp, 180);

      final fatura = state.commitments.firstWhere(
        (c) => c.installment.id == 'f1',
      );
      expect(fatura.overpaid, closeTo(10.40, 0.001));
      expect(fatura.isStruck, isTrue);
      expect(fatura.isPartial, isFalse);
    });

    test('parcela COMUM quitada continua valendo o que foi pago', () {
      // Aqui o app zera o `amount` e move o valor para o `paidAmount`. Sem o
      // `referenceAmount` como saída, o plano viraria zero e a linha sumiria
      // da barra.
      final quitada = InstallmentModel(
        id: 'luz',
        orderId: 'order-luz',
        amount: 0,
        paidAmount: 183.45,
        paidDate: _sunday.add(const Duration(days: 1)),
        description: 'Luz',
        dueDate: _sunday.add(const Duration(days: 1)),
        status: InstallmentStatus.paid,
        type: OrderType.expense,
        installmentType: InstallmentType.single,
        accounts: const {'corrente': AccountImpact.debt},
      );

      final state = ArenaCalculator.from(_inputs(week: [quitada]));

      expect(state.monsterMaxHp, 183.45);
      expect(state.monsterHp, 0);
      expect(state.isDefeated, isTrue);
      expect(state.commitments.single.isStruck, isTrue);
    });

    test('a vitória exige remaining ZERO, e não "tem pagamento"', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            invoicePaid(id: 'inter', amount: 12130.09, paid: 1000),
            _expense(
              id: 'luz',
              amount: 180,
              status: InstallmentStatus.paid,
              paidDate: _sunday,
            ),
          ],
        ),
      );

      expect(state.struckCount, 1, reason: 'só a luz caiu');
      expect(state.partialCommitments.single.installment.id, 'inter');
      expect(state.isDefeated, isFalse);
    });

    test('resíduo de centavos conta como quitado', () {
      // Medido na base: de 73 faturas do cofre, TRÊS fecharam com dois a
      // quatro centavos faltando. É o arredondamento do banco, não dívida —
      // e com "resto exatamente zero" essas semanas terminariam com o monstro
      // vivo em quatro centavos, para sempre, sem vitória nenhuma.
      final state = ArenaCalculator.from(
        _inputs(week: [invoicePaid(id: 'c6', amount: 3942.04, paid: 3942.00)]),
      );

      final linha = state.commitments.single;
      expect(linha.isStruck, isTrue);
      expect(linha.isPartial, isFalse);
      expect(linha.residue, closeTo(0.04, 0.001));
      expect(state.isDefeated, isTrue, reason: 'a semana acabou');

      // O VALOR continua exato: a tolerância decide quando a luta acabou, não
      // quanto ela custou.
      expect(state.monsterHp, closeTo(0.04, 0.001));
      expect(state.monsterMaxHp, 3942.04);
    });

    test('um real faltando NÃO é resíduo', () {
      final state = ArenaCalculator.from(
        _inputs(week: [invoicePaid(id: 'f', amount: 3942.04, paid: 3941.04)]),
      );

      final linha = state.commitments.single;
      expect(linha.isStruck, isFalse);
      expect(linha.isPartial, isTrue);
      expect(linha.residue, 0);
      expect(state.isDefeated, isFalse);
      expect(state.monsterHp, 1);
    });

    test('cinco centavos ainda é resíduo; seis não é', () {
      // O limite, dos dois lados. Medido no histórico: o maior resíduo real é
      // de quatro centavos, e cinco dá uma folga de um.
      final noLimite = ArenaCalculator.from(
        _inputs(week: [invoicePaid(id: 'a', amount: 100.05, paid: 100.00)]),
      );
      final passouDoLimite = ArenaCalculator.from(
        _inputs(week: [invoicePaid(id: 'b', amount: 100.06, paid: 100.00)]),
      );

      expect(noLimite.isDefeated, isTrue);
      expect(passouDoLimite.isDefeated, isFalse);
    });

    test('uma linha com resíduo não salva a semana inteira', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            invoicePaid(id: 'quitada', amount: 3942.04, paid: 3942.00),
            _expense(id: 'luz', amount: 180, dayOffset: 2),
          ],
        ),
      );

      expect(state.isDefeated, isFalse);
      expect(state.struckCount, 1);
    });

    test('o atraso conta pelo que ainda FALTA', () {
      // Uma fatura vencida com pagamento parcial deve o resto, não o total.
      final state = ArenaCalculator.from(
        _inputs(
          overdue: [
            InstallmentModel(
              id: 'fatura',
              orderId: 'order-fatura',
              amount: 8075.61,
              paidAmount: 7521.50,
              paidDate: _sunday.add(const Duration(days: -1)),
              description: 'Fatura',
              dueDate: _sunday.add(const Duration(days: -4)),
              status: InstallmentStatus.pending,
              type: OrderType.transfer,
              installmentType: InstallmentType.single,
              isInvoice: true,
              accounts: const {'cartao': AccountImpact.credit},
            ),
          ],
        ),
      );

      expect(state.overdueAmount, closeTo(554.11, 0.001));
      expect(state.isEnraged, isTrue);
    });
  });

  group('o rombo: comprometido acima do caixa', () {
    test('o retrato real do domingo: barra cheia e semana perdida', () {
      // R\$ 3.115,02 em caixa contra R\$ 12.122,33 de compromisso. A barra
      // está CHEIA — é domingo, nada saiu ainda — e sem um estado próprio a
      // cena diria "tudo bem".
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 3115.02, current: 3115.02)],
          week: [_expense(id: 'emprestimo', amount: 3811.78, dayOffset: 2)],
          overdue: [
            _pendingInvoice(id: 'fatura', amount: 8300.55, dayOffset: -3),
            _expense(id: 'c6', amount: 10, dayOffset: -4),
          ],
        ),
      );

      expect(state.currentBalance, 3115.02);
      expect(state.monsterHp, 12122.33);
      expect(state.heroHpRatio, 1, reason: 'a barra está cheia');
      expect(state.isPressed, isTrue);
      expect(state.heroMood, HeroMood.pressed);
      expect(state.shortfall, closeTo(9007.31, 0.001));
      expect(state.freeBalance, closeTo(-9007.31, 0.001));
    });

    test('caixa que cobre não é rombo', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('c', initial: 5000, current: 5000)],
          week: [_expense(id: 'aluguel', amount: 1200, dayOffset: 2)],
        ),
      );

      expect(state.isPressed, isFalse);
      expect(state.shortfall, 0);
      expect(state.heroMood, HeroMood.healthy);
    });

    test('saldo negativo é exausto, e exausto ganha do pressionado', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('c', initial: 500, current: -120)],
          week: [_expense(id: 'aluguel', amount: 1200, dayOffset: 2)],
        ),
      );

      expect(state.isPressed, isTrue);
      expect(state.heroMood, HeroMood.exhausted);
    });

    test('o maior pendente é a causa do rombo', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('c', initial: 100, current: 100)],
          week: [_expense(id: 'emprestimo', amount: 3811.78, dayOffset: 2)],
          overdue: [
            _pendingInvoice(id: 'fatura', amount: 8300.55, dayOffset: -3),
          ],
        ),
      );

      expect(state.largestPending?.installment.id, 'fatura');
      expect(state.largestPending?.remaining, 8300.55);
    });
  });

  group('golpe agendado', () {
    test('pago com data FUTURA não desconta hoje', () {
      // O monstro não pode nascer abatido no domingo com a semana inteira de
      // débito automático já cobrada.
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'aluguel',
              amount: 1200,
              dayOffset: 5,
              status: InstallmentStatus.paid,
              paidDate: _sunday.add(const Duration(days: 5)),
            ),
            _expense(id: 'luz', amount: 180, dayOffset: 2),
          ],
        ),
      );

      expect(state.monsterMaxHp, 1380);
      expect(state.monsterHp, 1380, reason: 'nada saiu do caixa ainda');
      expect(state.scheduledStrikes.single.installment.id, 'aluguel');
      expect(state.struckCount, 0);
    });

    test('quando o dia chega, o golpe desconta', () {
      final state = ArenaCalculator.from(
        _inputs(
          today: _sunday.add(const Duration(days: 5)),
          week: [
            _expense(
              id: 'aluguel',
              amount: 1200,
              dayOffset: 5,
              status: InstallmentStatus.paid,
              paidDate: _sunday.add(const Duration(days: 5)),
            ),
          ],
        ),
      );

      expect(state.monsterHp, 0);
      expect(state.isDefeated, isTrue);
      expect(state.scheduledStrikes, isEmpty);
    });

    test('pago SEM data de pagamento conta como golpe dado', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'aluguel',
              amount: 1200,
              status: InstallmentStatus.settled,
            ),
          ],
        ),
      );

      expect(state.monsterHp, 0);
    });
  });

  group('atrasado dentro da semana', () {
    test('pendente com vencimento antes de hoje é atraso — sem enfurecer', () {
      final state = ArenaCalculator.from(
        _inputs(week: [_expense(id: 'luz', amount: 180, dayOffset: 1)]),
      );

      final luz = state.commitments.single;
      expect(luz.isLate, isTrue);
      expect(luz.isOverdue, isFalse);
      expect(luz.isBehind, isTrue);
      expect(
        state.isEnraged,
        isFalse,
        reason: 'enfurecer é privilégio do atraso de semanas anteriores',
      );
    });

    test('ele sobe para o topo da folha, junto com o atraso antigo', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'hoje', amount: 30, dayOffset: 3),
            _expense(id: 'atrasada-na-semana', amount: 40, dayOffset: 1),
          ],
          overdue: [_expense(id: 'atrasada-antes', amount: 10, dayOffset: -4)],
        ),
      );

      expect(state.commitments.map((c) => c.installment.id).toList(), [
        'atrasada-antes',
        'atrasada-na-semana',
        'hoje',
      ]);
    });

    test('o que venceu e foi PAGO não é atraso', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'luz',
              amount: 180,
              dayOffset: 1,
              status: InstallmentStatus.paid,
              paidDate: _sunday.add(const Duration(days: 1)),
            ),
          ],
        ),
      );

      expect(state.commitments.single.isLate, isFalse);
    });
  });

  group('atraso', () {
    test('soma ao HP inicial, enfurece o monstro e vira cicatriz', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [_expense(id: 'luz', amount: 180, dayOffset: 3)],
          overdue: [_expense(id: 'cartao', amount: 640, dayOffset: -9)],
        ),
      );

      expect(state.overdueAmount, 640);
      expect(state.monsterMaxHp, 820);
      expect(state.monsterHp, 820);
      expect(state.isEnraged, isTrue);
      expect(state.monsterSkin, MonsterSkin.demon);
    });

    test('parcela atrasada JÁ PAGA não conta', () {
      final state = ArenaCalculator.from(
        _inputs(
          overdue: [
            _expense(
              id: 'cartao',
              amount: 640,
              dayOffset: -9,
              status: InstallmentStatus.paid,
            ),
          ],
        ),
      );

      expect(state.overdueAmount, 0);
      expect(state.isEnraged, isFalse);
    });

    test('o atrasado é marcado como tal na lista', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [_expense(id: 'luz', amount: 180, dayOffset: 3)],
          overdue: [_expense(id: 'cartao', amount: 640, dayOffset: -9)],
        ),
      );

      final atrasado = state.commitments.firstWhere((c) => c.isOverdue);
      expect(atrasado.installment.id, 'cartao');
      expect(atrasado.isPaid, isFalse);
      expect(atrasado.daysUntilDue, lessThan(0));
    });
  });

  group('ordem da folha do monstro', () {
    test(
      'atrasados, hoje, amanhã, resto da semana — e os pagos por último',
      () {
        final state = ArenaCalculator.from(
          _inputs(
            week: [
              // quarta é o dia 3 (offset 3); sábado é 6.
              _expense(id: 'sabado', amount: 50, dayOffset: 6),
              _expense(id: 'quinta', amount: 40, dayOffset: 4),
              _expense(id: 'hoje', amount: 30, dayOffset: 3),
              _expense(
                id: 'pago',
                amount: 20,
                dayOffset: 1,
                status: InstallmentStatus.paid,
                paidDate: _sunday.add(const Duration(days: 1)),
              ),
            ],
            overdue: [_expense(id: 'atrasado', amount: 10, dayOffset: -4)],
          ),
        );

        expect(state.commitments.map((c) => c.installment.id).toList(), [
          'atrasado',
          'hoje',
          'quinta',
          'sabado',
          'pago',
        ]);
      },
    );

    test('"hoje" e "amanhã" são o próximo golpe; o resto da semana não é', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'hoje', amount: 30, dayOffset: 3),
            _expense(id: 'amanha', amount: 40, dayOffset: 4),
            _expense(id: 'sabado', amount: 50, dayOffset: 6),
          ],
        ),
      );

      expect(state.nextBlow.map((c) => c.installment.id).toList(), [
        'hoje',
        'amanha',
      ]);
      expect(state.commitments.first.isDueToday, isTrue);
      expect(state.commitments[1].isDueTomorrow, isTrue);
    });

    test('o que já venceu e não foi pago não é "próximo golpe": é atraso', () {
      final state = ArenaCalculator.from(
        _inputs(overdue: [_expense(id: 'atrasado', amount: 10, dayOffset: -4)]),
      );

      expect(state.nextBlow, isEmpty);
      expect(state.pendingCommitments.single.isOverdue, isTrue);
    });

    test('pendentes e pagos são separáveis pela folha', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'a', amount: 10, dayOffset: 4),
            _expense(
              id: 'b',
              amount: 20,
              status: InstallmentStatus.paid,
              paidDate: _sunday,
            ),
          ],
        ),
      );

      expect(state.pendingCommitments.map((c) => c.installment.id), ['a']);
      expect(state.paidCommitments.map((c) => c.installment.id), ['b']);
    });
  });

  group('HP dos heróis: o saldo é a vida', () {
    test('máximo é o saldo de domingo; atual é o de agora', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            _account('corrente', initial: 4200, current: 3100),
            _account('investimento', initial: 1000, current: 880),
          ],
        ),
      );

      expect(state.initialBalance, 5200);
      expect(state.currentBalance, 3980);
      expect(state.heroHpRatio, closeTo(3980 / 5200, 0.0001));
      expect(state.isOverhealed, isFalse);
    });

    test('a soma das contas é em centavos', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            for (var i = 0; i < 3; i++)
              _account('c$i', initial: 0.1, current: 0.1),
          ],
        ),
      );

      expect(state.initialBalance, 0.30);
      expect(state.currentBalance, 0.30);
    });

    test('conta SEM documento antes do domingo entra com zero no inicial', () {
      // É o caso da conta criada no meio da semana: ela não existia no começo
      // da luta, e inventar um saldo de partida para ela faria a barra nascer
      // cheia com dinheiro que não estava lá.
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            _account('antiga', initial: 3000, current: 2500),
            _account('nova', initial: 0, current: 700),
          ],
        ),
      );

      expect(state.initialBalance, 3000);
      expect(state.currentBalance, 3200);
      expect(state.isOverhealed, isTrue, reason: 'entrou mais do que saiu');
      expect(state.overheal, 200);
      expect(state.heroHpRatio, 1, reason: 'a barra cheia para no topo');
    });

    test('o comprometido é o MESMO número do monstro', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 5000, current: 4000)],
          week: [_expense(id: 'aluguel', amount: 1200)],
        ),
      );

      expect(state.committed, state.monsterHp);
      expect(state.committed, 1200);
      expect(state.freeBalance, 2800);
      expect(state.committedRatio, closeTo(1200 / 5000, 0.0001));
    });

    test('comprometido acima do saldo de domingo: a hachura para em 1', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 400, current: 300)],
          week: [_expense(id: 'aluguel', amount: 1200)],
        ),
      );

      expect(state.committedRatio, 1);
      expect(state.freeBalance, -900);
    });

    test('saldo negativo: exausto', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('corrente', initial: 500, current: -120)]),
      );

      expect(state.heroMood, HeroMood.exhausted);
      expect(state.heroHpRatio, 0);
    });

    test('abaixo de um terço do saldo de domingo: machucado', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('corrente', initial: 3000, current: 800)]),
      );

      expect(state.heroMood, HeroMood.hurt);
    });

    test('sem saldo de partida, qualquer caixa positivo é barra cheia', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('nova', initial: 0, current: 700)]),
      );

      expect(state.heroHpRatio, 1);
      expect(state.heroMood, HeroMood.healthy);
    });

    test('cada conta guarda início, atual e a diferença', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            _account('c1', name: 'Nubank', initial: 4200, current: 3100),
            _account('c2', name: 'Tesouro', initial: 1000, current: 1000),
          ],
        ),
      );

      expect(state.accounts.first.name, 'Nubank');
      expect(state.accounts.first.delta, -1100);
      expect(state.accounts.last.delta, 0);
    });
  });

  group('cura', () {
    test('receita RECEBIDA na semana cura; a agendada não', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 1000, current: 7000)],
          week: [
            _income(id: 'salario', amount: 6000),
            _income(
              id: 'freela',
              amount: 900,
              status: InstallmentStatus.pending,
            ),
          ],
        ),
      );

      expect(state.healedThisWeek, 6000);
    });
  });

  group('elenco', () {
    test('dois heróis com skins distintas e o resto vira contador', () {
      final state = ArenaCalculator.from(
        _inputs(
          members: [
            _member('u1', name: 'Gabriel Silva'),
            _member('u2', name: 'Ana Paula'),
            _member('u3', name: 'João'),
          ],
        ),
      );

      expect(state.heroes.map((h) => h.name).toList(), ['Gabriel', 'Ana']);
      expect(state.heroes.first.skin, isNot(state.heroes.last.skin));
      expect(state.extraMembers, 1);
    });

    test('sem nome, o herói usa o começo do e-mail', () {
      final state = ArenaCalculator.from(
        _inputs(members: [_member('u1', email: 'gafsel@funances.test')]),
      );

      expect(state.heroes.single.name, 'gafsel');
    });
  });

  group('o marcador do dia', () {
    test('domingo é o dia 1 de 7; quarta é o 4', () {
      expect(
        ArenaCalculator.from(_inputs(today: _sunday)).day,
        ArenaDay.sunday,
      );
      expect(ArenaCalculator.from(_inputs(today: _wednesday)).day.ordinal, 4);
      expect(ArenaCalculator.from(_inputs(today: _wednesday)).day.daysLeft, 4);
    });

    test('sábado é o último dia', () {
      final saturday = _sunday.add(const Duration(days: 6));
      final state = ArenaCalculator.from(_inputs(today: saturday));

      expect(state.day, ArenaDay.saturday);
      expect(state.day.daysLeft, 1);
    });
  });

  group('monstro da semana', () {
    test('a skin é estável para o mesmo id de semana', () {
      expect(
        ArenaCalculator.skinForWeek('2026-W12'),
        ArenaCalculator.skinForWeek('2026-W12'),
      );
    });

    test('semanas vizinhas não repetem o bicho', () {
      expect(
        ArenaCalculator.skinForWeek('2026-W12'),
        isNot(ArenaCalculator.skinForWeek('2026-W13')),
      );
    });
  });

  group('cena vazia', () {
    test(
      'sem compromisso e sem caixa, a Arena sabe que não tem o que mostrar',
      () {
        expect(ArenaCalculator.from(_inputs()).isEmpty, isTrue);
      },
    );

    test('caixa sozinho já é motivo para desenhar a cena', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('c', initial: 100, current: 100)]),
      );

      expect(state.isEmpty, isFalse);
    });
  });
}
