import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/utils/date_time_converter.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'reconciliation_model.freezed.dart';
part 'reconciliation_model.g.dart';

@freezed
sealed class ReconciliationTransaction with _$ReconciliationTransaction {
  const factory ReconciliationTransaction({
    required String description,
    required double amount,
    @DateTimeTwelvePmConverter()
    required DateTime date,
    required OrderType type, // income or expense
    CategoryModel? category,
  }) = _ReconciliationTransaction;

  factory ReconciliationTransaction.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationTransactionFromJson(json);
}

enum ReconciliationMatchStatus {
  matched,
  unmatched,
  suggested,
  ignored,
}

@freezed
sealed class ReconciliationMatch with _$ReconciliationMatch {
  const factory ReconciliationMatch({
    required ReconciliationTransaction documentTransaction,
    InstallmentModel? systemInstallment,
    OrderModel? createdOrder,
    @Default(ReconciliationMatchStatus.unmatched) ReconciliationMatchStatus status,
  }) = _ReconciliationMatch;
}
