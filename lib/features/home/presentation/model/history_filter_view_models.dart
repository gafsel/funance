import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'history_filter_view_models.freezed.dart';

@freezed
sealed class HistoryFilterState with _$HistoryFilterState {
  const factory HistoryFilterState({
    String? description,
    CategoryModel? category,
    OrderType? type,
    InstallmentStatus? status,
    double? minAmount,
    double? maxAmount,
  }) = _HistoryFilterState;

  factory HistoryFilterState.fromQuery(TransactionQuery query, {CategoryModel? category}) {
    return HistoryFilterState(
      description: query.description,
      category: category,
      type: query.type,
      status: query.status,
      minAmount: query.minAmount,
      maxAmount: query.maxAmount,
    );
  }

  const HistoryFilterState._();

  TransactionQuery toQuery() {
    return TransactionQuery(
      description: description,
      categoryId: category?.id,
      type: type,
      status: status,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }

  bool get hasActiveFilters {
    return description != null ||
        category != null ||
        type != null ||
        status != null ||
        minAmount != null ||
        maxAmount != null;
  }
}
