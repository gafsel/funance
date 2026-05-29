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
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      initialBalanceDate: DateTime.parse(json['initialBalanceDate'] as String),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CheckingAccountToJson(CheckingAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initialBalance': instance.initialBalance,
      'initialBalanceDate': instance.initialBalanceDate.toIso8601String(),
      'runtimeType': instance.$type,
    };

InvestmentAccount _$InvestmentAccountFromJson(Map<String, dynamic> json) =>
    InvestmentAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      initialBalanceDate: DateTime.parse(json['initialBalanceDate'] as String),
      interestRate: (json['interestRate'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$InvestmentAccountToJson(InvestmentAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initialBalance': instance.initialBalance,
      'initialBalanceDate': instance.initialBalanceDate.toIso8601String(),
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
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      initialBalanceDate: DateTime.parse(json['initialBalanceDate'] as String),
      limit: (json['limit'] as num).toDouble(),
      dueDay: (json['dueDay'] as num).toInt(),
      closingDay: (json['closingDay'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CreditCardAccountToJson(CreditCardAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initialBalance': instance.initialBalance,
      'initialBalanceDate': instance.initialBalanceDate.toIso8601String(),
      'limit': instance.limit,
      'dueDay': instance.dueDay,
      'closingDay': instance.closingDay,
      'runtimeType': instance.$type,
    };

DebtAccount _$DebtAccountFromJson(Map<String, dynamic> json) => DebtAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  isDeleted: json['isDeleted'] as bool? ?? false,
  initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
  initialBalanceDate: DateTime.parse(json['initialBalanceDate'] as String),
  interestRate: (json['interestRate'] as num).toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$DebtAccountToJson(DebtAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'isDeleted': instance.isDeleted,
      'initialBalance': instance.initialBalance,
      'initialBalanceDate': instance.initialBalanceDate.toIso8601String(),
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

_AccountDocumentAnalysisResult _$AccountDocumentAnalysisResultFromJson(
  Map<String, dynamic> json,
) => _AccountDocumentAnalysisResult(
  account: AccountModel.fromJson(json['account'] as Map<String, dynamic>),
  orders:
      (json['orders'] as List<dynamic>?)
          ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$AccountDocumentAnalysisResultToJson(
  _AccountDocumentAnalysisResult instance,
) => <String, dynamic>{'account': instance.account, 'orders': instance.orders};
