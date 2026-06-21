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
    ReconciliationTransaction? documentTransaction,
    InstallmentModel? systemInstallment,
    OrderModel? createdOrder,
    @Default(ReconciliationMatchStatus.unmatched) ReconciliationMatchStatus status,
    String? customDescription,
    CategoryModel? customCategory,
    OrderType? customType,
    String? targetAccountId,
    int? installmentCount,
  }) = _ReconciliationMatch;
}

enum UploadStatus {
  reading,
  extracting,
  searching,
  preparing,
  completed,
  error;

  static UploadStatus fromName(String name) {
    return UploadStatus.values.firstWhere(
      (v) => v.name == name,
      orElse: () => UploadStatus.error,
    );
  }
}

@freezed
sealed class UploadProgressModel with _$UploadProgressModel {
  const factory UploadProgressModel({
    required UploadStatus status,
    required double progress,
    required String message,
  }) = _UploadProgressModel;

  factory UploadProgressModel.fromJson(Map<String, dynamic> json) =>
      _$UploadProgressModelFromJson(json);
}
