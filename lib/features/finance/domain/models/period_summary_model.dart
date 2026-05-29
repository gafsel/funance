import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'period_summary_model.freezed.dart';

part 'period_summary_model.g.dart';

@freezed
sealed class PeriodSummaryModel with _$PeriodSummaryModel {
  const factory PeriodSummaryModel.year({
    required int year,
    required CategoryModel category,
    @Default(0)
    double generalPlannedAmount, // Valores vindos da category planning
    required double specificPlannedAmount, // Valores vindos de installments
    @Default(0) double actualAmount,
    required DateTime lastUpdate,
  }) = _PeriodSummaryModelYear;

  const factory PeriodSummaryModel.month({
    required int year,
    required int month,
    required CategoryModel category,
    @Default(0)
    double generalPlannedAmount, // Valores vindos da category planning
    required double specificPlannedAmount, // Valores vindos de installments
    @Default(0) double actualAmount,
    required DateTime lastUpdate,
  }) = _PeriodSummaryModelMonth;

  const PeriodSummaryModel._();

  @JsonKey(includeToJson: true)
  String get id => map(
    year: (data) => "${data.year}-${data.category.id}",
    month: (data) =>
        "$data.year-${data.month.toString().padLeft(2, "0")}-${data.category.id}",
  );

  factory PeriodSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$PeriodSummaryModelFromJson(json);

  double get plannedAmount =>
      generalPlannedAmount > 0 ? generalPlannedAmount : specificPlannedAmount;

  double get progress => plannedAmount > 0 ? actualAmount / plannedAmount : 0.0;
}
