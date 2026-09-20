import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/arena/presentation/widgets/arena_home_block.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_strip_view.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';

/// A Home.
///
/// A ordem dos blocos é a decisão principal desta tela, e ela mudou por
/// inteiro depois do teste do APK. Antes a Home abria pelo cabeçalho do cofre
/// — nome, tipo e nível, os três já escritos na `AppBar` logo acima — e
/// seguia com a Bússola, o coaching em cartão de 120px, as missões, a Party e
/// a lista COMPLETA de metas. Quem abria o app via primeiro o que não muda: o
/// nível muda uma vez por mês, a Bússola uma vez por mês, a meta em meses.
///
/// A ordem nova segue uma pergunta só — "o que eu preciso saber AGORA?":
///
/// 1. **a conquista do momento.** Não é um bloco: ela chega por cima, no
///    `CelebrationHost`, de qualquer tela. Reservar altura fixa para algo que
///    aparece uma vez por semana era o erro que a Home antiga cometia com o
///    nível;
/// 2. **o desafio da semana** — a Arena. Ela tomou o lugar de DOIS blocos:
///    o cabeçalho "quanto sobra" e a faixa de "vence hoje e amanhã". Os dois
///    respondiam à mesma pergunta em texto ("tenho dinheiro?" e "o que
///    aperta?"), e a Arena responde às duas de uma vez, em duas barras que se
///    opõem: a dos heróis é o saldo das contas, a do monstro é o que a semana
///    ainda deve. O número do cabeçalho antigo continua existindo — virou a
///    linha "livre" do detalhe das contas —, e a lista de vencimentos virou
///    o "próximo golpe" do detalhe do monstro;
/// 3. **as pendências do leitor de notificação**, quando existem: coisas que
///    expiram;
/// 4. **as missões da semana**, em resumo e com UM botão — o da missão em
///    foco. O detalhe da semana (cartões, XP e checklist) abre em
///    `/missions`;
/// 5. **o empurrão** — o coaching, em UMA linha. Decisão de produto: o nudge
///    de "gasto fora do plano" NÃO vira bloco de Home. Ele é reação a uma
///    decisão que a pessoa acabou de tomar, e fica na folha que aparece
///    depois do lançamento — ali, com o valor na tela e o dedo no aparelho,
///    ele pode virar correção; repetido aqui no dia seguinte, vira boletim
///    sobre algo que já passou. Ver README, "Decisões de produto da Home";
/// 6. **a linha da Bússola** — número, patente e variação;
/// 7. **uma meta em destaque**, a de prazo mais curto — em uma linha, com o
///    nome do bloco dispensado: a linha já diz que é uma meta, e `/goals`
///    tem o cartão completo.
///
/// O que saiu: o cabeçalho duplicado do cofre (a identidade mora na `AppBar`),
/// a lista inteira de metas (foi para `/goals`) e a Party (foi para a Visão
/// Geral, ao lado da distribuição 50-30-20, que é o assunto dela).
///
/// Uma coluna só, em qualquer largura. O arranjo de duas colunas existia para
/// caber o que a Home tinha demais; com a Home curta, a segunda coluna só
/// afastaria a leitura do canto onde ela começa.
class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SafeArea(
        child: AppContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ArenaHomeBlock(),
              AutomaticTransactionConsolidationWidget(maxItems: 3),
              WeeklyMissionsView(compact: true),
              AppSpacing.gapLg,
              CoachingInsightCard(compact: true),
              CompassStripView(),
              AppSpacing.gapLg,
              GoalsSection(highlightOnly: true, showTitle: false),
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}
