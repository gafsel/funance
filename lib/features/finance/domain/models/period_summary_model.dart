import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_summary_model.freezed.dart';
part 'period_summary_model.g.dart';

@freezed
sealed class PeriodSummaryCategoryModel with _$PeriodSummaryCategoryModel {
  const factory PeriodSummaryCategoryModel({
    @Default(0) double generalPlannedAmount,
    @Default(0) double specificPlannedAmount,
    @Default(0) double actualAmount,
  }) = _PeriodSummaryCategoryModel;

  const PeriodSummaryCategoryModel._();

  factory PeriodSummaryCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$PeriodSummaryCategoryModelFromJson(json);

  double get plannedAmount => max(generalPlannedAmount, specificPlannedAmount);

  double get progress => plannedAmount > 0 ? actualAmount / plannedAmount : 0.0;
}

@freezed
sealed class PeriodSummaryModel with _$PeriodSummaryModel {
  const factory PeriodSummaryModel.year({
    required int year,
    required Map<String, PeriodSummaryCategoryModel> categories,
    required DateTime lastUpdate,
  }) = _PeriodSummaryModelYear;

  const factory PeriodSummaryModel.month({
    required int year,
    required int month,
    required Map<String, PeriodSummaryCategoryModel> categories,
    required DateTime lastUpdate,
  }) = _PeriodSummaryModelMonth;

  const factory PeriodSummaryModel.week({
    required int year,
    required int week,
    required Map<String, PeriodSummaryCategoryModel> categories,
    required DateTime lastUpdate,
  }) = _PeriodSummaryModelWeek;

  const PeriodSummaryModel._();

  @JsonKey(includeToJson: true)
  String get id => map(
    year: (data) => "${data.year}",
    month: (data) => "${data.year}-${data.month.toString().padLeft(2, "0")}",
    week: (data) => "${data.year}-W${data.week.toString().padLeft(2, "0")}",
  );

  factory PeriodSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$PeriodSummaryModelFromJson(json);
}
