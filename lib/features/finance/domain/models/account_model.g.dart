// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NextInvoice _$NextInvoiceFromJson(Map<String, dynamic> json) => _NextInvoice(
  dueDate: const DateTimeIsoConverter().fromJson(json['dueDate'] as String),
  closingDate: const DateTimeIsoConverter().fromJson(
    json['closingDate'] as String,
  ),
  cycleStart: const DateTimeIsoConverter().fromJson(
    json['cycleStart'] as String,
  ),
  cycleEnd: const DateTimeIsoConverter().fromJson(json['cycleEnd'] as String),
  amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  orderId: json['orderId'] as String? ?? '',
  installmentId: json['installmentId'] as String?,
  status:
      $enumDecodeNullable(_$InstallmentStatusEnumMap, json['status']) ??
      InstallmentStatus.pending,
  updatedAt: const DateTimeIsoNullableConverter().fromJson(
    json['updatedAt'] as String?,
  ),
);

Map<String, dynamic> _$NextInvoiceToJson(
  _NextInvoice instance,
) => <String, dynamic>{
  'dueDate': const DateTimeIsoConverter().toJson(instance.dueDate),
  'closingDate': const DateTimeIsoConverter().toJson(instance.closingDate),
  'cycleStart': const DateTimeIsoConverter().toJson(instance.cycleStart),
  'cycleEnd': const DateTimeIsoConverter().toJson(instance.cycleEnd),
  'amount': instance.amount,
  'orderId': instance.orderId,
  'installmentId': instance.installmentId,
  'status': _$InstallmentStatusEnumMap[instance.status]!,
  'updatedAt': const DateTimeIsoNullableConverter().toJson(instance.updatedAt),
};

const _$InstallmentStatusEnumMap = {
  InstallmentStatus.pending: 'pending',
  InstallmentStatus.paid: 'paid',
  InstallmentStatus.settled: 'settled',
  InstallmentStatus.removed: 'removed',
};

CheckingAccount _$CheckingAccountFromJson(
  Map<String, dynamic> json,
) => CheckingAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  isDeleted: json['isDeleted'] as bool? ?? false,
  initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
  initialBalanceDate: const DateTimeTwelvePmConverter().fromJson(
    json['initialBalanceDate'] as String,
  ),
  bankLogo:
      $enumDecodeNullable(_$BankLogoEnumMap, json['bankLogo']) ?? BankLogo.none,
  ownerIds:
      (json['ownerIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
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
      'initialBalanceDate': const DateTimeTwelvePmConverter().toJson(
        instance.initialBalanceDate,
      ),
      'bankLogo': _$BankLogoEnumMap[instance.bankLogo]!,
      'ownerIds': instance.ownerIds,
      'runtimeType': instance.$type,
    };

const _$BankLogoEnumMap = {
  BankLogo.none: 'none',
  BankLogo.nubank: 'nubank',
  BankLogo.inter: 'inter',
  BankLogo.itau: 'itau',
  BankLogo.bradesco: 'bradesco',
  BankLogo.santander: 'santander',
  BankLogo.bb: 'bb',
  BankLogo.caixa: 'caixa',
  BankLogo.c6: 'c6',
  BankLogo.xp: 'xp',
  BankLogo.btg: 'btg',
  BankLogo.visa: 'visa',
  BankLogo.mastercard: 'mastercard',
  BankLogo.elo: 'elo',
  BankLogo.amex: 'amex',
};

InvestmentAccount _$InvestmentAccountFromJson(
  Map<String, dynamic> json,
) => InvestmentAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  isDeleted: json['isDeleted'] as bool? ?? false,
  initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
  initialBalanceDate: const DateTimeTwelvePmConverter().fromJson(
    json['initialBalanceDate'] as String,
  ),
  interestRate: (json['interestRate'] as num).toDouble(),
  bankLogo:
      $enumDecodeNullable(_$BankLogoEnumMap, json['bankLogo']) ?? BankLogo.none,
  ownerIds:
      (json['ownerIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
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
      'initialBalanceDate': const DateTimeTwelvePmConverter().toJson(
        instance.initialBalanceDate,
      ),
      'interestRate': instance.interestRate,
      'bankLogo': _$BankLogoEnumMap[instance.bankLogo]!,
      'ownerIds': instance.ownerIds,
      'runtimeType': instance.$type,
    };

CreditCardAccount _$CreditCardAccountFromJson(
  Map<String, dynamic> json,
) => CreditCardAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  isDeleted: json['isDeleted'] as bool? ?? false,
  initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
  initialBalanceDate: const DateTimeTwelvePmConverter().fromJson(
    json['initialBalanceDate'] as String,
  ),
  limit: (json['limit'] as num).toDouble(),
  dueDay: (json['dueDay'] as num).toInt(),
  closingDay: (json['closingDay'] as num).toInt(),
  bankLogo:
      $enumDecodeNullable(_$BankLogoEnumMap, json['bankLogo']) ?? BankLogo.none,
  ownerIds:
      (json['ownerIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  nextInvoice: json['nextInvoice'] == null
      ? null
      : NextInvoice.fromJson(json['nextInvoice'] as Map<String, dynamic>),
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
      'initialBalanceDate': const DateTimeTwelvePmConverter().toJson(
        instance.initialBalanceDate,
      ),
      'limit': instance.limit,
      'dueDay': instance.dueDay,
      'closingDay': instance.closingDay,
      'bankLogo': _$BankLogoEnumMap[instance.bankLogo]!,
      'ownerIds': instance.ownerIds,
      'runtimeType': instance.$type,
    };

DebtAccount _$DebtAccountFromJson(Map<String, dynamic> json) => DebtAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  isDeleted: json['isDeleted'] as bool? ?? false,
  initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
  initialBalanceDate: const DateTimeTwelvePmConverter().fromJson(
    json['initialBalanceDate'] as String,
  ),
  interestRate: (json['interestRate'] as num).toDouble(),
  bankLogo:
      $enumDecodeNullable(_$BankLogoEnumMap, json['bankLogo']) ?? BankLogo.none,
  ownerIds:
      (json['ownerIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
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
      'initialBalanceDate': const DateTimeTwelvePmConverter().toJson(
        instance.initialBalanceDate,
      ),
      'interestRate': instance.interestRate,
      'bankLogo': _$BankLogoEnumMap[instance.bankLogo]!,
      'ownerIds': instance.ownerIds,
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
