import 'dart:developer';

import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/core/files/picked_document.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:uuid/uuid.dart';

class AccountFormNotifier extends FormNotifier<AccountFormState, void>
    with TracksWriteOutcome {
  final AccountService accountService;
  final CategoryService categoryService;
  final FinanceService financeService;
  final AnalyticsService analytics;

  AccountFormNotifier({
    AccountModel? account,
    AccountType? type,
    required this.accountService,
    required this.categoryService,
    required this.financeService,
    required this.analytics,
  }) : super(AccountFormState.initial(account: account, type: type));

  void updateName(String value) => state = state.copyWith(name: value);

  void updateInitialBalance(double value) =>
      state = state.copyWith(initialBalance: value);

  void updateInitialBalanceDate(DateTime value) =>
      state = state.copyWith(initialBalanceDate: value);

  void updateType(AccountType value) => state = state.copyWith(type: value);

  void updateColor(String value) => state = state.copyWith(color: value);

  void updateIcon(String value) => state = state.copyWith(icon: value);

  void updateRegistrationMethod(AccountRegistrationMethod value) =>
      state = state.copyWith(registrationMethod: value);

  void updateLimit(double limit) => state = state.copyWith(limit: limit);

  void updateDueDay(int dueDay) => state = state.copyWith(dueDay: dueDay);

  void updateClosingDay(int closingDay) =>
      state = state.copyWith(closingDay: closingDay);

  void updateInterestRate(double interestRate) =>
      state = state.copyWith(interestRate: interestRate);

  void updateBankLogo(BankLogo bankLogo) {
    state = state.copyWith(bankLogo: bankLogo);
    if (bankLogo.defaultColor != null) {
      state = state.copyWith(color: bankLogo.defaultColor!);
    }
  }

  void updateOwnerIds(List<String> ownerIds) =>
      state = state.copyWith(ownerIds: ownerIds);

  Future<void> updateFile(PickedDocument? document) async {
    state = state.copyWith(
      selectedFile: document,
      processingStatus: document != null
          ? AccountProcessingStatus.pending
          : AccountProcessingStatus.none,
      detectedOrders: [],
    );

    if (document != null) {
      try {
        // 2. Chamar análise passando o storagePath
        final analysis = await accountService.analyzeDocument(document);

        final accountData = analysis.account;

        state = state.copyWith(
          name: accountData.name,
          type: accountData.type,
          color: accountData.color,
          icon: accountData.icon,
          initialBalance: accountData.initialBalance,
          initialBalanceDate: accountData.initialBalanceDate,
          limit: accountData.mapOrNull(creditCard: (value) => value.limit),
          dueDay: accountData.mapOrNull(creditCard: (value) => value.dueDay),
          closingDay: accountData.mapOrNull(
            creditCard: (value) => value.closingDay,
          ),
          interestRate: accountData.mapOrNull(
            investment: (value) => value.interestRate,
            debt: (value) => value.interestRate,
          ),
          detectedOrders: analysis.orders,
          processingStatus: AccountProcessingStatus.completed,
        );
      } catch (e) {
        log(e.toString());

        final rawMessage = e.toString().contains('BusinessException')
            ? e.toString().split(':').last.trim()
            : e.toString();

        state = state.copyWith(
          processingStatus: AccountProcessingStatus.failed,
          // Limite diário de IA tem mensagem própria do servidor, já pronta
          // para o usuário.
          errorMessage: callableErrorMessage(e, rawMessage),
        );
      }
    }
  }

  @override
  Future<void> submit() async {
    beginWrite();

    AccountModel account = state.asAccountModel();

    if (state.originalAccount == null) {
      final created = await accountService.create(account);

      account = created.value;
      recordWrite(created.outcome);

      state = state.copyWith(originalAccount: account);

      // Analytics nunca derruba a criação da conta.
      try {
        await analytics.logAccountCreated(account.type.name);
      } catch (_) {}
    } else {
      await accountService.update(account);
    }

    // 1. Garantir que as categorias existam
    final categories = [...await categoryService.getCategories().first];

    // 2. Processar Orders
    final processedOrders = <OrderModel>[];
    for (final order in state.detectedOrders) {
      if (order.category != null) {
        final category = await _findOrCreateCategory(
          categories,
          order.category!,
        );

        processedOrders.add(
          order.copyWith(
            installmentCreationStatus: InstallmentStatus.settled,
            category: category,
            accounts: {
              account.id: order.type == OrderType.expense
                  ? AccountImpact.debt
                  : AccountImpact.credit,
            },
          ),
        );
      }
    }

    // 5. Salvar Orders e Plannings
    await Future.wait(
      processedOrders.map((order) => financeService.addOrder(order)),
    );
  }

  Future<CategoryModel> _findOrCreateCategory(
    List<CategoryModel> categories,
    CategoryModel category,
  ) async {
    final CategoryModel? found = categories
        .where(
          (c) =>
              c.type == category.type &&
              c.name.toLowerCase() == category.name.toLowerCase(),
        )
        .firstOrNull;

    if (found == null) {
      final newCategory = (await categoryService.create(
        category.copyWith(id: const Uuid().v4()),
      )).value;

      categories.add(newCategory);

      return newCategory;
    }

    return found;
  }
}
