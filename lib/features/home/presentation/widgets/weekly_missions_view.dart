import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_summary.dart';
import 'package:funances/features/home/presentation/widgets/missions/server_missions.dart';
import 'package:funances/features/home/presentation/widgets/missions/streak_badge.dart';
import 'package:funances/features/home/presentation/widgets/missions/week_checklist.dart';
import 'package:funances/features/home/presentation/widgets/missions/weekly_xp.dart';

// As peças moram em `missions/` desde que este arquivo foi quebrado por
// responsabilidade, mas continuam saindo por aqui: a Jornada e os testes
// importam `weekly_missions_view.dart` e não precisam saber da divisão.
export 'package:funances/features/home/presentation/widgets/missions/mission_card.dart';
export 'package:funances/features/home/presentation/widgets/missions/mission_summary.dart';
export 'package:funances/features/home/presentation/widgets/missions/no_missions_empty_state.dart';
export 'package:funances/features/home/presentation/widgets/missions/server_missions.dart';
export 'package:funances/features/home/presentation/widgets/missions/streak_badge.dart';
export 'package:funances/features/home/presentation/widgets/missions/success_empty_state.dart';
export 'package:funances/features/home/presentation/widgets/missions/week_checklist.dart';
export 'package:funances/features/home/presentation/widgets/missions/weekly_xp.dart';

/// As missões da semana — as do SERVIDOR — e o checklist do que vence nela.
///
/// F2.4: havia dois sistemas de missão. O do servidor (`weekly_missions`,
/// com nome gerado por IA, alvo, progresso e XP de verdade) nunca aparecia na
/// tela; o do cliente inventava missões a partir das parcelas e um XP que
/// ninguém creditava. Agora só o do servidor é "missão"; as parcelas da
/// semana são o checklist, sem XP fabricado.
class WeeklyMissionsView extends ConsumerWidget {
  const WeeklyMissionsView({super.key, this.compact = false});

  /// Três LINHAS em vez de três cartões, sem o XP da semana e sem o
  /// checklist.
  ///
  /// Na Home este bloco media 1158px — 65% de uma tela que já tinha três
  /// rolagens e meia. O resumo diz as mesmas três coisas que se lê de
  /// relance (qual é a missão, quanto falta, quanto paga) em uma altura por
  /// missão; o resto continua existindo em `/missions`, que abre pelo
  /// cabeçalho do resumo.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (compact) return const MissionSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.weeklyMissionsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const StreakBadge(),
          ],
        ),
        const SizedBox(height: 16),
        const WeeklyXp(),
        const SizedBox(height: 24),
        const ServerMissions(),
        const SizedBox(height: 32),
        const WeekChecklist(),
      ],
    );
  }
}
