// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => _OrderModel(
  id: json['id'] as String,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String,
  dueDay: (json['dueDay'] as num).toInt(),
  startMonth: json['startMonth'] as String,
  installmentCount: (json['installmentCount'] as num?)?.toInt(),
  installmentType: $enumDecode(
    _$InstallmentTypeEnumMap,
    json['installmentType'],
  ),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  type: $enumDecode(_$OrderTypeEnumMap, json['type']),
  installmentCreationStatus: $enumDecodeNullable(
    _$InstallmentStatusEnumMap,
    json['installmentCreationStatus'],
  ),
  accounts: (json['accounts'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, $enumDecode(_$AccountImpactEnumMap, e)),
  ),
  category: json['category'] == null
      ? null
      : CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderModelToJson(_OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'description': instance.description,
      'dueDay': instance.dueDay,
      'startMonth': instance.startMonth,
      'installmentCount': instance.installmentCount,
      'installmentType': _$InstallmentTypeEnumMap[instance.installmentType]!,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'type': _$OrderTypeEnumMap[instance.type]!,
      'installmentCreationStatus':
          _$InstallmentStatusEnumMap[instance.installmentCreationStatus],
      'accounts': instance.accounts?.map(
        (k, e) => MapEntry(k, _$AccountImpactEnumMap[e]!),
      ),
      'category': instance.category,
    };

const _$InstallmentTypeEnumMap = {
  InstallmentType.single: 'single',
  InstallmentType.installment: 'installment',
  InstallmentType.recurring: 'recurring',
};

const _$OrderStatusEnumMap = {
  OrderStatus.active: 'active',
  OrderStatus.cancelled: 'cancelled',
};

const _$OrderTypeEnumMap = {
  OrderType.expense: 'expense',
  OrderType.income: 'income',
  OrderType.transfer: 'transfer',
};

const _$InstallmentStatusEnumMap = {
  InstallmentStatus.pending: 'pending',
  InstallmentStatus.paid: 'paid',
  InstallmentStatus.settled: 'settled',
  InstallmentStatus.removed: 'removed',
};

const _$AccountImpactEnumMap = {
  AccountImpact.debt: 'debt',
  AccountImpact.credit: 'credit',
};
