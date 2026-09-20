import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';

part 'arena_state.freezed.dart';

/// Aparência do herói de um membro.
///
/// Existe como enum — e não como índice de sprite — porque a customização por
/// usuário já tem lugar guardado: `users/{uid}.avatar`. Nesta POC o app **não
/// grava** nada lá; a skin é escolhida pela ordem de entrada no workspace
/// ([ArenaCalculator.skinForIndex]), e o dia em que o campo existir só o
/// `fromName` muda.
enum HeroSkin {
  knight,
  mage,
  ranger,
  warrior;

  static HeroSkin fromName(String? name) =>
      HeroSkin.values.where((skin) => skin.name == name).firstOrNull ??
      HeroSkin.knight;
}

/// Aparência — e nome — do monstro da semana.
///
/// Sorteada pelo id da semana, não pelo relógio: a mesma semana mostra o
/// mesmo bicho em todo aparelho e depois de todo recarregamento. Um
/// `Random()` sem semente trocaria o monstro a cada rebuild.
enum MonsterSkin { spider, bat, ghost, slime, demon }

/// Estado de ânimo do herói. Nunca existe "morto": o herói da Arena não morre.
enum HeroMood {
  /// Saldo acima de um terço do saldo de domingo.
  healthy,

  /// Saldo positivo, mas abaixo de um terço: pose machucada.
  hurt,

  /// **Pressionado**: o comprometido passou do caixa.
  ///
  /// A barra pode estar CHEIA e a situação ser a pior da semana — foi
  /// exatamente o que o retrato real mostrou: R$ 3.115,02 em caixa contra
  /// R$ 12.122,33 de compromisso, no domingo, com a barra intacta. Sem um
  /// estado próprio, a cena dizia "tudo bem" com um rombo de nove mil reais
  /// na frente.
  pressed,

  /// Saldo negativo. Filtro escuro.
  exhausted,
}

/// Um membro do workspace, na Arena.
@freezed
sealed class ArenaHero with _$ArenaHero {
  const factory ArenaHero({
    required String userId,
    required String name,
    required HeroSkin skin,
    String? photoUrl,
  }) = _ArenaHero;
}

/// Um compromisso agendado da semana — uma linha do monstro.
///
/// É a parcela do app com o que a cena precisa saber **já decidido**: se ela
/// está paga, se está atrasada e em quantos dias ela vence. A folha do
/// monstro lê daqui, e é daqui que sai o HP: nenhuma das duas reconta.
@freezed
sealed class ArenaCommitment with _$ArenaCommitment {
  const ArenaCommitment._();

  const factory ArenaCommitment({
    required InstallmentModel installment,

    /// Já quitado (`paid` ou `settled`).
    required bool isPaid,

    /// Pendente com vencimento ANTERIOR ao domingo desta semana.
    required bool isOverdue,

    /// Pago, mas com `paidDate` no FUTURO — um débito automático já marcado
    /// para sexta, por exemplo. O golpe está agendado; ele ainda não caiu.
    required bool isScheduledStrike,

    /// Dias de calendário até o vencimento, a partir de hoje. Negativo =
    /// venceu.
    required int daysUntilDue,
  }) = _ArenaCommitment;

  /// O PLANO: quanto este compromisso pesava quando a semana começou.
  ///
  /// A pergunta que decide é **quem cobrou**:
  ///
  /// - uma **FATURA** é uma cobrança de terceiro. O `amount` sobrevive à
  ///   quitação porque ele é o que o cartão cobrou, e pagar menos que isso
  ///   deixa dívida: R$ 12.130,09 cobrados com R$ 1.000 pagos continuam
  ///   devendo R$ 11.130,09. Aqui o plano é o `amount`;
  /// - uma **despesa comum** é um lançamento do próprio usuário. Se a conta
  ///   de água nasceu com R$ 400 previstos e foi quitada por R$ 347,42, a
  ///   conta ACABOU — o que sobrou não é dívida, é uma previsão que errou por
  ///   cima. Tratar o `amount` como cobrança aqui deixava um monstro fantasma
  ///   de R$ 52,58 de pé, para sempre.
  ///
  /// Fora da fatura vale o `referenceAmount` (`paidAmount ?? amount`), que
  /// responde as duas formas: pendente devolve o previsto, quitada devolve o
  /// que saiu — inclusive quando a quitação zera o `amount`, que é como o app
  /// grava a parcela comum.
  double get planned => installment.isInvoice && installment.amount > 0
      ? installment.amount
      : installment.referenceAmount;

  /// O que de fato saiu do caixa por este compromisso, HOJE.
  ///
  /// Preso ao [planned]: pagar a mais não tira do monstro mais do que ele
  /// tinha. O excedente vira [overpaid] e aparece na linha, não na barra.
  double get struck {
    if (isScheduledStrike) return 0;

    final paid = installment.paidAmount ?? (isPaid ? planned : 0);
    return paid > planned ? planned : paid;
  }

  /// O que ainda falta deste compromisso.
  double get remaining {
    final left = planned - struck;
    return left < 0 ? 0 : left;
  }

  /// Quanto passou do previsto. Aparece na linha como "+R$ x acima".
  double get overpaid {
    final paid = installment.paidAmount ?? 0;
    final over = paid - planned;
    return over > 0 ? over : 0;
  }

  /// Até quanto um resto conta como zero, em reais.
  ///
  /// Medido na base: de 73 faturas do cofre, TRÊS fecharam com dois a quatro
  /// centavos faltando (R$ 3.942,04 cobrados, R$ 3.942,00 pagos). É o
  /// arredondamento do banco, não uma dívida — e com "resto exatamente zero"
  /// essas semanas terminariam com o monstro vivo em quatro centavos, para
  /// sempre, sem vitória nenhuma.
  ///
  /// Cinco centavos é o maior resíduo que o histórico mostra, com folga de
  /// um. O valor em reais continua EXATO nas somas: o que a tolerância muda é
  /// só a leitura de "isto acabou".
  static const double residueTolerance = 0.05;

  /// O resto que sobrou de um compromisso já dado por quitado. Zero quando
  /// ele fechou redondo.
  double get residue => isStruck ? remaining : 0;

  /// Houve pagamento, mas ele não cobriu o compromisso — de verdade, e não
  /// por causa de centavos.
  bool get isPartial => struck > 0 && remaining > residueTolerance;

  /// O golpe caiu POR INTEIRO: nada relevante falta deste compromisso.
  ///
  /// É o que conta como linha resolvida. Um pagamento marcado para sexta não
  /// desconta hoje — senão o monstro nasceria abatido no domingo, com a
  /// semana inteira de débitos automáticos já descontada antes de qualquer um
  /// deles sair da conta.
  bool get isStruck =>
      !isScheduledStrike && remaining <= residueTolerance && planned > 0;

  /// Pendente e já vencida DENTRO desta semana. Não enfurece o monstro (isso
  /// é privilégio do atraso de semanas anteriores), mas sobe para o topo da
  /// folha com o mesmo destaque: é o que já devia ter sido resolvido.
  bool get isLate => !isStruck && !isOverdue && daysUntilDue < 0;

  /// Atrasado de qualquer origem — de semanas passadas ou desta.
  bool get isBehind => isOverdue || isLate;

  bool get isDueToday => !isStruck && !isBehind && daysUntilDue == 0;
  bool get isDueTomorrow => !isStruck && !isBehind && daysUntilDue == 1;

  /// O "próximo golpe": o que vence hoje ou amanhã. É a `DueSoonStrip` da
  /// Home antiga, agora dentro do monstro.
  bool get isNextBlow => isDueToday || isDueTomorrow;
}

/// Quanto a semana já andou. É o "relógio" do centro do HUD — o cronômetro
/// que separa as duas barras.
enum ArenaDay {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday;

  /// 1..7 — o "3/7" que o marcador central mostra.
  int get ordinal => index + 1;

  /// Quantos dias ainda restam, contando o de hoje.
  int get daysLeft => 7 - index;
}

/// Um saldo de conta, do domingo até agora. É a linha do detalhe dos heróis.
@freezed
sealed class ArenaAccountLife with _$ArenaAccountLife {
  const ArenaAccountLife._();

  const factory ArenaAccountLife({
    required String accountId,
    required String name,

    /// Saldo no início da semana: o último documento de `balance` com data
    /// ANTERIOR ao domingo. Conta que não existia ainda vale zero.
    required double initial,

    /// Saldo agora: o último documento de `balance`.
    required double current,
  }) = _ArenaAccountLife;

  double get delta => current - initial;
}

/// Um evento que a cena ainda não mostrou.
///
/// Guardado em memória (no provider) porque o gasto acontece no formulário de
/// lançamento, não na Home: quando o usuário volta, a cena consome isto e
/// anima. Sem o adiamento, o dano tocava numa tela que ninguém estava vendo.
@freezed
sealed class ArenaPendingEvent with _$ArenaPendingEvent {
  const factory ArenaPendingEvent({
    /// Despesa lançada: fere os heróis, porque o saldo é o HP.
    @Default(0) double damage,

    /// Receita recebida: cura.
    @Default(0) double healed,
  }) = _ArenaPendingEvent;
}

/// Tudo o que a cena precisa saber, já calculado.
///
/// **Só leitura.** Nenhum campo daqui nasce de uma escrita nova no Firestore:
/// são as contas, os saldos por dia, as parcelas e os membros que o app já
/// observa, recombinados. A única escrita que a Arena provoca é a de quitar
/// um compromisso, e essa passa pelo caminho que já existia
/// (`TransactionPaymentSheet`).
///
/// ## O que a Arena é — e o que ela não é
///
/// A Arena é o **desafio da semana**: heróis contra o monstro dos
/// compromissos agendados. Só isso. Categorias, cartões e investimentos terão
/// visualizações próprias; tentar caber os três aqui foi o que fez a primeira
/// POC ter duas fontes de HP numa barra só e um casulo competindo com o
/// monstro pela atenção.
@freezed
sealed class ArenaState with _$ArenaState {
  const ArenaState._();

  const factory ArenaState({
    /// `YYYY-Www` — a semana do servidor.
    required String weekId,

    /// Em que dia da semana estamos. O marcador central do HUD.
    required ArenaDay day,

    // ── Heróis ─────────────────────────────────────────────────────────────
    /// Caixa no DOMINGO 00:00: soma dos últimos saldos anteriores ao domingo
    /// das contas líquidas (corrente + investimento). É o HP MÁXIMO.
    required double initialBalance,

    /// Caixa AGORA: soma dos últimos saldos das mesmas contas. É o HP ATUAL.
    required double currentBalance,

    /// As contas que compõem os dois números, para o detalhe.
    @Default(<ArenaAccountLife>[]) List<ArenaAccountLife> accounts,

    /// Receitas recebidas na semana. É a CURA — e é o que pode fazer o atual
    /// passar do inicial.
    required double healedThisWeek,

    // ── Monstro ────────────────────────────────────────────────────────────
    /// TODOS os compromissos agendados da semana (pagos e pendentes) mais o
    /// atraso das semanas anteriores, já ordenados para a folha.
    @Default(<ArenaCommitment>[]) List<ArenaCommitment> commitments,

    /// Soma de tudo o que a semana tinha para pagar. HP INICIAL do monstro.
    required double commitmentsInitial,

    /// O que ainda falta pagar. HP ATUAL do monstro.
    required double commitmentsRemaining,

    /// O que está atrasado de semanas anteriores. Enfurece e vira cicatriz.
    required double overdueAmount,

    required MonsterSkin monsterSkin,

    // ── Elenco ─────────────────────────────────────────────────────────────
    @Default(<ArenaHero>[]) List<ArenaHero> heroes,

    /// Membros além dos dois que viram herói. Vira um contador na cena.
    @Default(0) int extraMembers,

    /// XP da semana, do `weekly_xp` do servidor. Só alimenta as moedas.
    @Default(0) double weeklyXp,
  }) = _ArenaState;

  // ── Monstro ──────────────────────────────────────────────────────────────

  /// Vida do monstro agora: o que ainda falta sair do caixa.
  double get monsterHp => commitmentsRemaining;

  /// Vida do monstro no início da semana.
  double get monsterMaxHp => commitmentsInitial;

  double get monsterHpRatio => monsterMaxHp <= 0
      ? 0
      : (monsterHp / monsterMaxHp).clamp(0.0, 1.0).toDouble();

  /// Já pago da semana. O tamanho da mordida acumulada.
  double get paidSoFar => monsterMaxHp - monsterHp;

  bool get isEnraged => overdueAmount > 0;

  /// O monstro morre quando TODA linha caiu.
  ///
  /// Linha a linha, e não pelo total: "caiu" tolera o resíduo de centavos
  /// (ver [ArenaCommitment.residueTolerance]), e um total com quatro centavos
  /// de arredondamento manteria o bicho vivo para sempre. O número da barra
  /// continua exato — o que a tolerância decide é quando a luta acabou, não
  /// quanto ela custou.
  bool get isDefeated {
    if (commitmentsInitial <= 0) return false;
    if (commitments.isEmpty) return commitmentsRemaining <= 0;

    return commitments.every((c) => c.isStruck);
  }

  /// Centavos de arredondamento que sobraram numa semana vencida.
  double get residue =>
      commitments.fold<double>(0, (total, c) => total + c.residue);

  List<ArenaCommitment> get pendingCommitments =>
      commitments.where((c) => !c.isStruck).toList();

  List<ArenaCommitment> get paidCommitments =>
      commitments.where((c) => c.isStruck).toList();

  /// O compromisso pendente que mais pesa. É a CAUSA que o rombo explica.
  ArenaCommitment? get largestPending {
    final pendentes = pendingCommitments;
    if (pendentes.isEmpty) return null;

    return pendentes.reduce((a, b) => b.remaining > a.remaining ? b : a);
  }

  /// Golpes marcados para um dia que ainda não chegou.
  List<ArenaCommitment> get scheduledStrikes =>
      commitments.where((c) => c.isScheduledStrike).toList();

  /// Quantos compromissos já foram resolvidos, de quantos. É o placar da
  /// semana — e o que o fechamento mostra na virada.
  int get struckCount => commitments.where((c) => c.isStruck).length;

  /// Compromissos com pagamento parcial: já levaram golpe, mas continuam de
  /// pé.
  List<ArenaCommitment> get partialCommitments =>
      commitments.where((c) => c.isPartial).toList();

  int get commitmentsCount => commitments.length;

  /// O que vence hoje ou amanhã. Era a `DueSoonStrip` da Home.
  List<ArenaCommitment> get nextBlow =>
      commitments.where((c) => c.isNextBlow).toList();

  // ── Heróis ───────────────────────────────────────────────────────────────

  /// O que ainda está comprometido — a faixa hachurada da barra dos heróis.
  ///
  /// É o MESMO número da vida do monstro, de propósito: o que mantém o
  /// monstro em pé é exatamente o que os heróis ainda não podem gastar.
  double get committed => monsterHp;

  /// O caixa realmente livre: o que tem menos o que já tem dono. Era o
  /// "quanto sobra" do cabeçalho da Jornada.
  double get freeBalance => currentBalance - committed;

  /// A vida dos heróis: **dinheiro POSITIVO em conta**.
  ///
  /// Decisão do dono, e ela resolve um defeito que o QA já tinha visto sem
  /// saber nomear: *"HP do herói = dinheiro positivo em conta; barra = saldo
  /// início da semana (max) / saldo atual"*.
  ///
  /// A conta antiga era `atual / inicial`, e ela tem um buraco: com os DOIS
  /// negativos — o rombo real do cofre, R\$ −6.361,92 no domingo e os mesmos
  /// R\$ −6.361,92 hoje — a divisão dá **1**, e a tela mostrava a barra
  /// CHEIA para quem está no vermelho. Dois números negativos se cancelavam
  /// numa boa notícia.
  ///
  /// Devendo não se tem vida: abaixo de zero o HP é zero, e não um número
  /// negativo que a divisão pudesse "consertar" com outro negativo.
  double get heroHp => math.max(0.0, currentBalance);

  /// A régua da barra: o caixa de DOMINGO, também sem parte negativa.
  ///
  /// `math.max` com o HP de hoje no fim é o que impede a barra de passar de
  /// 100%: quem começou a semana devendo e virou o caixa tem régua zero, e
  /// uma barra de 50 sobre 0 não é infinita — é cheia.
  double get heroMaxHp => math.max(math.max(0.0, initialBalance), heroHp);

  /// Fração cheia da barra dos heróis.
  ///
  /// A régua é o início da semana, e não o saldo de hoje: é o que faz a barra
  /// **encolher** quando se gasta, em vez de continuar cheia com um número
  /// menor ao lado.
  ///
  /// Sem régua (semana que começou em zero ou no vermelho) e sem caixa hoje,
  /// a barra fica VAZIA. É a resposta honesta: não há vida para medir, e quem
  /// diz o tamanho do buraco é o selo, que traz o número.
  double get heroHpRatio =>
      heroMaxHp <= 0 ? 0 : (heroHp / heroMaxHp).clamp(0.0, 1.0).toDouble();

  /// Passou do saldo de domingo: entrou mais dinheiro do que saiu.
  bool get isOverhealed => currentBalance > initialBalance;

  /// Quanto passou. É o que o rótulo verde do transbordo mostra.
  double get overheal => isOverhealed ? currentBalance - initialBalance : 0;

  /// Fração comprometida (hachurada), na mesma régua da barra.
  ///
  /// **Nunca passa da vida que existe.** A hachura é a parte do que se TEM
  /// que já tem dono, e ela é desenhada a partir da ponta cheia da barra: com
  /// a barra vazia e a hachura em 100%, a tela mostrava uma faixa vermelha de
  /// ponta a ponta que o olho lê como vida CHEIA.
  ///
  /// Era o retrato real do cofre no dia do QA — caixa em −R\$ 6.361,92, barra
  /// em zero — e a Arena dizia que estava tudo no lugar. Uma barra vazia é
  /// uma barra vazia; quem conta o tamanho do buraco é o selo, que traz o
  /// número.
  ///
  /// O `min` com [heroHpRatio] no fim é o que faz a hachura SUMIR quando o
  /// HP é zero: hachura é a parte do que se TEM que já tem dono, e quem não
  /// tem nada não tem o que reservar.
  double get committedRatio {
    final bruta = initialBalance <= 0
        ? (committed > 0 ? 1.0 : 0.0)
        : (committed / initialBalance).clamp(0.0, 1.0).toDouble();

    return math.min(bruta, heroHpRatio);
  }

  /// O caixa não cobre o que a semana já deve.
  bool get isPressed => committed > currentBalance;

  /// Quanto falta em caixa para cobrir os compromissos. Zero quando cobre.
  double get shortfall {
    final falta = committed - currentBalance;
    return falta > 0 ? falta : 0;
  }

  HeroMood get heroMood {
    if (currentBalance < 0) return HeroMood.exhausted;
    // O rombo vem ANTES do "machucado": ter pouco do que se tinha é ruim;
    // dever mais do que se tem é outra categoria de problema.
    if (isPressed) return HeroMood.pressed;
    if (heroHpRatio < 1 / 3) return HeroMood.hurt;
    return HeroMood.healthy;
  }

  /// Não há nada para mostrar: sem compromisso e sem caixa.
  bool get isEmpty =>
      commitmentsInitial <= 0 && currentBalance == 0 && initialBalance == 0;
}
