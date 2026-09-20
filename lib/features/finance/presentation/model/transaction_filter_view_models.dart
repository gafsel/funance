import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'transaction_filter_view_models.freezed.dart';

@freezed
sealed class TransactionFilterState with _$TransactionFilterState {
  const factory TransactionFilterState({
    String? accountId,
    String? description,
    CategoryModel? category,
    OrderType? type,
    InstallmentStatus? status,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) = _TransactionFilterState;

  factory TransactionFilterState.fromQuery(
    TransactionQuery query, {
    CategoryModel? category,
    AccountModel? account,
  }) {
    return TransactionFilterState(
      accountId: query.accountId,
      description: query.description,
      category: category,
      type: query.type,
      status: query.status,
      minAmount: query.minAmount,
      maxAmount: query.maxAmount,
      startDate: query.startDate,
      endDate: query.endDate,
    );
  }

  const TransactionFilterState._();

  TransactionQuery toQuery() {
    return TransactionQuery(
      accountId: accountId,
      description: description,
      categoryId: category?.id,
      type: type,
      status: status,
      minAmount: minAmount,
      maxAmount: maxAmount,
      startDate: startDate,
      endDate: endDate,
    );
  }

  bool get hasActiveFilters {
    return accountId != null ||
        description != null ||
        category != null ||
        type != null ||
        status != null ||
        minAmount != null ||
        maxAmount != null;
  }
}
