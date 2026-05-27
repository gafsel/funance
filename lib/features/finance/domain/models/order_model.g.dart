// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['id'] as String,
  description: json['description'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  installmentsCount: (json['installments_count'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  type: $enumDecode(_$OrderTypeEnumMap, json['type']),
  planningId: json['planning_id'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'total_amount': instance.totalAmount,
      'category': instance.category.toJson(),
      'installments_count': instance.installmentsCount,
      'date': instance.date.toIso8601String(),
      'status': _$OrderStatusEnumMap[instance.status]!,
      'type': _$OrderTypeEnumMap[instance.type]!,
      'planning_id': instance.planningId,
      'metadata': instance.metadata,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.active: 'active',
  OrderStatus.paid: 'paid',
  OrderStatus.cancelled: 'cancelled',
};

const _$OrderTypeEnumMap = {
  OrderType.expense: 'expense',
  OrderType.income: 'income',
  OrderType.transfer: 'transfer',
};
