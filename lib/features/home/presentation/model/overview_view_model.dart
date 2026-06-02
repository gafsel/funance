import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'overview_view_model.freezed.dart';

enum SummaryViewType { planning, effective }

@freezed
sealed class OverviewCategorySummary with _$OverviewCategorySummary {
  factory OverviewCategorySummary({
    required CategoryModel category,
    required double generalPlannedAmount,
    required double specificPlannedAmount,
    required double actualAmount,
  }) = _OverviewCategorySummary;

  const OverviewCategorySummary._();

  double get plannedAmount => max(generalPlannedAmount, specificPlannedAmount);
}

@freezed
sealed class SummaryState with _$SummaryState {
  factory SummaryState({
    required List<OverviewCategorySummary> summary,
    required double specificPlannedAmountOthers,
    required double generalPlannedAmountOthers,
    required double actualAmountOthers,
    required double totalAmount,
  }) = _SummaryState;
}

@freezed
sealed class BalanceState with _$BalanceState {
  factory BalanceState({
    required double totalPlanned,
    required double totalActual,
  }) = _BalanceState;
}
