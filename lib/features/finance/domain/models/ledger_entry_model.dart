import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_entry_model.freezed.dart';
part 'ledger_entry_model.g.dart';

enum LedgerEntryStatus {
  @JsonValue('forecast')
  forecast,
  @JsonValue('cleared')
  cleared,
}

enum LedgerEntryType {
  @JsonValue('debit')
  debit,
  @JsonValue('credit')
  credit,
}

@freezed
sealed class LedgerEntryModel with _$LedgerEntryModel {
  const factory LedgerEntryModel({
    required String id,
    @JsonKey(name: 'order_id') String? orderId,
    required String category,
    required double amount,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    required LedgerEntryStatus status,
    required LedgerEntryType type,
    @JsonKey(name: 'account_id') String? accountId,
    @JsonKey(name: 'is_deductible') @Default(false) bool isDeductible,
  }) = _LedgerEntryModel;

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) => _$LedgerEntryModelFromJson(json);
}
