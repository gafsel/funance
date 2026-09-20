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

/// Aparência do monstro da semana.
///
/// Sorteada pelo id da semana, não pelo relógio: a mesma semana mostra o
/// mesmo bicho em todo aparelho e depois de todo recarregamento. Um
/// `Random()` sem semente trocaria o monstro a cada rebuild.
enum MonsterSkin { spider, bat, ghost, slime, demon }

/// Estado de ânimo do herói. Nunca existe "morto": o herói da Arena não morre.
enum HeroMood {
  /// Vida acima de um terço.
  healthy,

  /// Vida positiva, mas abaixo de um terço: pose machucada.
  hurt,

  /// Vida negativa — mais comprometido do que disponível. Filtro escuro.
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

/// Tudo o que a cena precisa saber, já calculado.
///
/// **Só leitura.** Nenhum campo daqui nasce de uma escrita nova no Firestore:
/// são as contas, as parcelas, o `period_summaries` da semana e os membros
/// que o app já observa, recombinados. A única escrita que a Arena provoca é
/// a de quitar uma parcela, e essa passa pelo caminho que já existia
/// (`TransactionPaymentSheet`).
@freezed
sealed class ArenaState with _$ArenaState {
  const ArenaState._();

  const factory ArenaState({
    /// `YYYY-Www` — a semana do servidor.
    required String weekId,

    // ── Herói ──────────────────────────────────────────────────────────────
    /// Dinheiro nas contas líquidas: corrente + investimento (a "poupança"
    /// deste modelo de dados). Cartão e dívida ficam de fora — o que está no
    /// cartão ainda não saiu, e dívida não é caixa.
    required double liquidBalance,

    /// Receitas recebidas na semana. É a CURA.
    required double healedThisWeek,

    /// Gasto fora do plano, ou acima do limite da categoria. É o DANO.
    required double damageThisWeek,

    // ── Monstro ────────────────────────────────────────────────────────────
    /// Parcelas de despesa da semana (pagas + pendentes) somadas ao atraso.
    required double installmentsInitial,

    /// O que dessas parcelas ainda não foi pago.
    required double installmentsRemaining,

    /// Rateio semanal dos limites planejados, como o servidor o agregou.
    required double budgetInitial,

    /// Quanto do orçamento da semana ainda não foi gasto.
    required double budgetRemaining,

    /// Parcelas pendentes vencidas ANTES desta semana. Deixam o monstro
    /// enfurecido e viram a cicatriz "+R$ X atrasado".
    required double overdueAmount,

    required MonsterSkin monsterSkin,

    // ── Elenco e cenário ───────────────────────────────────────────────────
    @Default(<ArenaHero>[]) List<ArenaHero> heroes,

    /// Membros além dos dois que viram herói. Vira um contador na cena.
    @Default(0) int extraMembers,

    /// XP da semana, do `weekly_xp` do servidor. Só alimenta as moedas.
    @Default(0) double weeklyXp,

    /// Fatura aberta do cartão principal — o casulo. `null` = sem cartão, ou
    /// resumo ainda não gravado pelo servidor.
    double? invoiceAmount,

    /// Id da parcela da fatura, para o toque no casulo abrir `/invoices/{id}`.
    String? invoiceInstallmentId,

    /// As parcelas de despesa da semana ainda PENDENTES, na ordem de
    /// vencimento. É o que a folha do monstro lista.
    @Default(<InstallmentModel>[]) List<InstallmentModel> pendingInstallments,
  }) = _ArenaState;

  /// Vida do monstro agora.
  double get monsterHp => installmentsRemaining + budgetRemaining;

  /// Vida do monstro no início da semana.
  double get monsterMaxHp => installmentsInitial + budgetInitial;

  /// O que ainda está comprometido — a faixa hachurada da barra do herói.
  ///
  /// É o MESMO número da vida do monstro, de propósito: o que mantém o
  /// monstro em pé é exatamente o que o herói ainda não pode gastar.
  double get committed => monsterHp;

  /// Vida do herói: caixa livre. Pode ser negativa.
  double get heroHp => liquidBalance - committed;

  /// Fração cheia da barra do herói, para desenho. 0..1.
  double get heroHpRatio => liquidBalance <= 0
      ? 0
      : (heroHp / liquidBalance).clamp(0.0, 1.0).toDouble();

  /// Fração comprometida (hachurada) da barra do herói. 0..1.
  double get committedRatio => liquidBalance <= 0
      ? (committed > 0 ? 1 : 0)
      : (committed / liquidBalance).clamp(0.0, 1.0).toDouble();

  double get monsterHpRatio => monsterMaxHp <= 0
      ? 0
      : (monsterHp / monsterMaxHp).clamp(0.0, 1.0).toDouble();

  bool get isEnraged => overdueAmount > 0;

  /// O monstro foge quando as PARCELAS da semana acabaram. Orçamento não
  /// gasto não o mantém em pé — sobra do planejado é mérito, não inimigo.
  bool get hasFled => installmentsInitial > 0 && installmentsRemaining <= 0;

  HeroMood get heroMood {
    if (heroHp < 0) return HeroMood.exhausted;
    if (heroHpRatio < 1 / 3) return HeroMood.hurt;
    return HeroMood.healthy;
  }

  /// Não há nada para mostrar: sem parcelas, sem orçamento e sem caixa.
  bool get isEmpty => monsterMaxHp <= 0 && liquidBalance <= 0;
}
