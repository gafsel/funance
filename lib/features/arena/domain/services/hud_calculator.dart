import 'package:funances/core/money/money.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';

/// Uma categoria do sumário mensal, já cruzada com o documento da categoria.
///
/// O cruzamento é obrigatório e não é detalhe: o sumário guarda id, e sem o
/// documento não há como saber se aquele id é despesa, se é de sistema ou se
/// foi apagado. Categoria que o app não conhece **não vira aldeão** — é a
/// mesma peneira que o servidor faz no fechamento do mês, e a mesma que
/// `PeriodSummaryViewProviders.monthSummary` já fazia para a Visão Geral.
class HudCategoryReading {
  const HudCategoryReading({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
    required this.isSystem,
    required this.planned,
    required this.actual,
  });

  final String categoryId;
  final String name;
  final String icon;
  final String color;
  final bool isExpense;

  /// Categoria criada e mantida pelo servidor (saldo inicial, contrapartida
  /// de transferência). Ela não é aldeã: ninguém planejou nada ali.
  final bool isSystem;

  /// `generalPlannedAmount` — o LIMITE da categoria rateado no período. É o
  /// orçamento, e é ele que vira HP.
  final double planned;

  final double actual;
}

/// Um saldo de conta já lido com o teto de HOJE.
///
/// O teto não é opcional. Um lançamento agendado para sexta faz o servidor
/// gravar o saldo projetado de SEXTA, e o documento mais recente passa a ser
/// o do futuro: os cartões deste cofre têm documento de saldo até 2036. Quem
/// lê "o último" lê 2036.
class HudBalanceReading {
  const HudBalanceReading({
    required this.accountId,
    required this.name,
    required this.balance,
    this.color,
  });

  final String accountId;
  final String name;

  /// O saldo como a conta o guarda — negativo numa dívida.
  final double balance;

  final String? color;
}

/// `accounts.nextInvoice` de um cartão.
class HudInvoiceReading {
  const HudInvoiceReading({
    required this.accountId,
    required this.name,
    required this.amount,
    required this.closingDate,
    required this.dueDate,
    required this.isOpenCycle,
    this.color,
    this.installmentId,
    this.overdueDays = 0,
  });

  final String accountId;
  final String name;
  final double amount;
  final DateTime closingDate;
  final DateTime dueDate;

  /// O ciclo ainda não fechou: o valor é o acumulado e ainda sobe.
  final bool isOpenCycle;

  final String? color;

  /// `nextInvoice.installmentId` — nulo enquanto a fatura não existe de fato.
  final String? installmentId;

  /// Há quantos dias a fatura venceu, pelo relógio do app. Zero se não venceu.
  final int overdueDays;
}

/// O que o HUD mensal precisa ler. Nada aqui é consulta nova por capricho:
/// saldo, sumário do mês e `nextInvoice` já existem no app.
class HudInputs {
  const HudInputs({
    required this.monthKey,
    this.income,
    this.investments = const <HudBalanceReading>[],
    this.debts = const <HudBalanceReading>[],
    this.invoices = const <HudInvoiceReading>[],
    this.categories = const <HudCategoryReading>[],
    this.history = const <HudMonthlyReport>[],
    this.debtInstallments =
        const <String, ({Money amount, DateTime dueDate})>{},
  });

  final String monthKey;

  /// `workspaces.expectedIncome`. `null` = o servidor ainda não sabe.
  final ExpectedIncome? income;

  final List<HudBalanceReading> investments;
  final List<HudBalanceReading> debts;
  final List<HudInvoiceReading> invoices;
  final List<HudCategoryReading> categories;

  /// Os meses já fechados (`monthly_reports`).
  final List<HudMonthlyReport> history;

  /// A próxima parcela pendente de cada conta de dívida, por id da conta.
  final Map<String, ({Money amount, DateTime dueDate})> debtInstallments;
}

/// A conta do rodapé mensal, isolada de Riverpod, de Firestore e de widget.
///
/// Está aqui inteira pelo mesmo motivo que [ArenaCalculator]: é a parte que
/// precisa estar CERTA. Ver `test/arena/hud_calculator_test.dart`.
///
/// ## As quatro leituras, em quatro linhas
///
/// 1. **poção** = saldo das contas de investimento ÷ receita prevista;
/// 2. **vila** = Σ realizado ÷ Σ planejado das categorias de despesa com
///    orçamento — e o HP de cada aldeão é `orçamento − realizado`;
/// 3. **ovo** = Σ das próximas faturas ÷ receita prevista;
/// 4. **gota** = saldo devedor ÷ receita prevista.
///
/// O denominador das três razões é UM só, e ele vem do servidor. Quando ele
/// não existe, [HudRatio.tier] é nulo e a tela mostra o estado neutro: o app
/// não inventa denominador.
abstract final class HudCalculator {
  static HudState from(HudInputs inputs) {
    // A receita prevista de OUTRO mês não é a receita deste.
    //
    // O documento do workspace guarda um `monthKey`, e ele existe justamente
    // porque o campo pode ficar para trás: o cron do dia 1 pode não ter
    // rodado, o app pode estar aberto desde ontem e virar o mês na mão do
    // usuário, ou o gatilho de receita pode ter falhado. Sem conferir, o
    // rodapé dividiria as faturas de outubro pela receita de setembro e
    // apresentaria o resultado com a mesma confiança de um número certo.
    //
    // Fora de mês é tratado como AUSENTE, que é o estado que o contrato já
    // define para "ainda não sei" — e não como zero, que seria um veredito.
    final expected = inputs.income?.monthKey == inputs.monthKey
        ? inputs.income
        : null;
    final income = expected?.amount;

    return HudState(
      monthKey: inputs.monthKey,
      income: expected,
      potion: _potion(inputs, income),
      village: _village(inputs),
      egg: _egg(inputs, income),
      drop: _drop(inputs, income),
    );
  }

  // ── Poção: investimentos ──────────────────────────────────────────────

  static HudPotion _potion(HudInputs inputs, Money? income) {
    final accounts = <HudLabeledAmount>[
      for (final reading in inputs.investments)
        HudLabeledAmount(
          id: reading.accountId,
          name: reading.name,
          amount: Money.fromDouble(reading.balance),
          color: reading.color,
        ),
    ]..sort((a, b) => b.amount.cents.compareTo(a.amount.cents));

    // A soma é em centavos e inclui saldo negativo: uma conta de
    // investimento no vermelho (resgate maior que o aporte) não pode
    // desaparecer da conta só porque incomoda. O piso em zero está na razão,
    // não aqui — a folha mostra a linha como ela é.
    final total = Money.sum(accounts.map((a) => a.amount));

    return HudPotion(
      accounts: accounts,
      ratio: HudRatio(amount: total, income: income),
    );
  }

  // ── Vila: categorias ──────────────────────────────────────────────────

  static HudVillage _village(HudInputs inputs) {
    final villagers = <HudVillager>[];
    final unprotected = <HudLabeledAmount>[];

    for (final c in inputs.categories) {
      if (!c.isExpense || c.isSystem) continue;

      final planned = Money.fromDouble(c.planned);
      final actual = Money.fromDouble(c.actual);

      if (planned.isPositive) {
        villagers.add(
          HudVillager(
            categoryId: c.categoryId,
            name: c.name,
            icon: c.icon,
            color: c.color,
            planned: planned,
            actual: actual,
          ),
        );
        continue;
      }

      // Sem orçamento e sem gasto não é nada: nem aldeão, nem desprotegido.
      // É uma categoria que não aconteceu neste mês, e listá-la encheria a
      // folha de linhas zeradas.
      if (actual.isPositive) {
        unprotected.add(
          HudLabeledAmount(
            id: c.categoryId,
            name: c.name,
            amount: actual,
            color: c.color,
            icon: c.icon,
          ),
        );
      }
    }

    // Quem está pior primeiro — e "pior" muda de significado conforme o
    // aldeão está vivo ou morto.
    //
    // Ordenar por HP ABSOLUTO misturava as duas perguntas e respondia mal às
    // duas: "Investimentos", com R$ 200 de orçamento e nada gasto, subia
    // acima de "Cuidados pessoais", que tinha queimado 78% de R$ 1.500 e
    // estava prestes a cair — porque R$ 200 de folga é menos que R$ 328,80.
    // Folga em reais não é risco; a fração é.
    //
    // Então: os MORTOS primeiro, do mais fundo no vermelho (é o estrago que
    // o usuário precisa ver), e depois os vivos por FRAÇÃO de HP crescente —
    // quem está mais perto de morrer logo abaixo dos que já morreram.
    villagers.sort((a, b) {
      if (a.isAlive != b.isAlive) return a.isAlive ? 1 : -1;

      final by = a.isAlive
          ? a.hpRatio.compareTo(b.hpRatio)
          : a.hp.cents.compareTo(b.hp.cents);

      return by != 0 ? by : a.name.compareTo(b.name);
    });

    unprotected.sort((a, b) {
      final byAmount = b.amount.cents.compareTo(a.amount.cents);
      return byAmount != 0 ? byAmount : a.name.compareTo(b.name);
    });

    final history = [...inputs.history]
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));

    return HudVillage(
      villagers: villagers,
      unprotected: unprotected,
      history: history,
    );
  }

  // ── Ovo: cartões ──────────────────────────────────────────────────────

  static HudEgg _egg(HudInputs inputs, Money? income) {
    final invoices =
        <HudInvoice>[
          for (final reading in inputs.invoices)
            HudInvoice(
              accountId: reading.accountId,
              name: reading.name,
              amount: Money.fromDouble(reading.amount),
              closingDate: reading.closingDate,
              dueDate: reading.dueDate,
              color: reading.color,
              isOpenCycle: reading.isOpenCycle,
              installmentId: reading.installmentId,
              overdueDays: reading.overdueDays,
            ),
        ]..sort((a, b) {
          // VENCIDA primeiro, e explicitamente — não porque a data dela é
          // menor. Ordenar só por vencimento dá o mesmo resultado hoje e
          // deixaria de dar no dia em que uma fatura vencida for reemitida
          // com data futura; e é a ordem que a folha precisa garantir, não um
          // efeito colateral de outra regra.
          if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;

          final byDue = a.dueDate.compareTo(b.dueDate);
          return byDue != 0 ? byDue : a.name.compareTo(b.name);
        });

    final total = Money.sum(invoices.map((i) => i.amount));

    return HudEgg(
      invoices: invoices,
      ratio: HudRatio(amount: total, income: income),
    );
  }

  // ── Gota: dívidas ─────────────────────────────────────────────────────

  static HudDrop _drop(HudInputs inputs, Money? income) {
    final debts = <HudDebt>[];

    for (final reading in inputs.debts) {
      // O saldo devedor vem NEGATIVO da conta, e é em módulo que ele é uma
      // frase: "devo R$ 7.623,68". Uma conta de dívida com saldo positivo —
      // quitada com sobra — não deve nada, e entra como zero.
      final owed = reading.balance < 0
          ? Money.fromDouble(-reading.balance)
          : Money.zero;

      if (owed.isZero) continue;

      final next = inputs.debtInstallments[reading.accountId];

      debts.add(
        HudDebt(
          accountId: reading.accountId,
          name: reading.name,
          balance: owed,
          color: reading.color,
          installment: next?.amount,
          nextDueDate: next?.dueDate,
        ),
      );
    }

    debts.sort((a, b) {
      final byBalance = b.balance.cents.compareTo(a.balance.cents);
      return byBalance != 0 ? byBalance : a.name.compareTo(b.name);
    });

    final total = Money.sum(debts.map((d) => d.balance));

    return HudDrop(
      debts: debts,
      ratio: HudRatio(amount: total, income: income),
    );
  }
}
