// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UniquePlanning _$UniquePlanningFromJson(Map<String, dynamic> json) =>
    UniquePlanning(
      id: json['id'] as String,
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      amount: (json['amount'] as num).toDouble(),
      installmentsCount: (json['installmentsCount'] as num?)?.toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      accountId: json['accountId'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$UniquePlanningToJson(UniquePlanning instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category.toJson(),
      'amount': instance.amount,
      'installmentsCount': instance.installmentsCount,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'accountId': instance.accountId,
      'runtimeType': instance.$type,
    };

RecurrentPlanning _$RecurrentPlanningFromJson(Map<String, dynamic> json) =>
    RecurrentPlanning(
      id: json['id'] as String,
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      amount: (json['amount'] as num).toDouble(),
      installmentsCount: (json['installmentsCount'] as num?)?.toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      accountId: json['accountId'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$RecurrentPlanningToJson(RecurrentPlanning instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category.toJson(),
      'amount': instance.amount,
      'installmentsCount': instance.installmentsCount,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'accountId': instance.accountId,
      'runtimeType': instance.$type,
    };

ParceladoPlanning _$ParceladoPlanningFromJson(Map<String, dynamic> json) =>
    ParceladoPlanning(
      id: json['id'] as String,
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      amount: (json['amount'] as num).toDouble(),
      installmentsCount: (json['installmentsCount'] as num?)?.toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      accountId: json['accountId'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ParceladoPlanningToJson(ParceladoPlanning instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category.toJson(),
      'amount': instance.amount,
      'installmentsCount': instance.installmentsCount,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'accountId': instance.accountId,
      'runtimeType': instance.$type,
    };
