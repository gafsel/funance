// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountModel _$AccountModelFromJson(Map<String, dynamic> json) => AccountModel(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  type: $enumDecode(_$AccountTypeEnumMap, json['type']),
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  isDeleted: json['isDeleted'] as bool? ?? false,
  initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0.0,
  initialBalanceDate: DateTime.parse(json['initial_balance_date'] as String),
  filePath: json['file_path'] as String?,
  fileName: json['file_name'] as String?,
  processingStatus:
      $enumDecodeNullable(
        _$AccountProcessingStatusEnumMap,
        json['processing_status'],
      ) ??
      AccountProcessingStatus.none,
);

Map<String, dynamic> _$AccountModelToJson(AccountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'type': _$AccountTypeEnumMap[instance.type]!,
      'metadata': instance.metadata,
      'isDeleted': instance.isDeleted,
      'initial_balance': instance.initialBalance,
      'initial_balance_date': instance.initialBalanceDate.toIso8601String(),
      'file_path': instance.filePath,
      'file_name': instance.fileName,
      'processing_status':
          _$AccountProcessingStatusEnumMap[instance.processingStatus]!,
    };

const _$AccountTypeEnumMap = {
  AccountType.checking: 'checking',
  AccountType.investment: 'investment',
  AccountType.creditCard: 'credit_card',
  AccountType.debt: 'debt',
};

const _$AccountProcessingStatusEnumMap = {
  AccountProcessingStatus.none: 'none',
  AccountProcessingStatus.pending: 'pending',
  AccountProcessingStatus.processing: 'processing',
  AccountProcessingStatus.completed: 'completed',
  AccountProcessingStatus.failed: 'failed',
};

AccountBalanceModel _$AccountBalanceModelFromJson(Map<String, dynamic> json) =>
    AccountBalanceModel(
      id: json['id'] as String,
      balance: (json['balance'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AccountBalanceModelToJson(
  AccountBalanceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'balance': instance.balance,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
