import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/freedom_compass.dart';
import 'package:funances/features/home/presentation/widgets/journey_header.dart';
import 'package:funances/features/home/presentation/widgets/team_status_view.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AutomaticTransactionConsolidationWidget(),
                // A resposta primeiro: quanto sobra até o fim do mês, e só
                // depois a bússola e as missões. A Jornada abria em missões,
                // e a pergunta que o usuário faz todo dia ficava três telas
                // adiante.
                const JourneyHeader(),
                const FreedomCompassCard(),
                if (isLargeScreen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          spacing: 32,
                          children: [
                            CoachingInsightCard(),
                            WeeklyMissionsView(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: TeamStatusView()),
                    ],
                  )
                else ...[
                  CoachingInsightCard(),
                  Column(
                    spacing: 32,
                    children: [WeeklyMissionsView(), TeamStatusView()],
                  ),
                ],
                const GoalsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
