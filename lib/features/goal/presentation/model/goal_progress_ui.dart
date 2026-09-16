import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Apresentação do progresso de uma meta.
///
/// `GoalProgress` é derivado sincronamente de `GoalModel`
/// (`goal.calculateProgress()`), então não precisa de provider: chamar o
/// cálculo direto evita uma família chaveada pelo modelo freezed, que vazava
/// um provider por edição da meta.
extension GoalProgressUi on GoalProgress {
  Color getStatusColor(BuildContext context) {
    switch (status) {
      case GoalStatus.onTrack:
        return AppColors.success;
      case GoalStatus.atRisk:
        return AppColors.antiqueGold;
      case GoalStatus.behind:
        return AppColors.error;
      case GoalStatus.lost:
        return AppColors.error;
    }
  }

  String getStatusText(AppLocalizations l10n) {
    switch (status) {
      case GoalStatus.onTrack:
        return l10n.goalStatusOnTrack;
      case GoalStatus.atRisk:
        return l10n.goalStatusAtRisk;
      case GoalStatus.behind:
        return l10n.goalStatusBehind;
      case GoalStatus.lost:
        return l10n.goalStatusLost;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case GoalStatus.onTrack:
        return Icons.mood;
      case GoalStatus.atRisk:
        return Icons.warning_amber;
      case GoalStatus.behind:
        return Icons.watch_later_outlined;
      case GoalStatus.lost:
        return Icons.mood_bad;
    }
  }
}

/// Textos que dependem do TIPO da meta.
///
/// `currentAmount` significa coisas opostas: em `saveMoney`/`payDebt` é o
/// quanto já foi conquistado (e 100% é a vitória); em `reduceExpense`/
/// `reduceCreditCard` é o quanto já foi GASTO contra um teto (e 100% é o
/// orçamento estourado). Um texto só para os dois casos mentiria para metade
/// das metas.
extension GoalLabelsUi on GoalModel {
  /// Rótulo do valor corrente na barra de progresso.
  String amountLabel(AppLocalizations l10n) => switch (type) {
    GoalType.saveMoney => l10n.goalAmountSavedLabel,
    GoalType.payDebt => l10n.goalAmountPaidLabel,
    GoalType.reduceExpense || GoalType.reduceCreditCard =>
      l10n.goalAmountSpentLabel,
  };

  /// Resumo curto do progresso, para o card da Jornada.
  ///
  /// [format] recebe um valor e devolve a moeda já formatada no locale.
  String progressSummary(
    AppLocalizations l10n,
    String Function(double) format,
  ) {
    if (isAccumulation) {
      final remaining = targetAmount - currentAmount;
      return remaining > 0
          ? l10n.goalRemainingValue(format(remaining))
          : l10n.goalSpentOfLimit(
              format(currentAmount),
              format(targetAmount),
            );
    }

    final slack = targetAmount - currentAmount;
    return slack >= 0
        ? l10n.goalRemainingLimit(format(slack))
        : l10n.goalOverLimit(format(-slack));
  }

  /// "Concluída em" para metas de acúmulo, "Limite atingido em" para as de
  /// redução — nas de redução alcançar o alvo é bater o teto, não vencer.
  String? completionLabel(AppLocalizations l10n, String Function(DateTime) format) {
    final date = completedAt;
    if (date == null) return null;
    return isAccumulation
        ? l10n.goalCompletedAt(format(date))
        : l10n.goalLimitReachedAt(format(date));
  }
}
