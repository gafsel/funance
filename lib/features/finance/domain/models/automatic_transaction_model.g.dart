// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automatic_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AutomaticTransactionModel _$AutomaticTransactionModelFromJson(
  Map<String, dynamic> json,
) => _AutomaticTransactionModel(
  id: json['id'] as String,
  description: json['description'] as String,
  amount: (json['amount'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
  type: $enumDecode(_$OrderTypeEnumMap, json['type']),
  originNotificationId: json['originNotificationId'] as String?,
  packageName: json['packageName'] as String?,
  accountId: json['accountId'] as String?,
  categoryId: json['categoryId'] as String?,
  suggestedCategory: json['suggestedCategory'] == null
      ? null
      : CategoryModel.fromJson(
          json['suggestedCategory'] as Map<String, dynamic>,
        ),
  suggestedAccount: json['suggestedAccount'] == null
      ? null
      : AccountModel.fromJson(json['suggestedAccount'] as Map<String, dynamic>),
  isConsolidated: json['isConsolidated'] as bool? ?? false,
  isIgnored: json['isIgnored'] as bool? ?? false,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AutomaticTransactionModelToJson(
  _AutomaticTransactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'description': instance.description,
  'amount': instance.amount,
  'date': instance.date.toIso8601String(),
  'type': _$OrderTypeEnumMap[instance.type]!,
  'originNotificationId': instance.originNotificationId,
  'packageName': instance.packageName,
  'accountId': instance.accountId,
  'categoryId': instance.categoryId,
  'suggestedCategory': instance.suggestedCategory?.toJson(),
  'suggestedAccount': instance.suggestedAccount?.toJson(),
  'isConsolidated': instance.isConsolidated,
  'isIgnored': instance.isIgnored,
  'metadata': instance.metadata,
};

const _$OrderTypeEnumMap = {
  OrderType.expense: 'expense',
  OrderType.income: 'income',
  OrderType.transfer: 'transfer',
};
