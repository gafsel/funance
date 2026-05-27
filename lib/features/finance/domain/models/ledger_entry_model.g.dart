// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerEntryModel _$LedgerEntryModelFromJson(Map<String, dynamic> json) =>
    LedgerEntryModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String?,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: $enumDecode(_$LedgerEntryStatusEnumMap, json['status']),
      type: $enumDecode(_$LedgerEntryTypeEnumMap, json['type']),
      accountId: json['account_id'] as String?,
      isDeductible: json['is_deductible'] as bool? ?? false,
    );

Map<String, dynamic> _$LedgerEntryModelToJson(LedgerEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'category': instance.category,
      'amount': instance.amount,
      'due_date': instance.dueDate.toIso8601String(),
      'status': _$LedgerEntryStatusEnumMap[instance.status]!,
      'type': _$LedgerEntryTypeEnumMap[instance.type]!,
      'account_id': instance.accountId,
      'is_deductible': instance.isDeductible,
    };

const _$LedgerEntryStatusEnumMap = {
  LedgerEntryStatus.forecast: 'forecast',
  LedgerEntryStatus.cleared: 'cleared',
};

const _$LedgerEntryTypeEnumMap = {
  LedgerEntryType.debit: 'debit',
  LedgerEntryType.credit: 'credit',
};
