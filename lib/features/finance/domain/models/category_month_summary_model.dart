import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_month_summary_model.freezed.dart';
part 'category_month_summary_model.g.dart';

@freezed
sealed class CategoryMonthSummaryModel with _$CategoryMonthSummaryModel {
  const factory CategoryMonthSummaryModel({
    required String id,
    required int year,
    required int month,
    required CategoryModel category,
    required double totalDebit,
    required double totalCredit,
    required double plannedAmount,
    required double actualAmount,
    required int count,
    required DateTime lastUpdate,
  }) = _CategoryMonthSummaryModel;

  factory CategoryMonthSummaryModel.fromJson(Map<String, dynamic> json) => _$CategoryMonthSummaryModelFromJson(json);
}
