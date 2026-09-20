import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_strip_view.dart';
import 'package:funances/features/home/presentation/widgets/home/due_soon_strip.dart';
import 'package:funances/features/home/presentation/widgets/journey_header.dart';
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
/// 2. **quanto sobra no mês** — a única pergunta que se faz todo dia;
/// 3. **o que vence hoje e amanhã** — o que ainda dá tempo de resolver;
/// 4. **as pendências do leitor de notificação**, quando existem. Mesma
///    família do 3: coisas que expiram;
/// 5. **as missões da semana**, com o que fazer;
/// 6. **o empurrão** — o coaching, em UMA linha;
/// 7. **a linha da Bússola** — número, patente e variação;
/// 8. **uma meta em destaque**, a de prazo mais curto.
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
              JourneyHeader(),
              DueSoonStrip(),
              AutomaticTransactionConsolidationWidget(),
              WeeklyMissionsView(),
              AppSpacing.gapLg,
              CoachingInsightCard(compact: true),
              CompassStripView(),
              AppSpacing.gapLg,
              GoalsSection(highlightOnly: true),
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}
