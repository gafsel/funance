import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/utils/date_time_converter.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

enum AccountType {
  @JsonValue('checking')
  checking,
  @JsonValue('investment')
  investment,
  @JsonValue('creditCard')
  creditCard,
  @JsonValue('debt')
  debt,
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
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
  }) = CheckingAccount;

  const factory AccountModel.investment({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
    required double interestRate,
  }) = InvestmentAccount;

  const factory AccountModel.creditCard({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
    required double limit,
    required int dueDay,
    required int closingDay,
  }) = CreditCardAccount;

  const factory AccountModel.debt({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
    required double interestRate,
  }) = DebtAccount;

  AccountType get type => map(
    checking: (_) => AccountType.checking,
    investment: (_) => AccountType.investment,
    creditCard: (_) => AccountType.creditCard,
    debt: (_) => AccountType.debt,
  );

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);
}

@freezed
sealed class AccountBalanceModel with _$AccountBalanceModel {
  const AccountBalanceModel._();

  const factory AccountBalanceModel({
    required String id, // Date string YYYY-MM-DD
    required double balance,
    required DateTime updatedAt,
  }) = _AccountBalanceModel;

  factory AccountBalanceModel.zero() =>
      AccountBalanceModel(id: "", balance: 0, updatedAt: DateTime.now());

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$AccountBalanceModelFromJson(json);
}

@freezed
sealed class AccountDocumentAnalysisResult with _$AccountDocumentAnalysisResult {
  factory AccountDocumentAnalysisResult({
    required AccountModel account,
    @Default([]) List<OrderModel> orders,
  }) = _AccountDocumentAnalysisResult;

  const AccountDocumentAnalysisResult._();

  factory AccountDocumentAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AccountDocumentAnalysisResultFromJson(json);
}
