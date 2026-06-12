
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:uuid/uuid.dart';

part 'account_view_models.freezed.dart';


@freezed
sealed class AccountFormArgs with _$AccountFormArgs {
  factory AccountFormArgs({AccountModel? account, AccountType? type}) = _AccountFormArgs;
}


enum AccountRegistrationMethod { document, manual }

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
sealed class AccountFormState with _$AccountFormState {
  const AccountFormState._();

  const factory AccountFormState({
    AccountModel? originalAccount,
    required String name,
    required double initialBalance,
    required DateTime initialBalanceDate,
    required String color,
    required String icon,
    required AccountType type,
    double? limit,
    int? dueDay,
    int? closingDay,
    double? interestRate,
    File? selectedFile,
    @Default(AccountProcessingStatus.none)
    AccountProcessingStatus processingStatus,
    String? errorMessage,
    @Default(AccountRegistrationMethod.document)
    AccountRegistrationMethod registrationMethod,
    @Default([]) List<OrderModel> detectedOrders,
  }) = _AccountFormState;

  bool get creation => originalAccount == null;

  factory AccountFormState.initial({AccountModel? account, AccountType? type}) {
    return AccountFormState(
      originalAccount: account,
      name: account?.name ?? '',
      initialBalance: account?.initialBalance ?? 0.0,
      initialBalanceDate: account?.initialBalanceDate ?? DateTime.now(),
      color: account?.color ?? '#4A8C9C',
      icon: account?.icon ?? 'account_balance',
      type: account?.type ?? type ?? AccountType.checking,
      limit: account?.mapOrNull(creditCard: (cc) => cc.limit),
      dueDay: account?.mapOrNull(creditCard: (cc) => cc.dueDay),
      closingDay: account?.mapOrNull(creditCard: (cc) => cc.closingDay),
      interestRate: account?.mapOrNull(
        debt: (cc) => cc.interestRate,
        investment: (cc) => cc.interestRate,
      ),
      processingStatus: AccountProcessingStatus.none,
      registrationMethod: account != null
          ? AccountRegistrationMethod.manual
          : AccountRegistrationMethod.document,
    );
  }

  AccountModel asAccountModel() {
    if (originalAccount != null) {
      return originalAccount!
          .copyWith(
        name: name,
        icon: icon,
        color: color,
        initialBalanceDate: initialBalanceDate,
        initialBalance: initialBalance,
      )
          .map(
        checking: (checking) => checking,
        investment: (investment) =>
            investment.copyWith(interestRate: interestRate!),
        creditCard: (creditCard) => creditCard.copyWith(
          dueDay: dueDay!,
          closingDay: closingDay!,
          limit: limit!,
        ),
        debt: (debt) => debt.copyWith(interestRate: interestRate!),
      );
    }

    switch (type) {
      case AccountType.checking:
        return AccountModel.checking(
          id: originalAccount?.id ?? Uuid().v4(),
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          initialBalance: initialBalance,
        );
      case AccountType.creditCard:
        return AccountModel.creditCard(
          id: originalAccount?.id ?? Uuid().v4(),
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          initialBalance: initialBalance,
          closingDay: closingDay!,
          dueDay: dueDay!,
          limit: limit!,
        );
      case AccountType.investment:
        return AccountModel.investment(
          id: originalAccount?.id ?? Uuid().v4(),
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          initialBalance: initialBalance,
          interestRate: interestRate!,
        );
      case AccountType.debt:
        return AccountModel.debt(
          id: originalAccount?.id ?? Uuid().v4(),
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          interestRate: interestRate!,
          initialBalance: initialBalance,
        );
    }
  }
}

@freezed
sealed class CategoryAmountModel with _$CategoryAmountModel {

  factory CategoryAmountModel({
    required CategoryModel category,
    required double amount,
  }) = _CategoryAmountModel;

}
