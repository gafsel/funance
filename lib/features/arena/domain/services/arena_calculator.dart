import 'package:funances/core/money/money.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

/// Um saldo de conta lido duas vezes: no domingo e agora.
///
/// O `initial` é o último documento de `accounts/{id}/balance/{dateKey}` com
/// `dateKey` ANTERIOR ao domingo. Conta que não tinha nenhum documento antes
/// do domingo — porque foi criada durante a semana — entra com zero, que é a
/// verdade: ela não existia no começo da luta.
class ArenaAccountReading {
  const ArenaAccountReading({
    required this.accountId,
    required this.name,
    required this.initial,
    required this.current,
  });

  final String accountId;
  final String name;
  final double initial;
  final double current;
}

/// O que a Arena precisa ler para montar a cena.
///
/// Tudo aqui já existe no app e já é observado por alguma tela. A Arena não
/// inventa consulta nova nem campo novo: ela recombina.
class ArenaInputs {
  const ArenaInputs({
    required this.weekId,
    required this.today,
    required this.accounts,
    required this.weekInstallments,
    required this.overdueInstallments,
    required this.members,
    this.weeklyXp = 0,
    this.maxHeroes = 2,
  });

  /// `YYYY-Www` do servidor.
  final String weekId;

  /// O dia de hoje, do relógio do app. Decide o marcador da semana e a ordem
  /// da folha do monstro ("hoje", "amanhã", "resto").
  final DateTime today;

  /// As contas LÍQUIDAS (corrente + investimento), cada uma com o saldo de
  /// domingo e o de agora. Cartão e dívida ficam de fora: o que está no
  /// cartão ainda não saiu, e dívida não é caixa.
  final List<ArenaAccountReading> accounts;

  /// Parcelas cuja `referenceDate` cai na semana. `referenceDate` é
  /// `paidDate ?? dueDate`, e é por isso que esta lista serve às duas contas
  /// ao mesmo tempo: o que está pendente entrou pelo vencimento, o que foi
  /// pago entrou pela data do pagamento.
  final List<InstallmentModel> weekInstallments;

  /// Parcelas ainda pendentes com vencimento ANTES da semana.
  final List<InstallmentModel> overdueInstallments;

  /// Membros do workspace, na ordem de entrada (o primeiro é o dono).
  final List<UserModel> members;

  final double weeklyXp;

  /// Quantos membros viram herói de verdade. O resto vira contador.
  final int maxHeroes;
}

/// A conta da Arena, isolada de Riverpod, de Firestore e de widget.
///
/// Está aqui inteira, e não espalhada pelos componentes do Flame, porque é a
/// parte que precisa estar CERTA: o resto é enfeite, e enfeite se conserta
/// olhando. Ver `test/arena/arena_calculator_test.dart`.
///
/// ## A mecânica, em quatro linhas
///
/// 1. **monstro** = compromissos agendados da semana + atraso. Nada de
///    orçamento por categoria — o rateio contava o mesmo dinheiro duas vezes,
///    e categoria vai ter tela própria;
/// 2. **heróis** = saldo das contas líquidas, do domingo até agora. O saldo
///    **é** o HP: não há uma segunda régua;
/// 3. **cura** = receita recebida na semana;
/// 4. **dano** = qualquer saída de caixa. Ela aparece sozinha, porque a barra
///    dos heróis é o saldo.
abstract final class ArenaCalculator {
  /// Só despesa alimenta o monstro. Receita cura, transferência não é nem uma
  /// coisa nem outra (o dinheiro continua no workspace).
  static bool _isExpense(InstallmentModel i) => i.type == OrderType.expense;

  static bool _isSettled(InstallmentModel i) =>
      i.status == InstallmentStatus.paid ||
      i.status == InstallmentStatus.settled;

  /// A skin de um herói pela ORDEM de entrada no workspace.
  static HeroSkin skinForIndex(int index) =>
      HeroSkin.values[index % HeroSkin.values.length];

  /// O monstro da semana, sorteado pelo ID da semana.
  ///
  /// Determinístico de propósito: o mesmo `weekId` dá o mesmo bicho em todo
  /// aparelho, em toda sessão. Enfurecido tem cara própria — o demônio — e
  /// por isso a decisão de skin também olha o atraso.
  static MonsterSkin skinForWeek(String weekId, {bool enraged = false}) {
    if (enraged) return MonsterSkin.demon;

    final seed = weekId.codeUnits.fold<int>(0, (acc, unit) => acc + unit);
    const pool = <MonsterSkin>[
      MonsterSkin.spider,
      MonsterSkin.bat,
      MonsterSkin.ghost,
      MonsterSkin.slime,
    ];

    return pool[seed % pool.length];
  }

  /// Dias de calendário entre dois dias, ignorando a hora.
  ///
  /// Em UTC porque `difference().inDays` em horário local perde uma hora na
  /// virada do horário de verão e devolve 0 para o dia seguinte.
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  static ArenaState from(ArenaInputs inputs) {
    final weekStart = ProductWeek.startOf(inputs.today);

    // ── Monstro: SÓ compromisso agendado ───────────────────────────────────
    //
    // A soma é em CENTAVOS (`Money`) e não em `double`: uma semana de doze
    // parcelas somada em ponto flutuante já diverge da soma das linhas que a
    // folha do monstro mostra, e aí o golpe tira um valor e a barra anda
    // outro.
    final overdueRaw = inputs.overdueInstallments
        .where(_isExpense)
        .where((i) => !_isSettled(i))
        .toList();

    final commitments = <ArenaCommitment>[
      for (final i in overdueRaw)
        ArenaCommitment(
          installment: i,
          isPaid: false,
          isOverdue: true,
          daysUntilDue: daysBetween(inputs.today, i.dueDate),
        ),
      for (final i in inputs.weekInstallments.where(_isExpense))
        ArenaCommitment(
          installment: i,
          isPaid: _isSettled(i),
          isOverdue: false,
          daysUntilDue: daysBetween(inputs.today, i.dueDate),
        ),
    ]..sort(_commitmentOrder);

    final overdue = Money.sumOf(overdueRaw, (i) => i.amount);

    // HP inicial: tudo o que a semana tinha para pagar, mais o que ficou de
    // trás. O que já foi pago continua contando no INICIAL — é dano já
    // causado, e tirá-lo do total faria a barra encolher por baixo em vez de
    // esvaziar.
    final commitmentsInitial = Money.sumOf(commitments, (c) => c.amount);
    final paid = Money.sumOf(
      commitments.where((c) => c.isPaid),
      (c) => c.amount,
    );
    final commitmentsRemaining = commitmentsInitial - paid;

    // ── Heróis ─────────────────────────────────────────────────────────────
    final healed = Money.sumOf(
      inputs.weekInstallments
          .where((i) => i.type == OrderType.income)
          .where(_isSettled),
      (i) => i.referenceAmount,
    );

    final accounts = [
      for (final a in inputs.accounts)
        ArenaAccountLife(
          accountId: a.accountId,
          name: a.name,
          initial: a.initial,
          current: a.current,
        ),
    ];

    final initialBalance = Money.sumOf(accounts, (a) => a.initial);
    final currentBalance = Money.sumOf(accounts, (a) => a.current);

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

    final dayIndex = daysBetween(weekStart, inputs.today).clamp(0, 6);

    return ArenaState(
      weekId: inputs.weekId,
      day: ArenaDay.values[dayIndex],
      initialBalance: initialBalance.toDouble(),
      currentBalance: currentBalance.toDouble(),
      accounts: accounts,
      healedThisWeek: healed.toDouble(),
      commitments: commitments,
      commitmentsInitial: commitmentsInitial.toDouble(),
      // Um pagamento a mais do que o previsto (parcela paga com valor maior)
      // não deixa o restante negativo: a barra para no zero.
      commitmentsRemaining: commitmentsRemaining < Money.zero
          ? 0
          : commitmentsRemaining.toDouble(),
      overdueAmount: overdue.toDouble(),
      monsterSkin: skinForWeek(inputs.weekId, enraged: overdue > Money.zero),
      heroes: heroes,
      extraMembers: inputs.members.length - cast.length,
      weeklyXp: inputs.weeklyXp,
    );
  }

  /// A ordem da folha do monstro: **atrasados, hoje, amanhã, resto da
  /// semana**, e os pagos por último.
  ///
  /// Não é a ordem de vencimento pura. O que está atrasado não tem mais
  /// "dia"; o que vence hoje ainda dá para resolver; o que já foi pago é
  /// histórico e não disputa atenção com nada.
  static int _commitmentOrder(ArenaCommitment a, ArenaCommitment b) {
    int rank(ArenaCommitment c) {
      if (c.isPaid) return 3;
      if (c.isOverdue) return 0;
      if (c.daysUntilDue <= 0) return 1;
      return 2;
    }

    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;

    final byDue = a.installment.dueDate.compareTo(b.installment.dueDate);
    if (byDue != 0) return byDue;

    return a.installment.id.compareTo(b.installment.id);
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
