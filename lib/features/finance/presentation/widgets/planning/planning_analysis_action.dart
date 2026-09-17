import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/presentation/widgets/planning_503020_analysis_sheet.dart';

/// Botão da análise do planejamento pela IA.
///
/// A análise é cara e demorada (até dois minutos), então ela abre um modal de
/// carregamento com fases em vez de um spinner: um spinner parado por dois
/// minutos é indistinguível de um travamento.
class PlanningAnalysisAction extends ConsumerWidget {
  const PlanningAnalysisAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: context.l10n.planningAnalysisAction,
      icon: const Icon(Icons.auto_awesome),
      onPressed: () => _openAnalysis(context, ref),
    );
  }

  Future<void> _openAnalysis(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final analysis = await showLoadingModal(
        context,
        ref.read(PlanningAnalysisDomainProviders.service).analyze(),
        child: AnalysisLoadingView(
          title: l10n.planningAnalysisLoadingTitle,
          description: l10n.planningAnalysisLoadingDesc,
          firstPhaseDuration: const Duration(seconds: 45),
          totalDuration: const Duration(minutes: 2),
        ),
      );

      if (!context.mounted) return;
      await showPlanning503020AnalysisSheet(
        context,
        analysis,
        onRefresh: () {
          if (context.mounted) {
            _openAnalysis(context, ref);
          }
        },
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            callableErrorMessage(
              e,
              l10n.planningAnalysisError,
              offlineMessage: l10n.errorOfflineCallable,
            ),
          ),
        ),
      );
    }
  }
}
