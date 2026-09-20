import 'package:funances/core/money/money.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

/// O que a Arena precisa ler para montar a cena.
///
/// Tudo aqui já existe no app e já é observado por alguma tela. A Arena não
/// inventa consulta nova nem campo novo: ela recombina.
class ArenaInputs {
  const ArenaInputs({
    required this.weekId,
    required this.liquidBalance,
    required this.weekInstallments,
    required this.overdueInstallments,
    required this.members,
    this.weekSummary,
    this.weeklyXp = 0,
    this.invoice,
    this.maxHeroes = 2,
  });

  /// `YYYY-Www` do servidor.
  final String weekId;

  /// Saldo somado de corrente + investimento.
  final double liquidBalance;

  /// Parcelas cuja `referenceDate` cai na semana. `referenceDate` é
  /// `paidDate ?? dueDate`, e é por isso que esta lista serve às duas contas
  /// ao mesmo tempo: o que está pendente entrou pelo vencimento, o que foi
  /// pago entrou pela data do pagamento.
  final List<InstallmentModel> weekInstallments;

  /// Parcelas ainda pendentes com vencimento ANTES da semana.
  final List<InstallmentModel> overdueInstallments;

  /// Membros do workspace, na ordem de entrada (o primeiro é o dono).
  final List<UserModel> members;

  /// `period_summaries/{weekId}`. `null` enquanto o servidor não agregou.
  final PeriodSummaryModel? weekSummary;

  final double weeklyXp;

  /// Resumo da fatura aberta do cartão principal.
  final NextInvoice? invoice;

  /// Quantos membros viram herói de verdade. O resto vira contador.
  final int maxHeroes;
}

/// A conta da Arena, isolada de Riverpod, de Firestore e de widget.
///
/// Está aqui inteira, e não espalhada pelos componentes do Flame, porque é a
/// parte que precisa estar CERTA: o resto é enfeite, e enfeite se conserta
/// olhando. Ver `test/arena/arena_calculator_test.dart`.
abstract final class ArenaCalculator {
  /// Só despesa alimenta o monstro. Receita cura, transferência não é nem uma
  /// coisa nem outra (o dinheiro continua no workspace).
  static bool _isExpense(InstallmentModel i) => i.type == OrderType.expense;

  static bool _isSettled(InstallmentModel i) =>
      i.status == InstallmentStatus.paid ||
      i.status == InstallmentStatus.settled;

  /// A skin de um herói pela ORDEM de entrada no workspace.
  ///
  /// Enquanto `users/{uid}.avatar` não existir, é o que dá dois bonecos
  /// distintos e estáveis para o mesmo par de pessoas.
  static HeroSkin skinForIndex(int index) =>
      HeroSkin.values[index % HeroSkin.values.length];

  /// O monstro da semana, sorteado pelo ID da semana.
  ///
  /// Determinístico de propósito: o mesmo `weekId` dá o mesmo bicho em todo
  /// aparelho, em toda sessão. Enfurecido tem cara própria — o demônio — e
  /// por isso a decisão de skin também olha o atraso.
  static MonsterSkin skinForWeek(String weekId, {bool enraged = false}) {
    if (enraged) return MonsterSkin.demon;

    // Soma dos códigos: mistura suficiente para dois ids vizinhos
    // (`2026-W12` e `2026-W13`) caírem em bichos diferentes, e barata.
    final seed = weekId.codeUnits.fold<int>(0, (acc, unit) => acc + unit);
    const pool = <MonsterSkin>[
      MonsterSkin.spider,
      MonsterSkin.bat,
      MonsterSkin.ghost,
      MonsterSkin.slime,
    ];

    return pool[seed % pool.length];
  }

  static ArenaState from(ArenaInputs inputs) {
    // ── Monstro, parte 1: as parcelas ──────────────────────────────────────
    //
    // A soma é em CENTAVOS (`Money`) e não em `double`: uma semana de doze
    // parcelas somada em ponto flutuante já diverge da soma das linhas que a
    // folha do monstro mostra, e aí o golpe tira um valor e a barra anda
    // outro.
    final expenses = inputs.weekInstallments.where(_isExpense).toList();

    final overdue = Money.sumOf(
      inputs.overdueInstallments.where(_isExpense).where((i) => !_isSettled(i)),
      (i) => i.amount,
    );

    final weekInstallmentsTotal = Money.sumOf(
      expenses,
      (i) => i.referenceAmount,
    );

    final paidThisWeek = Money.sumOf(
      expenses.where(_isSettled),
      (i) => i.referenceAmount,
    );

    // HP inicial da parte "parcelas": o que a semana devia no domingo, mais o
    // que ficou de trás. O que já foi pago continua contando no INICIAL — é
    // dano já causado, e tirá-lo do total faria a barra encolher por baixo em
    // vez de esvaziar.
    final installmentsInitial = weekInstallmentsTotal + overdue;
    final installmentsRemaining = installmentsInitial - paidThisWeek;

    // ── Monstro, parte 2: o orçamento ──────────────────────────────────────
    //
    // `period_summaries/{weekId}` já traz o rateio semanal por categoria;
    // o app não reparte nada por conta própria.
    final categories =
        inputs.weekSummary?.categories ??
        const <String, PeriodSummaryCategoryModel>{};

    var budgetInitial = Money.zero;
    var spentWithinPlan = Money.zero;
    var overspent = Money.zero;

    for (final summary in categories.values) {
      final planned = Money.fromDouble(summary.plannedAmount);
      final actual = Money.fromDouble(summary.actualAmount);

      budgetInitial += planned;

      if (actual <= planned) {
        spentWithinPlan += actual;
      } else {
        spentWithinPlan += planned;
        // Categoria sem limite tem `planned` zero, e então o gasto INTEIRO é
        // excesso: é assim que "gasto fora do plano" e "gasto acima do
        // limite" viram a mesma conta, em vez de dois caminhos que divergem.
        overspent += actual - planned;
      }
    }

    final budgetRemaining = budgetInitial - spentWithinPlan;

    // ── Herói ──────────────────────────────────────────────────────────────
    final healed = Money.sumOf(
      inputs.weekInstallments
          .where((i) => i.type == OrderType.income)
          .where(_isSettled),
      (i) => i.referenceAmount,
    );

    // ── Elenco ─────────────────────────────────────────────────────────────
    final cast = inputs.members.take(inputs.maxHeroes).toList();
    final heroes = <ArenaHero>[
      for (var index = 0; index < cast.length; index++)
        ArenaHero(
          userId: cast[index].id,
          name: _firstName(cast[index]),
          skin: skinForIndex(index),
          photoUrl: cast[index].photoUrl,
        ),
    ];

    final pending = expenses.where((i) => !_isSettled(i)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ArenaState(
      weekId: inputs.weekId,
      liquidBalance: inputs.liquidBalance,
      healedThisWeek: healed.toDouble(),
      damageThisWeek: overspent.toDouble(),
      installmentsInitial: installmentsInitial.toDouble(),
      // Um pagamento a mais do que o previsto (parcela paga com valor maior)
      // não deixa o restante negativo: a barra para no zero.
      installmentsRemaining: installmentsRemaining < Money.zero
          ? 0
          : installmentsRemaining.toDouble(),
      budgetInitial: budgetInitial.toDouble(),
      budgetRemaining: budgetRemaining < Money.zero
          ? 0
          : budgetRemaining.toDouble(),
      overdueAmount: overdue.toDouble(),
      monsterSkin: skinForWeek(inputs.weekId, enraged: overdue > Money.zero),
      heroes: heroes,
      extraMembers: inputs.members.length - cast.length,
      weeklyXp: inputs.weeklyXp,
      invoiceAmount: inputs.invoice?.amount,
      invoiceInstallmentId: inputs.invoice?.installmentId,
      pendingInstallments: pending,
    );
  }

  /// Primeiro nome, ou o começo do e-mail. O balão em cima do herói tem
  /// espaço para uma palavra.
  static String _firstName(UserModel user) {
    final display = user.displayName?.trim();
    if (display != null && display.isNotEmpty) return display.split(' ').first;

    final local = user.email.split('@').first;
    return local.isEmpty ? user.id : local;
  }
}
