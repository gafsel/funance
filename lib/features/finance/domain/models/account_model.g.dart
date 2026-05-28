// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckingAccount _$CheckingAccountFromJson(Map<String, dynamic> json) =>
    CheckingAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0.0,
      initialBalanceDate: DateTime.parse(
        json['initial_balance_date'] as String,
      ),
      filePath: json['file_path'] as String?,
      fileName: json['file_name'] as String?,
      processingStatus:
          $enumDecodeNullable(
            _$AccountProcessingStatusEnumMap,
            json['processing_status'],
          ) ??
          AccountProcessingStatus.none,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CheckingAccountToJson(CheckingAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initial_balance': instance.initialBalance,
      'initial_balance_date': instance.initialBalanceDate.toIso8601String(),
      'file_path': instance.filePath,
      'file_name': instance.fileName,
      'processing_status':
          _$AccountProcessingStatusEnumMap[instance.processingStatus]!,
      'runtimeType': instance.$type,
    };

const _$AccountProcessingStatusEnumMap = {
  AccountProcessingStatus.none: 'none',
  AccountProcessingStatus.pending: 'pending',
  AccountProcessingStatus.processing: 'processing',
  AccountProcessingStatus.completed: 'completed',
  AccountProcessingStatus.failed: 'failed',
};

InvestmentAccount _$InvestmentAccountFromJson(Map<String, dynamic> json) =>
    InvestmentAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0.0,
      initialBalanceDate: DateTime.parse(
        json['initial_balance_date'] as String,
      ),
      filePath: json['file_path'] as String?,
      fileName: json['file_name'] as String?,
      processingStatus:
          $enumDecodeNullable(
            _$AccountProcessingStatusEnumMap,
            json['processing_status'],
          ) ??
          AccountProcessingStatus.none,
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$InvestmentAccountToJson(InvestmentAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initial_balance': instance.initialBalance,
      'initial_balance_date': instance.initialBalanceDate.toIso8601String(),
      'file_path': instance.filePath,
      'file_name': instance.fileName,
      'processing_status':
          _$AccountProcessingStatusEnumMap[instance.processingStatus]!,
      'interestRate': instance.interestRate,
      'runtimeType': instance.$type,
    };

CreditCardAccount _$CreditCardAccountFromJson(Map<String, dynamic> json) =>
    CreditCardAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0.0,
      initialBalanceDate: DateTime.parse(
        json['initial_balance_date'] as String,
      ),
      filePath: json['file_path'] as String?,
      fileName: json['file_name'] as String?,
      processingStatus:
          $enumDecodeNullable(
            _$AccountProcessingStatusEnumMap,
            json['processing_status'],
          ) ??
          AccountProcessingStatus.none,
      limit: (json['limit'] as num?)?.toDouble(),
      dueDay: (json['due_day'] as num?)?.toInt(),
      closingDay: (json['closing_day'] as num?)?.toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CreditCardAccountToJson(CreditCardAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initial_balance': instance.initialBalance,
      'initial_balance_date': instance.initialBalanceDate.toIso8601String(),
      'file_path': instance.filePath,
      'file_name': instance.fileName,
      'processing_status':
          _$AccountProcessingStatusEnumMap[instance.processingStatus]!,
      'limit': instance.limit,
      'due_day': instance.dueDay,
      'closing_day': instance.closingDay,
      'runtimeType': instance.$type,
    };

DebtAccount _$DebtAccountFromJson(Map<String, dynamic> json) => DebtAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
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
  interestRate: (json['interestRate'] as num?)?.toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$DebtAccountToJson(DebtAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initial_balance': instance.initialBalance,
      'initial_balance_date': instance.initialBalanceDate.toIso8601String(),
      'file_path': instance.filePath,
      'file_name': instance.fileName,
      'processing_status':
          _$AccountProcessingStatusEnumMap[instance.processingStatus]!,
      'interestRate': instance.interestRate,
      'runtimeType': instance.$type,
    };

_AccountBalanceModel _$AccountBalanceModelFromJson(Map<String, dynamic> json) =>
    _AccountBalanceModel(
      id: json['id'] as String,
      balance: (json['balance'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AccountBalanceModelToJson(
  _AccountBalanceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'balance': instance.balance,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
