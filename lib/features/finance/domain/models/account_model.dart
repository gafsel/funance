import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

enum AccountType {
  @JsonValue('checking')
  checking,
  @JsonValue('investment')
  investment,
  @JsonValue('credit_card')
  creditCard,
  @JsonValue('debt')
  debt,
}

enum AccountProcessingStatus {
  @JsonValue('none')
  none,
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

@freezed
sealed class AccountModel with _$AccountModel {
  const AccountModel._();

  const factory AccountModel.checking({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @JsonKey(name: 'initial_balance') @Default(0.0) double initialBalance,
    @JsonKey(name: 'initial_balance_date') required DateTime initialBalanceDate,
    @JsonKey(name: 'file_path') String? filePath,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'processing_status') @Default(AccountProcessingStatus.none) AccountProcessingStatus processingStatus,
  }) = CheckingAccount;

  const factory AccountModel.investment({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @JsonKey(name: 'initial_balance') @Default(0.0) double initialBalance,
    @JsonKey(name: 'initial_balance_date') required DateTime initialBalanceDate,
    @JsonKey(name: 'file_path') String? filePath,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'processing_status') @Default(AccountProcessingStatus.none) AccountProcessingStatus processingStatus,
    double? interestRate,
  }) = InvestmentAccount;

  const factory AccountModel.creditCard({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @JsonKey(name: 'initial_balance') @Default(0.0) double initialBalance,
    @JsonKey(name: 'initial_balance_date') required DateTime initialBalanceDate,
    @JsonKey(name: 'file_path') String? filePath,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'processing_status') @Default(AccountProcessingStatus.none) AccountProcessingStatus processingStatus,
    double? limit,
    @JsonKey(name: 'due_day') int? dueDay,
    @JsonKey(name: 'closing_day') int? closingDay,
  }) = CreditCardAccount;

  const factory AccountModel.debt({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @JsonKey(name: 'initial_balance') @Default(0.0) double initialBalance,
    @JsonKey(name: 'initial_balance_date') required DateTime initialBalanceDate,
    @JsonKey(name: 'file_path') String? filePath,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'processing_status') @Default(AccountProcessingStatus.none) AccountProcessingStatus processingStatus,
    double? interestRate,
  }) = DebtAccount;

  AccountType get type => map(
    checking: (_) => AccountType.checking,
    investment: (_) => AccountType.investment,
    creditCard: (_) => AccountType.creditCard,
    debt: (_) => AccountType.debt,
  );

  factory AccountModel.fromJson(Map<String, dynamic> json) => _$AccountModelFromJson(json);
}

@freezed
sealed class AccountBalanceModel with _$AccountBalanceModel {
  const AccountBalanceModel._();
  const factory AccountBalanceModel({
    required String id, // Date string YYYY-MM-DD
    required double balance,
    @JsonKey(name: 'updatedAt') required DateTime updatedAt,
  }) = _AccountBalanceModel;

  factory AccountBalanceModel.zero() => AccountBalanceModel(id: "", balance: 0, updatedAt: DateTime.now());

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) => _$AccountBalanceModelFromJson(json);
}
