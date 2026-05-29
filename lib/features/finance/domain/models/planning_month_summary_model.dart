import 'package:freezed_annotation/freezed_annotation.dart';

part 'planning_month_summary_model.freezed.dart';
part 'planning_month_summary_model.g.dart';

@freezed
sealed class PlanningMonthSummaryModel with _$PlanningMonthSummaryModel {
  const factory PlanningMonthSummaryModel({
    required String id,
    required int year,
    required int month,
    required double plannedAmount,
    required double actualAmount,
    required DateTime lastUpdate,
  }) = _PlanningMonthSummaryModel;

  const PlanningMonthSummaryModel._();

  factory PlanningMonthSummaryModel.fromJson(Map<String, dynamic> json) => _$PlanningMonthSummaryModelFromJson(json);

  double get progress => plannedAmount > 0 ? actualAmount / plannedAmount : 0.0;
}
