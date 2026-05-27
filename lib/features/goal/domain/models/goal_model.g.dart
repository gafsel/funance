// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoalModel _$GoalModelFromJson(Map<String, dynamic> json) => GoalModel(
  id: json['id'] as String,
  name: json['name'] as String,
  targetAmount: (json['targetAmount'] as num).toDouble(),
  currentAmount: (json['currentAmount'] as num).toDouble(),
  deadline: DateTime.parse(json['deadline'] as String),
  icon: json['icon'] as String?,
  type: $enumDecode(_$GoalTypeEnumMap, json['type']),
  accountId: json['accountId'] as String?,
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
  isDeleted: json['isDeleted'] as bool? ?? false,
);

Map<String, dynamic> _$GoalModelToJson(GoalModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'targetAmount': instance.targetAmount,
  'currentAmount': instance.currentAmount,
  'deadline': instance.deadline.toIso8601String(),
  'icon': instance.icon,
  'type': _$GoalTypeEnumMap[instance.type]!,
  'accountId': instance.accountId,
  'startDate': instance.startDate.toIso8601String(),
  'metadata': instance.metadata,
  'isDeleted': instance.isDeleted,
};

const _$GoalTypeEnumMap = {
  GoalType.saveMoney: 'save_money',
  GoalType.reduceExpense: 'reduce_expense',
  GoalType.reduceCreditCard: 'reduce_credit_card',
};
