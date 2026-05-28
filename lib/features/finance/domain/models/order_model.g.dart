// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseOrder _$ExpenseOrderFromJson(Map<String, dynamic> json) => ExpenseOrder(
  id: json['id'] as String,
  description: json['description'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  installmentsCount: (json['installments_count'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  planningId: json['planning_id'] as String?,
  accountId: json['accountId'] as String?,
  isDeleted: json['is_deleted'] as bool?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ExpenseOrderToJson(ExpenseOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'total_amount': instance.totalAmount,
      'category': instance.category,
      'installments_count': instance.installmentsCount,
      'date': instance.date.toIso8601String(),
      'status': _$OrderStatusEnumMap[instance.status]!,
      'planning_id': instance.planningId,
      'accountId': instance.accountId,
      'is_deleted': instance.isDeleted,
      'runtimeType': instance.$type,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.active: 'active',
  OrderStatus.paid: 'paid',
  OrderStatus.cancelled: 'cancelled',
};

IncomeOrder _$IncomeOrderFromJson(Map<String, dynamic> json) => IncomeOrder(
  id: json['id'] as String,
  description: json['description'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  installmentsCount: (json['installments_count'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  planningId: json['planning_id'] as String?,
  accountId: json['accountId'] as String?,
  isDeleted: json['is_deleted'] as bool?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$IncomeOrderToJson(IncomeOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'total_amount': instance.totalAmount,
      'category': instance.category,
      'installments_count': instance.installmentsCount,
      'date': instance.date.toIso8601String(),
      'status': _$OrderStatusEnumMap[instance.status]!,
      'planning_id': instance.planningId,
      'accountId': instance.accountId,
      'is_deleted': instance.isDeleted,
      'runtimeType': instance.$type,
    };

TransferOrder _$TransferOrderFromJson(Map<String, dynamic> json) =>
    TransferOrder(
      id: json['id'] as String,
      description: json['description'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      installmentsCount: (json['installments_count'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      planningId: json['planning_id'] as String?,
      fromAccountId: json['fromAccountId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      isDeleted: json['is_deleted'] as bool?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$TransferOrderToJson(TransferOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'total_amount': instance.totalAmount,
      'category': instance.category,
      'installments_count': instance.installmentsCount,
      'date': instance.date.toIso8601String(),
      'status': _$OrderStatusEnumMap[instance.status]!,
      'planning_id': instance.planningId,
      'fromAccountId': instance.fromAccountId,
      'toAccountId': instance.toAccountId,
      'is_deleted': instance.isDeleted,
      'runtimeType': instance.$type,
    };
