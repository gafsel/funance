// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconciliation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReconciliationTransaction _$ReconciliationTransactionFromJson(
  Map<String, dynamic> json,
) => _ReconciliationTransaction(
  description: json['description'] as String,
  amount: (json['amount'] as num).toDouble(),
  date: const DateTimeTwelvePmConverter().fromJson(json['date'] as String),
  type: $enumDecode(_$OrderTypeEnumMap, json['type']),
  category: json['category'] == null
      ? null
      : CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReconciliationTransactionToJson(
  _ReconciliationTransaction instance,
) => <String, dynamic>{
  'description': instance.description,
  'amount': instance.amount,
  'date': const DateTimeTwelvePmConverter().toJson(instance.date),
  'type': _$OrderTypeEnumMap[instance.type]!,
  'category': instance.category,
};

const _$OrderTypeEnumMap = {
  OrderType.expense: 'expense',
  OrderType.income: 'income',
  OrderType.transfer: 'transfer',
};
