import 'dart:developer';
import 'dart:io';

import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:uuid/uuid.dart';

class AccountFormNotifier extends FormNotifier<AccountFormState, void> {
  final AccountService accountService;
  final CategoryService categoryService;
  final FinanceService financeService;

  AccountFormNotifier({
    AccountModel? account,
    AccountType? type,
    required this.accountService,
    required this.categoryService,
    required this.financeService,
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

  Future<void> updateFile(File? file, String? name) async {
    state = state.copyWith(
      selectedFile: file,
      processingStatus: file != null
          ? AccountProcessingStatus.pending
          : AccountProcessingStatus.none,
      detectedOrders: [],
    );

    if (file != null && name != null) {
      try {
        // 2. Chamar análise passando o storagePath
        final analysis = await accountService.analyzeDocument(file);

        final accountData = analysis.account;

        state = state.copyWith(
          name: accountData.name,
          type: accountData.type,
          color: accountData.color,
          icon: accountData.icon,
          initialBalance: accountData.initialBalance,
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

        state = state.copyWith(
          processingStatus: AccountProcessingStatus.failed,
        );
      }
    }
  }

  @override
  Future<void> submit() async {
    AccountModel account = state.asAccountModel();

    if (state.originalAccount == null) {
      await accountService.create(account);

      state = state.copyWith(originalAccount: account);
    } else {
      accountService.update(account);
    }

    // 1. Garantir que as categorias existam
    final categories = List.from(await categoryService.getCategories().first);

    // 2. Processar Orders
    final processedOrders = <OrderModel>[];
    for (final order in state.detectedOrders) {
      if (order.category != null) {
        String categoryId = await _findOrCreateCategory(
          categories,
          order.category!,
        );

        processedOrders.add(
          order.copyWith(
            category: order.category?.copyWith(id: categoryId),
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

  Future<String> _findOrCreateCategory(
    List<dynamic> categories,
    CategoryModel category,
  ) async {
    String? categoryId = categories
        .where((c) => c.name.toLowerCase() == category.name.toLowerCase())
        .firstOrNull
        ?.id;

    if (categoryId == null) {
      categoryId = const Uuid().v4();
      final newCategory = category.copyWith(id: categoryId);

      await categoryService.create(newCategory);

      categories.add(newCategory);
    }

    return categoryId;
  }
}
