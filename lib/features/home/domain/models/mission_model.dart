import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'mission_model.freezed.dart';

@freezed
sealed class MissionModel with _$MissionModel {
  const factory MissionModel({
    required List<InstallmentMission> pendingInstallments,
    required List<InstallmentMission> completedInstallments,
    required List<InstallmentMission> overdueInstallments,
    required List<PlanningMission> planningMissions,
    required double totalXp,
    required double currentXp,
    required DateTime startDate,
    required DateTime endDate,
  }) = _MissionModel;

  const MissionModel._();

  double get progressPercentage => totalXp > 0 ? (currentXp / totalXp) : 0;
}

@freezed
sealed class InstallmentMission with _$InstallmentMission {
  const factory InstallmentMission({
    required InstallmentModel installment,
    required double xpValue,
    @Default(false) bool isAdherent,
    @Default(0) double earnedXp,
  }) = _InstallmentMission;
}

@freezed
sealed class PlanningMission with _$PlanningMission {
  const factory PlanningMission({
    required CategoryModel category,
    required PeriodSummaryCategoryModel summary,
    required double weeklyPlannedAmount,
    required double weeklyActualAmount,
    required double xpValue,
    required double progress,
    required bool isAdherent,
    required double earnedXp,
  }) = _PlanningMission;
}
