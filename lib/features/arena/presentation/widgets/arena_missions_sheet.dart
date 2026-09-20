import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';

/// As missões da semana, na folha que o pergaminho da cena abre.
///
/// É o MESMO bloco que abria a Home — `WeeklyMissionsView(compact: true)`,
/// com o cabeçalho que conta quantas foram, uma linha por missão com
/// progresso e XP, e o botão único da missão em foco. Nada foi reescrito
/// para caber aqui: a decisão do dono foi tirar o bloco da tela, não trocar o
/// conteúdo dele.
///
/// O cabeçalho continua sendo a porta de `/missions`, onde estão os cartões
/// completos, o XP da semana e o checklist. A folha fica na pilha enquanto
/// essa tela está aberta, e reaparece quando o usuário volta — que é o
/// comportamento normal de uma folha modal e poupa um toque de quem só foi
/// conferir uma coisa.
class ArenaMissionsSheet extends ConsumerWidget {
  const ArenaMissionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
      builder: (context) => const ArenaMissionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // O resumo SOME quando não há missão — na Home isso era certo, porque
    // um bloco que reserva altura para dizer "não há nada" é altura
    // desperdiçada. Numa folha que o usuário ABRIU, sumir é pior: ele pediu
    // para ver as missões e recebeu um retângulo vazio.
    final vazia =
        (ref.watch(JourneyViewProviders.weeklyMissions).valueOrNull ?? const [])
            .isEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: vazia
            ? const NoMissionsEmptyState()
            : const WeeklyMissionsView(compact: true),
      ),
    );
  }
}
