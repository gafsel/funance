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

  /// Rótulo do DESFECHO da meta, ou `null` enquanto ela ainda corre.
  ///
  /// Sucesso é sempre "Concluída em". A falha tem duas caras, e são mesmo
  /// diferentes: numa meta de redução, falhar é ter ESTOURADO o teto (o prazo
  /// nem precisa ter chegado); numa de acúmulo, é o prazo ter acabado sem
  /// alcançar o alvo.
  String? outcomeLabel(
    AppLocalizations l10n,
    String Function(DateTime) format,
  ) {
    switch (outcome) {
      case null:
        return null;
      case GoalOutcome.success:
        final date = completedAt;
        return date == null ? null : l10n.goalCompletedAt(format(date));
      case GoalOutcome.failed:
        final date = failedAt;
        if (date == null) return null;
        return isAccumulation
            ? l10n.goalDeadlineMissedAt(format(date))
            : l10n.goalLimitBlownAt(format(date));
    }
  }

  /// Ícone do desfecho: troféu para sucesso, alerta para falha.
  IconData get outcomeIcon =>
      isCompleted ? Icons.emoji_events : Icons.report_gmailerrorred;

  /// Cor do desfecho — o mesmo par de cores que o resto do app usa para
  /// sucesso e erro.
  Color get outcomeColor => isCompleted ? AppColors.success : AppColors.error;
}
