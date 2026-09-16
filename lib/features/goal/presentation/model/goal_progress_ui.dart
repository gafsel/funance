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
