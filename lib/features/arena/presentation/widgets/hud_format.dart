/// Como o rodapé mensal NOMEIA e TINGE o que a conta já decidiu.
///
/// Existe porque as mesmas quatro decisões estavam escritas duas vezes — uma
/// na faixa, outra nas folhas — e as duas cópias já tinham divergido: a faixa
/// mostrava "0,0×" onde a folha mostrava "R$ 263,41", e a classe que era só da
/// poção aparecia também no ovo e na gota. Duas implementações da mesma regra
/// divergem; é a mesma lição que tirou o cálculo da receita prevista do
/// cliente.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/l10n/app_localizations.dart';

/// A tinta do anel da vila: verde enquanto cabe, laranja perto do limite,
/// vermelho quando estourou.
///
/// A vila é o único dos quatro em que o anel JULGA, e ela pode: o limite é o
/// que o próprio usuário escreveu. Nos outros três o anel só mede tamanho.
Color hudVillageColor(HudVillage village) {
  if (village.isEmpty) return AppColors.inkInverse2;

  final progress = village.progress ?? 0;
  if (progress > 1) return AppColors.danger;
  if (progress >= 0.9) return AppColors.warning;
  return AppColors.success;
}

/// A tinta do ANEL do ovo: do verde ao vermelho conforme a razão se aproxima
/// de um mês inteiro de receita.
///
/// Só o anel. A casca do ovo é verde sempre — ovo e anel foram separados de
/// propósito, e um ovo que muda de cor com a razão perderia a única coisa que
/// o identifica a 30 px.
Color hudEggRingColor(HudEgg egg) {
  if (egg.ratio.isUnknown) return AppColors.inkInverse2;
  if (egg.ratio.isAtLeast(1, 1)) return AppColors.danger;
  if (egg.ratio.isAtLeast(1, 2)) return AppColors.warning;
  return AppColors.success;
}

/// A classe, por extenso — e ela é da POÇÃO, só.
///
/// O dono definiu "gole/semi/regular/super/hiper" falando do que se GUARDA, e
/// é lá que as palavras ficam. Chamar de "gole" um ovo de R$ 20.187,80 em
/// faturas dizia ao usuário que ele tem pouco de uma coisa boa. O ovo e a gota
/// mostram a razão crua; quem julga neles é a cor e a mini explicação.
///
/// Sem denominador, um traço — nunca "gole", que seria um veredito sobre um
/// número que não existe.
String hudTierLabel(AppLocalizations l10n, HudRatio ratio) {
  return switch (ratio.tier) {
    null => l10n.hudUnknown,
    HudTier.none => l10n.hudTierNone,
    HudTier.semi => l10n.hudTierSemi,
    HudTier.regular => l10n.hudTierRegular,
    HudTier.superTier => l10n.hudTierSuper,
    HudTier.hyper => l10n.hudTierHyper,
  };
}

/// A razão com UMA casa decimal, sem o "×": `0,4`, `1,1`, `< 0,1`.
///
/// Uma casa e não duas: o rodapé responde "isto é grande?", e a segunda casa
/// decimal não muda a resposta. Os centavos exatos estão na folha.
///
/// **O `< 0,1` não é preciosismo.** R$ 263,41 guardados sobre R$ 18.550,00 dão
/// 0,0142, que `toStringAsFixed(1)` escreve como "0,0" — e "0,0×" ao lado de
/// uma poção que TEM saldo é a faixa dizendo que não há nada ali. Zero é uma
/// afirmação, e ela só pode ser feita quando o numerador é zero de verdade.
///
/// `null` quando não há denominador.
String? hudRatioValue(HudRatio ratio, String locale) {
  final value = ratio.value;
  if (value == null) return null;

  final text = value.toStringAsFixed(1);
  final decimal = locale.startsWith('en') ? text : text.replaceAll('.', ',');

  // A comparação é com o TEXTO já arredondado, e não com um limiar de 0,05
  // escrito à mão: quem decide se saiu "0,0" é o mesmo arredondamento que vai
  // para a tela, e não uma segunda regra que pode discordar dele.
  if (value > 0 && double.parse(text) == 0) {
    return '< ${locale.startsWith('en') ? '0.1' : '0,1'}';
  }

  return decimal;
}

/// A razão como a faixa a mostra: "1,1×", "< 0,1×" ou o traço.
String hudRatioLabel(AppLocalizations l10n, HudRatio ratio, String locale) {
  final value = hudRatioValue(ratio, locale);
  if (value == null) return l10n.hudUnknown;

  return l10n.hudRatioTimes(value);
}

/// A frase da folha: "0,4× da receita prevista do mês (R$ 18.550,00)".
///
/// `null` sem denominador — a folha troca a frase pelo aviso âmbar.
String? hudRatioOfIncome(AppLocalizations l10n, HudRatio ratio, String locale) {
  final value = hudRatioValue(ratio, locale);
  final income = ratio.income;
  if (value == null || income == null) return null;

  return l10n.hudRatioOfIncome(value, income.format(locale: locale));
}

/// O valor COMPACTO de um aldeão: "R$ 1,5 mil" em vez de "R$ 1.462,77".
///
/// A grade da vila põe dezoito valores lado a lado em tiles de setenta e
/// poucos pixels, e "R$ 1.462,77" em `labelSmall` não cabe em nenhum deles —
/// ou sai cortado no meio ("R$ 1.46…"), que é pior do que arredondar: um
/// número truncado parece um número. A pergunta que a grade responde é
/// "quanto falta?", e para ela a ordem de grandeza basta; os centavos exatos
/// estão a um toque, na tela de planejamento.
///
/// `compactSimpleCurrency` e não um `toStringAsFixed` com sufixo à mão: "mil"
/// em português e "K" em inglês são decisão de LOCALE, e escrevê-la no código
/// seria traduzir na mão o que o `intl` já traduz.
String hudCompactMoney(Money value, String locale) =>
    NumberFormat.compactSimpleCurrency(locale: locale).format(value.toDouble());

// ── A semântica: o que a COR diz, em palavras ────────────────────────────────
//
// Quem lê a faixa com leitor de tela recebia "Ovo: 1,1×" — o número, e nada
// do julgamento. E o julgamento é justamente a parte que a faixa entrega sem
// texto: o anel vermelho, o ovo rachado, a gota piscando. Um usuário cego
// ouvia o dado e perdia a leitura.
//
// Cada uma destas devolve o par que o rótulo de acessibilidade usa: o VALOR
// (o número, dito por extenso) e o ESTADO (o que a cor comunica).

/// "R$ 263,41" + "gole".
({String value, String state}) hudPotionSemantics(
  AppLocalizations l10n,
  HudPotion potion,
  String locale,
) => (
  value: potion.total.format(locale: locale),
  state: !potion.isFilled
      ? l10n.hudSemanticsPotionEmpty
      : potion.ratio.isUnknown
      ? l10n.hudSemanticsNoIncome
      : hudTierLabel(l10n, potion.ratio),
);

/// "13 de 18 aldeões vivos" + "vila viva".
({String value, String state}) hudVillageSemantics(
  AppLocalizations l10n,
  HudVillage village,
) => (
  value: l10n.hudSemanticsVillagers(village.aliveCount, village.plannedCount),
  state: village.isEmpty
      ? l10n.hudSemanticsVillageNone
      : village.plannedCount < hudVillageMinimum
      ? l10n.hudSemanticsVillageNeedsThree
      : village.isAlive
      ? l10n.hudSemanticsVillageAlive
      : l10n.hudSemanticsVillageFallen,
);

/// "1,1× da receita" + "faturas acima da receita, perigo".
///
/// Sem denominador o valor é o TOTAL em dinheiro, e não o traço: "R$
/// 20.187,80, receita prevista ainda não calculada" diz as duas coisas que o
/// usuário precisa ouvir; um traço não diz nenhuma.
({String value, String state}) hudEggSemantics(
  AppLocalizations l10n,
  HudEgg egg,
  String locale,
) => (
  value: _ratioOrTotal(l10n, egg.ratio, locale),
  state: egg.isEmpty
      ? l10n.hudSemanticsEggEmpty
      : egg.ratio.isUnknown
      ? l10n.hudSemanticsNoIncome
      : egg.ratio.isAtLeast(1, 1)
      ? l10n.hudSemanticsEggDanger
      : egg.ratio.isAtLeast(1, 2)
      ? l10n.hudSemanticsEggWarning
      : l10n.hudSemanticsEggCalm,
);

/// "0,4× da receita" + "dívida ativa".
({String value, String state}) hudDropSemantics(
  AppLocalizations l10n,
  HudDrop drop,
  String locale,
) => (
  value: _ratioOrTotal(l10n, drop.ratio, locale),
  state: drop.total.isPositive
      ? l10n.hudSemanticsDropActive
      : l10n.hudSemanticsDropClear,
);

String _ratioOrTotal(AppLocalizations l10n, HudRatio ratio, String locale) {
  final value = hudRatioValue(ratio, locale);
  if (value == null) return ratio.amount.format(locale: locale);

  return l10n.hudSemanticsRatio(value);
}
