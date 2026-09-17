import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_strip_view.dart';
import 'package:funances/features/home/presentation/widgets/home/workspace_header.dart';
import 'package:funances/features/home/presentation/widgets/journey_header.dart';
import 'package:funances/features/home/presentation/widgets/team_status_view.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.layout.isWide;

        return SingleChildScrollView(
          padding: AppSpacing.allMd,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AutomaticTransactionConsolidationWidget(),
                // De quem é o cofre, de que tipo, e em que nível — tudo numa
                // linha. O nível muda uma vez por mês e tinha um bloco
                // inteiro só para ele.
                const WorkspaceHeader(),
                // A resposta primeiro: quanto sobra até o fim do mês, e só
                // depois a bússola e as missões. A Jornada abria em missões,
                // e a pergunta que o usuário faz todo dia ficava três telas
                // adiante.
                const JourneyHeader(),
                // A Bússola vira uma linha que expande. O cartão completo
                // continua existindo e abre daqui: o índice muda uma vez por
                // mês e não precisa pagar aluguel diário.
                const CompassStripView(),
                AppSpacing.gapLg,
                if (isLargeScreen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          spacing: AppSpacing.xl,
                          children: [
                            CoachingInsightCard(),
                            WeeklyMissionsView(),
                          ],
                        ),
                      ),
                      AppSpacing.gapXl,
                      Expanded(flex: 2, child: TeamStatusView()),
                    ],
                  )
                else ...[
                  CoachingInsightCard(),
                  Column(
                    spacing: AppSpacing.xl,
                    children: [WeeklyMissionsView(), TeamStatusView()],
                  ),
                ],
                const GoalsSection(),
                AppSpacing.gapXl,
              ],
            ),
          ),
        );
      },
    );
  }
}
