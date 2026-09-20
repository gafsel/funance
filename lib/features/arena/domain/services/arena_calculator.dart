import 'package:funances/core/money/money.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
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
    this.memberOrder = const <String>[],
    this.currentUser,
    this.accountTypes = const <String, AccountType>{},
    this.weeklyXp = 0,
    this.maxHeroes = 2,
  });

  /// `YYYY-Www` do servidor.
  final String weekId;

  /// O dia de hoje, do relógio do app. Decide o marcador da semana e a ordem
  /// da folha do monstro ("hoje", "amanhã", "resto").
  final DateTime today;

  /// As contas CORRENTES, cada uma com o saldo de domingo e o de agora.
  ///
  /// Cartão e dívida ficam de fora: o que está no cartão ainda não saiu, e
  /// dívida não é caixa. O investimento também — ele é a poção do HUD
  /// mensal.
  final List<ArenaAccountReading> accounts;

  /// Parcelas cuja `referenceDate` cai na semana. `referenceDate` é
  /// `paidDate ?? dueDate`, e é por isso que esta lista serve às duas contas
  /// ao mesmo tempo: o que está pendente entrou pelo vencimento, o que foi
  /// pago entrou pela data do pagamento.
  final List<InstallmentModel> weekInstallments;

  /// Parcelas ainda pendentes com vencimento ANTES da semana.
  final List<InstallmentModel> overdueInstallments;

  /// Membros do workspace, na ordem em que a callable os devolveu — que **não
  /// é** a ordem de entrada. Ver [memberOrder].
  final List<UserModel> members;

  /// `workspaces/{id}.members`: os uids na ORDEM DE ENTRADA, com o criador no
  /// primeiro lugar.
  ///
  /// Existe porque `getWorkspaceMembers` lê os documentos com um
  /// `where(documentId, in: [...])`, e o Firestore devolve isso na ordem dos
  /// UIDs, não na do array. Era sorte de alfabeto quem ficava com o
  /// cavaleiro: um uid começado em "a" tomava o lugar do criador do cofre. O
  /// array do workspace é a única lista que guarda a chegada — o backend usa
  /// exatamente ela para decidir quem é o dono.
  ///
  /// Vazia (um teste, um workspace ainda sem o campo) mantém a ordem que
  /// veio.
  final List<String> memberOrder;

  /// O documento do PRÓPRIO usuário, lido direto de `users/{uid}`.
  ///
  /// A lista de membros vem inteira da callable, inclusive a linha do próprio
  /// usuário — e a callable só passa a devolver o `avatar` depois do deploy
  /// das functions. Sem esta sobreposição, quem escolhesse um herói não veria
  /// a própria escolha na cena, que é a metade da funcionalidade que não
  /// depende de servidor nenhum.
  final UserModel? currentUser;

  /// O tipo de CADA conta do workspace — inclusive as que não são caixa.
  ///
  /// É o que decide o que entra no monstro: sem saber que `acc-c6` é cartão e
  /// `acc-nubank` é corrente, não há como separar "comprei no cartão" (que
  /// não tira nada do caixa hoje) de "paguei a fatura" (que tira).
  final Map<String, AccountType> accountTypes;

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
/// 1. **monstro** = o que SAI DAS CONTAS LÍQUIDAS na semana, mais o atraso.
///    Ver [_leavesCash]. Nada de orçamento por categoria — o rateio contava o
///    mesmo dinheiro duas vezes, e categoria vai ter tela própria;
/// 2. **heróis** = saldo das contas líquidas, do domingo até agora. O saldo
///    **é** o HP: não há uma segunda régua;
/// 3. **cura** = receita recebida na semana;
/// 4. **dano** = qualquer saída de caixa. Ela aparece sozinha, porque a barra
///    dos heróis é o saldo.
abstract final class ArenaCalculator {
  static bool _isSettled(InstallmentModel i) =>
      i.status == InstallmentStatus.paid ||
      i.status == InstallmentStatus.settled;

  /// Conta que é CAIXA. Só a corrente.
  ///
  /// O investimento saiu daqui junto com o HUD mensal — ele é a POÇÃO do
  /// rodapé, e o mesmo saldo não pode ser vida dos heróis e reserva ao mesmo
  /// tempo. Ver [arenaLiquidTypes].
  static bool _isLiquid(AccountType? type) => type == AccountType.checking;

  /// Este lançamento tira dinheiro das CONTAS LÍQUIDAS nesta semana?
  ///
  /// É a pergunta inteira do monstro, e ela veio do retrato real do dono. Na
  /// rodada 1 o monstro era "toda parcela de despesa da semana", e com isso
  /// quatro compras no cartão (mercado, farmácia, aplicativo) entravam na
  /// barra. O efeito era o oposto do pretendido: pagar um compromisso
  /// derrubava o monstro **sem** derrubar a vida dos heróis, porque uma
  /// compra no cartão não move o caixa. "Pagar custa vida" deixava de ser
  /// verdade justamente nas linhas mais numerosas da semana.
  ///
  /// Entram:
  ///
  /// - **despesa cuja conta de saída é a CORRENTE**: o boleto, a conta de
  ///   luz, o débito automático — "Segurança C6";
  /// - **transferência de conta líquida para CARTÃO ou DÍVIDA**: é assim que
  ///   o app registra o pagamento da fatura e a parcela do empréstimo;
  /// - **compromisso de dívida SEM conta de saída** — ver abaixo.
  ///
  /// Ficam de fora as compras feitas NO cartão (conta de saída `creditCard`):
  /// elas não tiram nada do caixa hoje e chegam depois, somadas, como a
  /// fatura. Elas pertencem aos "incubados" do HUD mensal.
  ///
  /// ## A fatura em aberto não tem conta de saída
  ///
  /// Esta é a parte que a rodada 2 errou, e o erro era estrutural: o servidor
  /// cria a order da fatura com `accounts: {cartão: "credit"}` e mais nada
  /// (`finance.repository.impl.ts`). A conta que vai PAGAR só entra no
  /// documento na hora da quitação — até lá ela não foi escolhida.
  ///
  /// Com `if (source == null) return false`, o maior compromisso da semana do
  /// dono — R$ 8.300,55 de fatura, vencida e em atraso — ficava fora do
  /// monstro, e a barra mostrava um terço da dívida real.
  ///
  /// A leitura certa é pelo DESTINO: um lançamento pendente cujo lado de
  /// crédito é um cartão ou uma dívida **vai** sair do caixa; só ainda não se
  /// sabe de qual conta. Origem "a definir" não é motivo para o compromisso
  /// não existir. Quando ela é paga, `accountIdSource` passa a ser a conta
  /// pagadora e o caminho normal assume — o número é o mesmo pelos dois
  /// lados, e é isso que faz a barra não pular na quitação.
  ///
  /// Hoje só a fatura nasce assim; a regra é escrita pela FORMA (sem origem,
  /// destino de dívida) e não por `isInvoice`, porque o dia em que o servidor
  /// criar a parcela de um empréstimo do mesmo jeito, ela já estará certa.
  static bool _leavesCash(InstallmentModel i, Map<String, AccountType> types) {
    // Receita cura; ela nunca é monstro.
    if (i.type == OrderType.income) return false;

    final source = i.accountIdSource;

    if (source == null) {
      // Sem conta de saída: só entra se o DESTINO for dívida. Um lançamento
      // órfão de verdade (sem conta nenhuma) cai fora aqui, porque
      // `_creditSide` devolve null e `_isDebtLike(null)` é falso.
      return _isDebtLike(types[_creditSide(i)]);
    }

    if (!_isLiquid(types[source])) return false;

    return switch (i.type) {
      OrderType.expense => true,
      OrderType.transfer => _isDebtLike(types[_creditSide(i)]),
      OrderType.income => false,
    };
  }

  /// A conta do lado CREDIT — o destino do dinheiro.
  ///
  /// Não usa `accountIdTarget` porque aquele getter só responde para
  /// `OrderType.transfer`, e o que interessa aqui é a forma do documento, não
  /// o tipo declarado nele.
  static String? _creditSide(InstallmentModel i) => i.accounts.entries
      .where((entry) => entry.value == AccountImpact.credit)
      .map((entry) => entry.key)
      .firstOrNull;

  /// O destino de uma transferência que conta como pagamento de dívida.
  static bool _isDebtLike(AccountType? type) =>
      type == AccountType.creditCard || type == AccountType.debt;

  /// A skin de um herói pela ORDEM de entrada no workspace.
  ///
  /// É o que vale para quem ainda não escolheu avatar nenhum — e por isso ela
  /// cicla só pelos QUATRO da POC, e não por `HeroSkin.values`: o catálogo
  /// cresceu para oito, e ciclar por todos trocaria o boneco de quem nunca
  /// mexeu em nada só porque o seletor ganhou opções novas.
  static const List<HeroSkin> _legacyRotation = [
    HeroSkin.knight,
    HeroSkin.mage,
    HeroSkin.ranger,
    HeroSkin.warrior,
  ];

  static HeroSkin skinForIndex(int index) =>
      _legacyRotation[index % _legacyRotation.length];

  /// O avatar ESCOLHIDO pelo membro; a ordem de entrada quando não há
  /// escolha.
  ///
  /// Um `avatar` gravado com nome desconhecido não cai no cavaleiro fixo: ele
  /// cai no mesmo boneco que o membro teria sem campo nenhum, que é a
  /// resposta menos surpreendente para quem olha a cena.
  static HeroSkin skinForMember(UserModel member, int index) =>
      HeroSkin.tryFromName(member.avatar) ?? skinForIndex(index);

  /// O elenco na ORDEM DE ENTRADA, com o documento local do próprio usuário
  /// no lugar da linha que veio da callable.
  ///
  /// Duas correções que precisam acontecer ANTES de qualquer índice ser
  /// atribuído, porque é o índice que decide o boneco de quem não escolheu e
  /// quem leva o distintivo de repetido:
  ///
  /// 1. **ordem**: `getWorkspaceMembers` devolve os documentos na ordem dos
  ///    UIDs do Firestore, não na de chegada. [ArenaInputs.memberOrder] é o
  ///    array do workspace, que guarda a chegada de verdade;
  /// 2. **o próprio usuário**: a linha dele vem da callable, que só entrega o
  ///    `avatar` depois do deploy das functions. O documento local já tem.
  ///
  /// Quem não estiver em [ArenaInputs.memberOrder] (convite recém-aceito que
  /// o app ainda não recarregou) vai para o FIM, na ordem em que veio — some
  /// da cena só quem já não cabia nela.
  static List<UserModel> roster(ArenaInputs inputs) {
    final posicao = <String, int>{
      for (var i = 0; i < inputs.memberOrder.length; i++)
        inputs.memberOrder[i]: i,
    };

    final ordenados = [...inputs.members];
    if (posicao.isNotEmpty) {
      final semLugar = posicao.length;
      ordenados.sort((a, b) {
        final pa = posicao[a.id] ?? (semLugar + inputs.members.indexOf(a));
        final pb = posicao[b.id] ?? (semLugar + inputs.members.indexOf(b));
        return pa.compareTo(pb);
      });
    }

    final eu = inputs.currentUser;
    if (eu == null) return ordenados;

    return [
      for (final membro in ordenados)
        if (membro.id == eu.id) membro.copyWith(avatar: eu.avatar) else membro,
    ];
  }

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

    // ── Monstro: o que sai do caixa na semana ──────────────────────────────
    //
    // A soma é em CENTAVOS (`Money`) e não em `double`: uma semana de doze
    // parcelas somada em ponto flutuante já diverge da soma das linhas que a
    // folha do monstro mostra, e aí o golpe tira um valor e a barra anda
    // outro.
    final types = inputs.accountTypes;

    final overdueRaw = inputs.overdueInstallments
        .where((i) => !_isSettled(i))
        .where((i) => _leavesCash(i, types))
        .toList();

    final commitments = <ArenaCommitment>[
      for (final i in overdueRaw)
        ArenaCommitment(
          installment: i,
          isPaid: false,
          isOverdue: true,
          isScheduledStrike: false,
          daysUntilDue: daysBetween(inputs.today, i.dueDate),
        ),
      for (final i in inputs.weekInstallments.where(
        (i) => _leavesCash(i, types),
      ))
        ArenaCommitment(
          installment: i,
          isPaid: _isSettled(i),
          isOverdue: false,
          // Pago com data no futuro: o dinheiro ainda não saiu.
          isScheduledStrike:
              _isSettled(i) &&
              i.paidDate != null &&
              daysBetween(inputs.today, i.paidDate!) > 0,
          daysUntilDue: daysBetween(inputs.today, i.dueDate),
        ),
    ]..sort(_commitmentOrder);

    // O atraso conta pelo que AINDA falta: uma fatura vencida com pagamento
    // parcial deve o resto, não o total.
    final overdue = Money.sumOf(
      commitments.where((c) => c.isOverdue),
      (c) => c.remaining,
    );

    // HP inicial: tudo o que a semana tem para tirar do caixa, mais o que
    // ficou de trás. O que já foi pago continua contando no INICIAL — é dano
    // já causado, e tirá-lo do total faria a barra encolher por baixo em vez
    // de esvaziar.
    //
    // A soma é LINHA A LINHA, e cada linha sabe distinguir o PLANO do que foi
    // GOLPEADO (`ArenaCommitment.planned` e `.struck`). Antes era um só campo
    // (`referenceAmount`) dos dois lados, e uma quitação PARCIAL mentia: a
    // fatura do Cartão Inter, R$ 12.130,09 com R$ 1.000 pagos, entrava no
    // inicial pelos R$ 1.000 — o monstro perdia onze mil de vida e comemorava
    // uma vitória que não houve.
    //
    // A subtração não precisa de piso: `struck` já é preso ao `planned` da
    // própria linha, então o descontado nunca passa do inicial. Pagar a mais
    // não derruba nada além do compromisso — o excedente vira `overpaid` e
    // aparece na folha, não na barra.
    final commitmentsInitial = Money.sumOf(commitments, (c) => c.planned);
    final struck = Money.sumOf(commitments, (c) => c.struck);
    final commitmentsRemaining = commitmentsInitial - struck;

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
    final elenco = roster(inputs);
    final cast = elenco.take(inputs.maxHeroes).toList();
    final skins = [
      for (var index = 0; index < cast.length; index++)
        skinForMember(cast[index], index),
    ];
    final heroes = <ArenaHero>[
      for (var index = 0; index < cast.length; index++)
        ArenaHero(
          userId: cast[index].id,
          name: _firstName(cast[index]),
          skin: skins[index],
          photoUrl: cast[index].photoUrl,
          // Repetido só a partir do SEGUNDO: quem chegou primeiro fica com o
          // boneco limpo, e o distintivo marca a diferença, não a escolha.
          duplicate: skins.take(index).contains(skins[index]),
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
      commitmentsRemaining: commitmentsRemaining.toDouble(),
      overdueAmount: overdue.toDouble(),
      monsterSkin: skinForWeek(inputs.weekId, enraged: overdue > Money.zero),
      heroes: heroes,
      extraMembers: elenco.length - cast.length,
      weeklyXp: inputs.weeklyXp,
    );
  }

  /// A ordem da folha do monstro: **atrasados, hoje, amanhã, resto da
  /// semana**, e os pagos por último.
  ///
  /// Não é a ordem de vencimento pura. O que está atrasado não tem mais
  /// "dia"; o que vence hoje ainda dá para resolver; o que já foi pago é
  /// histórico e não disputa atenção com nada.
  ///
  /// "Atrasado" inclui o que venceu DENTRO desta semana e continua pendente:
  /// a quarta-feira que passou sem a conta paga é tão atraso quanto a da
  /// semana anterior. O que a semana anterior tem de diferente é o direito de
  /// enfurecer o monstro — não o lugar na lista.
  static int _commitmentOrder(ArenaCommitment a, ArenaCommitment b) {
    int rank(ArenaCommitment c) {
      if (c.isPaid) return 3;
      if (c.isBehind) return 0;
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
