import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';

part 'overview_view_model.freezed.dart';

enum SummaryViewType { planning, effective }

@freezed
sealed class SummaryState with _$SummaryState {
  factory SummaryState({
    required List<PeriodSummaryModel> summary,
    required double specificPlannedAmountOthers,
    required double generalPlannedAmountOthers,
    required double actualAmountOthers,
    required double totalAmount,
  }) = _SummaryState;
}
