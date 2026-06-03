// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstallmentModel _$InstallmentModelFromJson(Map<String, dynamic> json) =>
    _InstallmentModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      dueDate: const DateTimeTwelvePmConverter().fromJson(
        json['dueDate'] as String,
      ),
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
      paidDate: const DateTimeTwelvePmNullableConverter().fromJson(
        json['paidDate'] as String?,
      ),
      installmentNumber: (json['installmentNumber'] as num?)?.toInt(),
      installmentCount: (json['installmentCount'] as num?)?.toInt(),
      status: $enumDecode(_$InstallmentStatusEnumMap, json['status']),
      type: $enumDecode(_$OrderTypeEnumMap, json['type']),
      installmentType: $enumDecode(
        _$InstallmentTypeEnumMap,
        json['installmentType'],
      ),
      accounts:
          (json['accounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, $enumDecode(_$AccountImpactEnumMap, e)),
          ) ??
          const {},
      category: json['category'] == null
          ? null
          : CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      replicationCascade: $enumDecodeNullable(
        _$ReplicationCascadeEnumMap,
        json['replicationCascade'],
      ),
      xp: (json['xp'] as num?)?.toDouble(),
      isInvoice: json['isInvoice'] as bool? ?? false,
    );

Map<String, dynamic> _$InstallmentModelToJson(_InstallmentModel instance) =>
    <String, dynamic>{
      'accountIds': instance.accountIds,
      'referenceDate': instance.referenceDate.toIso8601String(),
      'referenceAmount': instance.referenceAmount,
      'id': instance.id,
      'orderId': instance.orderId,
      'amount': instance.amount,
      'description': instance.description,
      'dueDate': const DateTimeTwelvePmConverter().toJson(instance.dueDate),
      'paidAmount': instance.paidAmount,
      'paidDate': const DateTimeTwelvePmNullableConverter().toJson(
        instance.paidDate,
      ),
      'installmentNumber': instance.installmentNumber,
      'installmentCount': instance.installmentCount,
      'status': _$InstallmentStatusEnumMap[instance.status]!,
      'type': _$OrderTypeEnumMap[instance.type]!,
      'installmentType': _$InstallmentTypeEnumMap[instance.installmentType]!,
      'accounts': instance.accounts.map(
        (k, e) => MapEntry(k, _$AccountImpactEnumMap[e]!),
      ),
      'category': instance.category?.toJson(),
      'replicationCascade':
          _$ReplicationCascadeEnumMap[instance.replicationCascade],
      'xp': instance.xp,
      'isInvoice': instance.isInvoice,
    };

const _$InstallmentStatusEnumMap = {
  InstallmentStatus.pending: 'pending',
  InstallmentStatus.paid: 'paid',
  InstallmentStatus.settled: 'settled',
  InstallmentStatus.removed: 'removed',
};

const _$OrderTypeEnumMap = {
  OrderType.expense: 'expense',
  OrderType.income: 'income',
  OrderType.transfer: 'transfer',
};

const _$InstallmentTypeEnumMap = {
  InstallmentType.single: 'single',
  InstallmentType.installment: 'installment',
  InstallmentType.recurring: 'recurring',
};

const _$AccountImpactEnumMap = {
  AccountImpact.debt: 'debt',
  AccountImpact.credit: 'credit',
};

const _$ReplicationCascadeEnumMap = {
  ReplicationCascade.none: 'none',
  ReplicationCascade.all: 'all',
  ReplicationCascade.future: 'future',
};
