import 'package:freezed_annotation/freezed_annotation.dart';

part 'planning_month_summary_model.freezed.dart';
part 'planning_month_summary_model.g.dart';

@freezed
sealed class PlanningMonthSummaryModel with _$PlanningMonthSummaryModel {
  const factory PlanningMonthSummaryModel({
    required String id,
    required int year,
    required int month,
    @JsonKey(name: 'planned_amount') required double plannedAmount,
    @JsonKey(name: 'actual_amount') required double actualAmount,
    @JsonKey(name: 'last_update') required DateTime lastUpdate,
  }) = _PlanningMonthSummaryModel;

  const PlanningMonthSummaryModel._();

  factory PlanningMonthSummaryModel.fromJson(Map<String, dynamic> json) => _$PlanningMonthSummaryModelFromJson(json);

  double get progress => plannedAmount > 0 ? actualAmount / plannedAmount : 0.0;
}
