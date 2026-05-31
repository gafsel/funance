// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoalModelPayDebt _$GoalModelPayDebtFromJson(Map<String, dynamic> json) =>
    _GoalModelPayDebt(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      deadline: DateTime.parse(json['deadline'] as String),
      accountId: json['accountId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GoalModelPayDebtToJson(_GoalModelPayDebt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'targetAmount': instance.targetAmount,
      'currentAmount': instance.currentAmount,
      'deadline': instance.deadline.toIso8601String(),
      'accountId': instance.accountId,
      'startDate': instance.startDate.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'runtimeType': instance.$type,
    };

_GoalModelCreditCard _$GoalModelCreditCardFromJson(Map<String, dynamic> json) =>
    _GoalModelCreditCard(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      averageSpending: (json['averageSpending'] as num).toDouble(),
      deadline: DateTime.parse(json['deadline'] as String),
      accountId: json['accountId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GoalModelCreditCardToJson(
  _GoalModelCreditCard instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'targetAmount': instance.targetAmount,
  'currentAmount': instance.currentAmount,
  'averageSpending': instance.averageSpending,
  'deadline': instance.deadline.toIso8601String(),
  'accountId': instance.accountId,
  'startDate': instance.startDate.toIso8601String(),
  'isDeleted': instance.isDeleted,
  'runtimeType': instance.$type,
};

_GoalModelReduceExpense _$GoalModelReduceExpenseFromJson(
  Map<String, dynamic> json,
) => _GoalModelReduceExpense(
  id: json['id'] as String,
  name: json['name'] as String,
  targetAmount: (json['targetAmount'] as num).toDouble(),
  currentAmount: (json['currentAmount'] as num).toDouble(),
  averageSpending: (json['averageSpending'] as num).toDouble(),
  deadline: DateTime.parse(json['deadline'] as String),
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  startDate: DateTime.parse(json['startDate'] as String),
  isDeleted: json['isDeleted'] as bool? ?? false,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$GoalModelReduceExpenseToJson(
  _GoalModelReduceExpense instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'targetAmount': instance.targetAmount,
  'currentAmount': instance.currentAmount,
  'averageSpending': instance.averageSpending,
  'deadline': instance.deadline.toIso8601String(),
  'category': instance.category.toJson(),
  'startDate': instance.startDate.toIso8601String(),
  'isDeleted': instance.isDeleted,
  'runtimeType': instance.$type,
};

_GoalModelSaveMoney _$GoalModelSaveMoneyFromJson(Map<String, dynamic> json) =>
    _GoalModelSaveMoney(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      deadline: DateTime.parse(json['deadline'] as String),
      accountId: json['accountId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GoalModelSaveMoneyToJson(_GoalModelSaveMoney instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'targetAmount': instance.targetAmount,
      'currentAmount': instance.currentAmount,
      'deadline': instance.deadline.toIso8601String(),
      'accountId': instance.accountId,
      'startDate': instance.startDate.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'runtimeType': instance.$type,
    };
