import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:funances/features/workspace/presentation/providers/category_providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers/workspace_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_form_provider.freezed.dart';

enum AccountRegistrationMethod { document, manual }

@freezed
sealed class AccountFormState with _$AccountFormState {
  const AccountFormState._();

  const factory AccountFormState({
    required String id,
    required String name,
    required double initialBalance,
    required DateTime initialBalanceDate,
    required AccountType type,
    required String color,
    required String icon,
    double? limit,
    int? dueDay,
    int? closingDay,
    double? interestRate,
    File? selectedFile,
    String? fileName,
    @Default(AccountProcessingStatus.none)
    AccountProcessingStatus processingStatus,
    @Default(AccountRegistrationMethod.document)
    AccountRegistrationMethod registrationMethod,
    @Default([]) List<OrderModel> detectedOrders,
    @Default([]) List<PlanningModel> detectedPlannings,
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _AccountFormState;

  factory AccountFormState.initial(
    AccountModel? account,
    AccountType? initialType,
  ) {
    return AccountFormState(
      id: account?.id ?? Uuid().v4(),
      name: account?.name ?? '',
      initialBalance: account?.initialBalance ?? 0.0,
      initialBalanceDate: account?.initialBalanceDate ?? DateTime.now(),
      type: account?.type ?? initialType ?? AccountType.checking,
      color: account?.color ?? '#4A8C9C',
      icon: account?.icon ?? 'account_balance',
      limit: account is CreditCardAccount ? account.limit : null,
      dueDay: account is CreditCardAccount ? account.dueDay : null,
      closingDay: account is CreditCardAccount ? account.closingDay : null,
      interestRate: account is InvestmentAccount
          ? account.interestRate
          : account is DebtAccount
          ? account.interestRate
          : null,
      fileName: account?.fileName,
      processingStatus:
          account?.processingStatus ?? AccountProcessingStatus.none,
      registrationMethod: account != null
          ? AccountRegistrationMethod.manual
          : AccountRegistrationMethod.document,
    );
  }

  AccountModel asAccountModel() {
    switch (type) {
      case AccountType.checking:
        return AccountModel.checking(
          id: id,
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          initialBalance: initialBalance,
        );
      case AccountType.creditCard:
        return AccountModel.creditCard(
          id: id,
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          initialBalance: initialBalance,
          closingDay: closingDay,
          dueDay: dueDay,
          limit: limit,
        );
      case AccountType.investment:
        return AccountModel.investment(
          id: id,
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          initialBalance: initialBalance,
          interestRate: interestRate,
        );
      case AccountType.debt:
        return AccountModel.debt(
          id: id,
          name: name,
          icon: icon,
          color: color,
          initialBalanceDate: initialBalanceDate,
          interestRate: interestRate,
          initialBalance: initialBalance,
        );
    }
  }
}

class AccountFormNotifier extends StateNotifier<AccountFormState> {
  final Ref ref;
  final AccountModel? initialAccount;

  AccountFormNotifier(this.ref, this.initialAccount, AccountType? initialType)
    : super(AccountFormState.initial(initialAccount, initialType));

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

  Future<void> updateFile(File? file, String? name) async {
    state = state.copyWith(
      selectedFile: file,
      fileName: name,
      processingStatus: file != null
          ? AccountProcessingStatus.pending
          : AccountProcessingStatus.none,
      detectedOrders: [],
      detectedPlannings: [],
    );

    if (file != null && name != null) {
      state = state.copyWith(isLoading: true);
      try {
        final workspaceId = ref
            .read(onboardingNotifierProvider)
            .createdWorkspaceId;
        final existingCategoryNames = <String>[];

        // 1. Upload para o Storage
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = workspaceId.isNotEmpty
            ? 'onboarding_attachments/$workspaceId/${timestamp}_$name'
            : 'onboarding_attachments/temp/${timestamp}_$name';

        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        await storageRef.putFile(file);

        if (workspaceId.isNotEmpty) {
          final categories = await ref
              .read(categoryRepositoryProvider)
              .getCategories(workspaceId)
              .first;
          existingCategoryNames.addAll(categories.map((c) => c.name));
        }

        // 2. Chamar análise passando o storagePath
        final analysis = await ref
            .read(onboardingServiceProvider)
            .analyzeDocument(
              storagePath: storagePath,
              fileName: name,
              existingCategories: existingCategoryNames,
            );

        final accountData = analysis.accountData;

        final orders = analysis.orders.map((o) {
          final type = o['type'] == 'income'
              ? OrderType.income
              : OrderType.expense;
          final commonFields = {
            'id': const Uuid().v4(),
            'description': o['description'] ?? '',
            'totalAmount': (o['totalAmount'] as num?)?.toDouble() ?? 0.0,
            'status': 'paid',
            'category': {
              'id': '',
              'name': o['categoryName'] ?? 'Uncategorized',
              'color': o['categoryColor'] ?? '#4A8C9C',
              'icon': o['categoryIcon'] ?? 'category',
              'type': o['type'] == 'income' ? 'income' : 'expense',
            },
            'installmentsCount': 1,
            'date':
                DateTime.tryParse(o['date'] ?? '')?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            'runtimeType': type.name,
          };
          return OrderModel.fromJson(commonFields);
        }).toList();

        final plannings = analysis.plannings.map((p) {
          final type = p['type'] == 'recurrent'
              ? PlanningType.recurrent
              : PlanningType.unique;
          final commonFields = {
            'id': const Uuid().v4(),
            'category': {
              'id': '',
              'name': p['categoryName'] ?? 'Uncategorized',
              'color': p['categoryColor'] ?? '#4A8C9C',
              'icon': p['categoryIcon'] ?? 'category',
              'type': 'expense',
            },
            'amount': (p['amount'] as num?)?.toDouble() ?? 0.0,
            'startDate': DateTime.now().toIso8601String(),
            'endDate': DateTime.now()
                .add(const Duration(days: 365 * 99))
                .toIso8601String(),
            'runtimeType': type.name,
          };
          return PlanningModel.fromJson(commonFields);
        }).toList();

        state = state.copyWith(
          name: accountData['name'] ?? state.name,
          type: AccountType.values.byName(accountData['type']),
          color: accountData['color'] ?? state.color,
          icon: accountData['icon'] ?? state.icon,
          initialBalance: _parseSafeDouble(accountData['initialBalance']),
          limit: (accountData['metadata']?['limit'] as num?)?.toDouble(),
          dueDay: accountData['metadata']?['dueDay'] as int?,
          closingDay: accountData['metadata']?['closingDay'] as int?,
          interestRate: (accountData['metadata']?['interestRate'] as num?)
              ?.toDouble(),
          detectedOrders: orders,
          detectedPlannings: plannings,
          processingStatus: AccountProcessingStatus.completed,
          isLoading: false,
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          processingStatus: AccountProcessingStatus.failed,
          errorMessage: e.toString(),
        );
      }
    }
  }

  double _parseSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    final d = (value is num) ? value.toDouble() : 0.0;
    return d.isFinite ? d : 0.0;
  }

  void updateMetadata(String key, dynamic value) {
    if (key == 'limit') {
      state = state.copyWith(limit: (value as num?)?.toDouble());
    } else if (key == 'dueDay') {
      state = state.copyWith(dueDay: value as int?);
    } else if (key == 'closingDay') {
      state = state.copyWith(closingDay: value as int?);
    } else if (key == 'interestRate') {
      state = state.copyWith(interestRate: (value as num?)?.toDouble());
    }
  }

  Future<void> submit({
    Function(AccountModel, List<OrderModel>, List<PlanningModel>)? onSave,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final workspaceId = ref
        .read(workspaceNotifierProvider)
        .currentWorkspace
        ?.id;
    if (workspaceId == null && onSave == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Workspace not found',
      );
      return;
    }

    AccountModel account = state.asAccountModel();

    try {
      if (onSave != null) {
        onSave(account, state.detectedOrders, state.detectedPlannings);
      } else {
        // 1. Garantir que as categorias existam
        final categories = await ref
            .read(categoryRepositoryProvider)
            .getCategories(workspaceId!)
            .first;
        final Map<String, String> categoryMap = {
          for (final c in categories) c.name.toLowerCase(): c.id,
        };

        // 2. Processar Orders
        final processedOrders = <OrderModel>[];
        for (final order in state.detectedOrders) {
          final categoryName = order.category.name.toLowerCase();
          String categoryId = categoryMap[categoryName] ?? '';

          if (categoryId.isEmpty) {
            final newCategoryId = const Uuid().v4();
            final newCategory = CategoryModel(
              id: newCategoryId,
              name: order.category.name,
              color: order.category.color,
              icon: order.category.icon,
              type: order.type == OrderType.income
                  ? CategoryType.income
                  : CategoryType.expense,
            );
            await ref
                .read(categoryRepositoryProvider)
                .createCategory(workspaceId, newCategory);
            categoryMap[categoryName] = newCategoryId;
            categoryId = newCategoryId;
          }

          processedOrders.add(
            order
                .copyWith(category: order.category.copyWith(id: categoryId))
                .map(
                  expense: (o) => o.copyWith(accountId: state.id),
                  income: (o) => o.copyWith(accountId: state.id),
                  transfer: (o) => o.copyWith(fromAccountId: state.id),
                ),
          );
        }

        // 3. Processar Plannings
        final processedPlannings = <PlanningModel>[];
        for (final planning in state.detectedPlannings) {
          final categoryName = planning.category.name.toLowerCase();
          String categoryId = categoryMap[categoryName] ?? '';

          if (categoryId.isEmpty) {
            final newCategoryId = const Uuid().v4();
            final newCategory = CategoryModel(
              id: newCategoryId,
              name: planning.category.name,
              color: planning.category.color,
              icon: planning.category.icon,
              type: CategoryType.expense,
            );
            await ref
                .read(categoryRepositoryProvider)
                .createCategory(workspaceId, newCategory);
            categoryMap[categoryName] = newCategoryId;
            categoryId = newCategoryId;
          }

          processedPlannings.add(
            planning
                .copyWith(category: planning.category.copyWith(id: categoryId))
                .map(
                  unique: (p) => p.copyWith(accountId: state.id),
                  recurrent: (p) => p.copyWith(accountId: state.id),
                  parcelado: (p) => p.copyWith(accountId: state.id),
                ),
          );
        }

        // 4. Salvar Conta
        if (initialAccount == null) {
          await ref
              .read(accountNotifierProvider.notifier)
              .createAccount(account);
        } else {
          await ref
              .read(accountNotifierProvider.notifier)
              .updateAccount(account);
        }

        // 5. Salvar Orders e Plannings
        for (final order in processedOrders) {
          await ref
              .read(financeRepositoryProvider)
              .addOrder(workspaceId, order);
        }
        for (final planning in processedPlannings) {
          await ref
              .read(financeRepositoryProvider)
              .addPlanning(workspaceId, planning);
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final accountFormProvider =
    StateNotifierProvider.family<
      AccountFormNotifier,
      AccountFormState,
      AccountFormArgs
    >((ref, args) {
      return AccountFormNotifier(ref, args.account, args.initialType);
    });

class AccountFormArgs {
  final AccountModel? account;
  final AccountType? initialType;

  AccountFormArgs({this.account, this.initialType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountFormArgs &&
          runtimeType == other.runtimeType &&
          account?.id == other.account?.id &&
          initialType == other.initialType;

  @override
  int get hashCode => (account?.id.hashCode ?? 0) ^ initialType.hashCode;
}
