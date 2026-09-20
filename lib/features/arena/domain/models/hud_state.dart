import 'package:flutter/foundation.dart';
import 'package:funances/core/money/money.dart';

/// Os quatro ícones do rodapé da Arena, em ordem de leitura.
///
/// A ordem não é alfabética nem arbitrária: começa no que você GUARDOU
/// (poção), passa pelo que você PLANEJOU (vila) e termina no que você DEVE
/// (ovo e gota). É a mesma ordem da conversa que um extrato provoca.
enum HudSlot { potion, village, egg, drop }

/// De onde saiu a receita prevista do mês.
///
/// `planned` é o que o usuário AGENDOU; `average` é a média dos três meses
/// anteriores, usada só quando não há nada agendado. A diferença importa na
/// folha: um denominador que veio de média merece a ressalva de que é
/// estimativa.
enum ExpectedIncomeSource { planned, average }

/// `workspaces/{w}.expectedIncome`, o denominador comum das três razões.
///
/// O app **lê** e nunca recalcula: duas implementações da mesma regra
/// divergem, e já divergiram duas vezes neste produto (a fatura e o
/// arredondamento de dinheiro). Ver `functions/README.md`, "HUD mensal".
///
/// A ausência deste objeto — e não um valor zero — é como o servidor escreve
/// "ainda não sei".
@immutable
class ExpectedIncome {
  const ExpectedIncome({
    required this.monthKey,
    required this.amount,
    required this.source,
    this.updatedAt,
  });

  final String monthKey;
  final Money amount;
  final ExpectedIncomeSource source;
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) =>
      other is ExpectedIncome &&
      other.monthKey == monthKey &&
      other.amount == amount &&
      other.source == source &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(monthKey, amount, source, updatedAt);
}

/// A classe de TAMANHO de uma razão. A mesma escala nos três ícones.
///
/// Ela mede tamanho, não virtude: uma poção hiper é ótima, um ovo hiper é
/// assustador e uma gota hiper é grave. Quem carrega o julgamento é a mini
/// explicação de cada folha, nunca o nome da classe.
///
/// `superTier` se chama assim porque `super` é palavra reservada em Dart. O
/// nome que o usuário lê sai do l10n.
enum HudTier { none, semi, regular, superTier, hyper }

/// Uma razão `valor ÷ receita prevista`, com a classe já decidida.
///
/// [income] nulo é "o servidor ainda não sabe quanto você ganha" — e nesse
/// caso [value] e [tier] são nulos, não zero. Zero seria um veredito
/// ("você não guardou nada"), e um veredito não pode ser dado sobre um
/// denominador que não existe.
@immutable
class HudRatio {
  const HudRatio({required this.amount, required this.income});

  /// O numerador: saldo investido, soma das faturas, saldo devedor.
  final Money amount;

  /// O denominador. `null` = ainda não calculado.
  final Money? income;

  bool get isUnknown => income == null || income!.cents <= 0;

  /// Quantos meses de receita o valor vale. `null` quando não há
  /// denominador.
  double? get value {
    if (isUnknown) return null;
    final numerator = amount.cents < 0 ? 0 : amount.cents;
    return numerator / income!.cents;
  }

  /// A razão chegou a [numerator]/[denominator] da receita?
  ///
  /// A comparação não passa por `double`: `0,5 × 1.855.000` é exato em `int` e
  /// aproximado em ponto flutuante, e um valor exatamente no corte tem de cair
  /// do lado de cima — as faixas são fechadas à esquerda (`>=`).
  ///
  /// Sem denominador a resposta é `false`: "ainda não sei" não chega a corte
  /// nenhum.
  bool isAtLeast(int numerator, int denominator) {
    if (isUnknown) return false;

    final n = amount.cents < 0 ? 0 : amount.cents;
    return n * denominator >= income!.cents * numerator;
  }

  /// A classe, decidida em CENTAVOS INTEIROS.
  HudTier? get tier {
    if (isUnknown) return null;

    if (isAtLeast(2, 1)) return HudTier.hyper;
    if (isAtLeast(3, 2)) return HudTier.superTier;
    if (isAtLeast(1, 1)) return HudTier.regular;
    if (isAtLeast(1, 2)) return HudTier.semi;
    return HudTier.none;
  }

  /// O preenchimento do anel, de 0 a 1. Razão acima de 1 enche o anel — o
  /// anel mostra "quanto falta para um mês inteiro", e passado isso não há
  /// mais o que mostrar.
  double get fill {
    final v = value;
    if (v == null) return 0;
    return v.clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is HudRatio && other.amount == amount && other.income == income;

  @override
  int get hashCode => Object.hash(amount, income);
}

/// Um nome e um valor: a linha das contas de investimento na folha da poção
/// e a das categorias sem proteção na folha da vila.
@immutable
class HudLabeledAmount {
  const HudLabeledAmount({
    required this.id,
    required this.name,
    required this.amount,
    this.color,
    this.icon,
  });

  /// Id da conta ou da categoria — é por ele que o toque abre o detalhe.
  final String id;
  final String name;
  final Money amount;

  /// Cor da conta ou da categoria (`#RRGGBB`), quando ela tem uma.
  final String? color;

  /// Nome do ícone da categoria, quando ela tem um.
  final String? icon;

  @override
  bool operator ==(Object other) =>
      other is HudLabeledAmount &&
      other.id == id &&
      other.name == name &&
      other.amount == amount &&
      other.color == color &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(id, name, amount, color, icon);
}

/// A POÇÃO: o que está guardado em contas de investimento.
@immutable
class HudPotion {
  const HudPotion({required this.accounts, required this.ratio});

  /// Contas de investimento com saldo, da maior para a menor.
  final List<HudLabeledAmount> accounts;

  final HudRatio ratio;

  Money get total => ratio.amount;

  /// Há o que beber. Poção vazia fica opaca; poção com saldo fica verde.
  bool get isFilled => total.isPositive;

  @override
  bool operator ==(Object other) =>
      other is HudPotion &&
      listEquals(other.accounts, accounts) &&
      other.ratio == ratio;

  @override
  int get hashCode => Object.hash(Object.hashAll(accounts), ratio);
}

/// Um ALDEÃO: uma categoria de despesa com orçamento no mês.
@immutable
class HudVillager {
  const HudVillager({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.planned,
    required this.actual,
  });

  final String categoryId;
  final String name;
  final String icon;
  final String color;

  /// O orçamento do mês (`generalPlannedAmount`).
  final Money planned;

  /// O que já foi gasto.
  final Money actual;

  /// O HP: o que sobra do orçamento. Negativo quando estourou.
  Money get hp => planned - actual;

  /// Dentro do limite é `<=`, não `<`: gastar exatamente o planejado é o
  /// alvo, não uma falha por um centavo.
  bool get isAlive => actual <= planned;

  /// Quanto da barra ainda está cheia, de 0 a 1.
  double get hpRatio {
    if (planned.cents <= 0) return 0;
    return (hp.cents / planned.cents).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is HudVillager &&
      other.categoryId == categoryId &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.planned == planned &&
      other.actual == actual;

  @override
  int get hashCode =>
      Object.hash(categoryId, name, icon, color, planned, actual);
}

/// O retrato de um mês fechado (`workspaces/{w}/monthly_reports/{YYYY-MM}`).
///
/// Existe porque o XP é concedido uma vez e depois some dentro do total do
/// workspace: sem o retrato, a folha da vila não teria como mostrar o que
/// aconteceu em agosto.
@immutable
class HudMonthlyReport {
  const HudMonthlyReport({
    required this.monthKey,
    required this.villagersPlanned,
    required this.villagersAlive,
    required this.villageAlive,
    required this.xpAwarded,
  });

  final String monthKey;
  final int villagersPlanned;
  final int villagersAlive;
  final bool villageAlive;
  final int xpAwarded;

  @override
  bool operator ==(Object other) =>
      other is HudMonthlyReport &&
      other.monthKey == monthKey &&
      other.villagersPlanned == villagersPlanned &&
      other.villagersAlive == villagersAlive &&
      other.villageAlive == villageAlive &&
      other.xpAwarded == xpAwarded;

  @override
  int get hashCode => Object.hash(
    monthKey,
    villagersPlanned,
    villagersAlive,
    villageAlive,
    xpAwarded,
  );
}

/// XP por aldeão vivo no fechamento do mês (`config/badges.xpSources`).
const int hudVillagerXp = 15;

/// Teto de aldeões pagos. Sem ele, o caminho mais curto para o XP seria
/// fatiar o orçamento em trinta categorias de R$ 10 e não gastar em nenhuma.
const int hudVillagerXpCap = 10;

/// XP pela vila inteira viva.
const int hudVillageXp = 100;

/// Mínimo de aldeões para a vila valer. "A soma ficou abaixo da soma" é uma
/// afirmação forte com um plano de verdade e uma banalidade com uma
/// categoria só.
const int hudVillageMinimum = 3;

/// A VILA: as categorias com orçamento no mês corrente.
@immutable
class HudVillage {
  const HudVillage({
    required this.villagers,
    required this.unprotected,
    required this.history,
  });

  /// Categorias de despesa com orçamento: os MORTOS primeiro (do mais fundo
  /// no vermelho) e, depois deles, os vivos do menor HP proporcional para o
  /// maior — quem está mais perto de cair aparece antes.
  final List<HudVillager> villagers;

  /// Categorias de despesa COM gasto e SEM orçamento. Elas não são aldeãs e
  /// não perdem nada: o jogo premia planejar de propósito, e tratar o não
  /// planejado como morte puniria justamente quem ainda não começou.
  final List<HudLabeledAmount> unprotected;

  /// Os meses já fechados, do mais recente para o mais antigo.
  final List<HudMonthlyReport> history;

  Money get plannedTotal => Money.sum(villagers.map((v) => v.planned));

  Money get actualTotal => Money.sum(villagers.map((v) => v.actual));

  int get aliveCount => villagers.where((v) => v.isAlive).length;

  int get plannedCount => villagers.length;

  /// A vila está de pé: a soma do realizado cabe na soma do planejado, com
  /// pelo menos [hudVillageMinimum] aldeões.
  bool get isAlive =>
      villagers.length >= hudVillageMinimum && actualTotal <= plannedTotal;

  /// O anel: Σ realizado ÷ Σ planejado, de 0 a 1.
  double get ring {
    if (plannedTotal.cents <= 0) return 0;
    return (actualTotal.cents / plannedTotal.cents).clamp(0.0, 1.0);
  }

  /// O mesmo quociente SEM teto — é ele que diz que a vila estourou.
  double? get progress {
    if (plannedTotal.cents <= 0) return null;
    return actualTotal.cents / plannedTotal.cents;
  }

  bool get isEmpty => villagers.isEmpty;

  /// O XP que o mês renderia se ele fechasse AGORA.
  ///
  /// É projeção, não promessa: quem paga é o cron do dia 1, sobre o mês
  /// inteiro. A folha diz isso com todas as letras.
  int get projectedXp {
    final pagos = aliveCount > hudVillagerXpCap ? hudVillagerXpCap : aliveCount;
    return pagos * hudVillagerXp + (isAlive ? hudVillageXp : 0);
  }

  @override
  bool operator ==(Object other) =>
      other is HudVillage &&
      listEquals(other.villagers, villagers) &&
      listEquals(other.unprotected, unprotected) &&
      listEquals(other.history, history);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(villagers),
    Object.hashAll(unprotected),
    Object.hashAll(history),
  );
}

/// Uma fatura por vir, do jeito que `accounts.nextInvoice` a descreve.
@immutable
class HudInvoice {
  const HudInvoice({
    required this.accountId,
    required this.name,
    required this.amount,
    required this.closingDate,
    required this.dueDate,
    this.color,
    this.isOpenCycle = false,
    this.installmentId,
    this.overdueDays = 0,
    this.limit,
    this.used = Money.zero,
  });

  final String accountId;
  final String name;
  final Money amount;
  final DateTime closingDate;
  final DateTime dueDate;
  final String? color;

  /// O limite do cartão (`accounts.limit`). `null` quando o usuário não
  /// informou nenhum.
  ///
  /// A ausência não vira zero, e a razão é a mesma do denominador das três
  /// razões: zero é um VEREDITO ("você não tem limite nenhum") e a ausência é
  /// "ainda não sei". Um cartão sem limite cadastrado desenhando 0% de uso
  /// diria ao usuário que ele tem o cartão inteiro livre justamente quando o
  /// app não faz ideia.
  final Money? limit;

  /// O limite JÁ COMPROMETIDO: o saldo do cartão em módulo, que é como a
  /// Visão Geral o calcula (`-balance`). Nunca negativo — um cartão pago
  /// adiantado não tem limite negativo em uso.
  final Money used;

  /// Quanto do limite já foi usado, de 0 a 1. `null` sem limite informado.
  double? get limitUsage {
    final total = limit;
    if (total == null || total.cents <= 0) return null;

    final usado = used.cents < 0 ? 0 : used.cents;
    return (usado / total.cents).clamp(0.0, 1.0);
  }

  /// O que ainda dá para gastar. `null` sem limite informado.
  Money? get availableLimit {
    final total = limit;
    if (total == null || total.cents <= 0) return null;

    final livre = total.cents - (used.cents < 0 ? 0 : used.cents);
    return Money.fromCents(livre < 0 ? 0 : livre);
  }

  /// Há quantos dias a fatura VENCEU. Zero enquanto ela não venceu.
  ///
  /// Ela continua entrando na soma do ovo — o contrato é `Σ nextInvoice`, e
  /// uma fatura vencida e não paga é a mais devida de todas. O que faltava
  /// era a MARCA: a do Nubank, vencida em 17/09, aparecia na folha com a
  /// mesma tinta discreta de uma que vence daqui a três semanas.
  final int overdueDays;

  bool get isOverdue => overdueDays > 0;

  /// O ciclo ainda está aberto: o valor é o acumulado até agora e ainda
  /// cresce. Fechado, ele é a cobrança definitiva.
  final bool isOpenCycle;

  /// A parcela da fatura, quando ela já existe. É por ela que a linha abre a
  /// tela de detalhe da fatura; sem ela, o destino é o extrato do cartão.
  final String? installmentId;

  @override
  bool operator ==(Object other) =>
      other is HudInvoice &&
      other.accountId == accountId &&
      other.name == name &&
      other.amount == amount &&
      other.closingDate == closingDate &&
      other.dueDate == dueDate &&
      other.color == color &&
      other.isOpenCycle == isOpenCycle &&
      other.installmentId == installmentId &&
      other.overdueDays == overdueDays &&
      other.limit == limit &&
      other.used == used;

  @override
  int get hashCode => Object.hash(
    accountId,
    name,
    amount,
    closingDate,
    dueDate,
    color,
    isOpenCycle,
    installmentId,
    overdueDays,
    limit,
    used,
  );
}

/// O OVO: as faturas dos próximos vencimentos.
@immutable
class HudEgg {
  const HudEgg({required this.invoices, required this.ratio});

  /// Faturas com as VENCIDAS primeiro e, depois delas, por vencimento.
  final List<HudInvoice> invoices;

  final HudRatio ratio;

  Money get total => ratio.amount;

  /// Três estágios de casca: liso, rachado e prestes a eclodir.
  ///
  /// Sem denominador o ovo não tem estágio nenhum — ele fica no primeiro, que
  /// é o neutro.
  ///
  /// Os cortes são em CENTAVOS INTEIROS, como as classes: um ovo de meio mês
  /// exato de receita rachava ou não conforme o erro de representação do
  /// `double` daquela divisão, e "a casca mudou porque o número tem dízima"
  /// não é uma regra que alguém possa explicar.
  int get stage {
    if (ratio.isAtLeast(1, 1)) return 2;
    if (ratio.isAtLeast(1, 2)) return 1;
    return 0;
  }

  /// O ovo treme quando a razão se aproxima de um mês inteiro de receita:
  /// quatro quintos dela.
  bool get isTrembling => ratio.isAtLeast(4, 5);

  bool get isEmpty => invoices.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is HudEgg &&
      listEquals(other.invoices, invoices) &&
      other.ratio == ratio;

  @override
  int get hashCode => Object.hash(Object.hashAll(invoices), ratio);
}

/// Uma conta de dívida: quanto ela ainda cobra.
@immutable
class HudDebt {
  const HudDebt({
    required this.accountId,
    required this.name,
    required this.balance,
    this.color,
    this.installment,
    this.nextDueDate,
  });

  final String accountId;
  final String name;

  /// Saldo DEVEDOR, em módulo: a conta guarda o número negativo, e "devo
  /// −R$ 7.623,68" não é uma frase.
  final Money balance;

  final String? color;

  /// A próxima parcela pendente desta dívida, quando existe.
  final Money? installment;

  final DateTime? nextDueDate;

  @override
  bool operator ==(Object other) =>
      other is HudDebt &&
      other.accountId == accountId &&
      other.name == name &&
      other.balance == balance &&
      other.color == color &&
      other.installment == installment &&
      other.nextDueDate == nextDueDate;

  @override
  int get hashCode =>
      Object.hash(accountId, name, balance, color, installment, nextDueDate);
}

/// A GOTA: o que você deve.
@immutable
class HudDrop {
  const HudDrop({required this.debts, required this.ratio});

  /// Dívidas da maior para a menor.
  final List<HudDebt> debts;

  final HudRatio ratio;

  Money get total => ratio.amount;

  /// A gota só pisca quando há dívida. Sem dívida ela fica parada e opaca —
  /// piscar num cofre sem dívida seria alarme sem incêndio.
  bool get isBlinking => total.isPositive;

  @override
  bool operator ==(Object other) =>
      other is HudDrop &&
      listEquals(other.debts, debts) &&
      other.ratio == ratio;

  @override
  int get hashCode => Object.hash(Object.hashAll(debts), ratio);
}

/// O rodapé inteiro: quatro leituras MENSAIS sob um embate semanal.
@immutable
class HudState {
  const HudState({
    required this.monthKey,
    required this.income,
    required this.potion,
    required this.village,
    required this.egg,
    required this.drop,
  });

  /// `YYYY-MM` do mês que o rodapé está lendo.
  final String monthKey;

  /// `null` = o servidor ainda não publicou a receita prevista **deste**
  /// mês. Os três ícones de razão ficam neutros; a vila não depende dela.
  ///
  /// Quando presente, `income.monthKey == monthKey` é invariante: quem monta
  /// o estado ([HudCalculator]) descarta a receita de outro mês.
  final ExpectedIncome? income;

  final HudPotion potion;
  final HudVillage village;
  final HudEgg egg;
  final HudDrop drop;

  bool get hasIncome => income != null;

  @override
  bool operator ==(Object other) =>
      other is HudState &&
      other.monthKey == monthKey &&
      other.income == income &&
      other.potion == potion &&
      other.village == village &&
      other.egg == egg &&
      other.drop == drop;

  @override
  int get hashCode => Object.hash(monthKey, income, potion, village, egg, drop);
}
