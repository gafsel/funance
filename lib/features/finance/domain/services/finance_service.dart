import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';

class FinanceService {
  final String workspaceId;
  final IFinanceRepository repository;
  final IAccountRepository accountRepository;
  final ICategoryRepository categoryRepository;

  FinanceService({
    required this.workspaceId,
    required this.repository,
    required this.accountRepository,
    required this.categoryRepository,
  });

  Future<OrderModel> addOrder(OrderModel order) async {
    final processedOrder = await _processVirtualCategory(order);
    return await repository.addOrder(workspaceId, processedOrder);
  }

  Future<void> updateOrder(OrderModel order) async {
    final processedOrder = await _processVirtualCategory(order);
    await repository.updateOrder(workspaceId, processedOrder);
  }

  Future<void> updateInstallment(InstallmentModel installment) async {
    final processedInstallment = await _processVirtualCategoryInstallment(
      installment,
    );
    await repository.updateInstallment(workspaceId, processedInstallment);
  }

  Future<AccountModel> getAccount(String accountId) async {
    return await accountRepository.getAccount(workspaceId, accountId);
  }

  Future<OrderModel> _processVirtualCategory(OrderModel order) async {
    if (order.type != OrderType.transfer) return order;

    final sourceId = order.accountIdSource;
    final targetId = order.accountIdTarget;

    if (sourceId == null && targetId == null) return order;

    AccountModel? sourceAccount;
    AccountModel? targetAccount;

    if (sourceId != null) {
      sourceAccount = await accountRepository.getAccount(workspaceId, sourceId);
    }

    if (targetId != null) {
      targetAccount = await accountRepository.getAccount(workspaceId, targetId);
    }

    CategoryModel? virtualCategory;

    if (targetAccount != null &&
        (targetAccount.type == AccountType.debt ||
            targetAccount.type == AccountType.investment)) {
      virtualCategory = await _getVirtualCategoryForAccountType(
        targetAccount.type,
        CategoryType.expense,
      );
    } else if (sourceAccount != null &&
        (sourceAccount.type == AccountType.debt ||
            sourceAccount.type == AccountType.investment)) {
      virtualCategory = await _getVirtualCategoryForAccountType(
        sourceAccount.type,
        CategoryType.income,
      );
    }

    if (virtualCategory != null) {
      return order.copyWith(category: virtualCategory);
    }

    return order;
  }

  Future<InstallmentModel> _processVirtualCategoryInstallment(
    InstallmentModel installment,
  ) async {
    if (installment.type != OrderType.transfer) return installment;

    final sourceId = installment.accountIdSource;
    final targetId = installment.accountIdTarget;

    if (sourceId == null && targetId == null) return installment;

    AccountModel? sourceAccount;
    AccountModel? targetAccount;

    if (sourceId != null) {
      sourceAccount = await accountRepository.getAccount(workspaceId, sourceId);
    }

    if (targetId != null) {
      targetAccount = await accountRepository.getAccount(workspaceId, targetId);
    }

    CategoryModel? virtualCategory;

    if (targetAccount != null &&
        (targetAccount.type == AccountType.debt ||
            targetAccount.type == AccountType.investment)) {
      virtualCategory = await _getVirtualCategoryForAccountType(
        targetAccount.type,
        CategoryType.expense,
      );
    } else if (sourceAccount != null &&
        (sourceAccount.type == AccountType.debt ||
            sourceAccount.type == AccountType.investment)) {
      virtualCategory = await _getVirtualCategoryForAccountType(
        sourceAccount.type,
        CategoryType.income,
      );
    }

    if (virtualCategory != null) {
      return installment.copyWith(category: virtualCategory);
    }

    return installment;
  }

  Future<CategoryModel> _getVirtualCategoryForAccountType(
    AccountType type,
    CategoryType categoryType,
  ) async {
    if (type == AccountType.debt) {
      return categoryType == CategoryType.expense
          ? await categoryRepository.getCategory(
              workspaceId,
              CategoryModel.virtualDebtExpenseId,
            )
          : await categoryRepository.getCategory(
              workspaceId,
              CategoryModel.virtualDebtIncomeId,
            );
    }
    return categoryType == CategoryType.expense
        ? await categoryRepository.getCategory(
            workspaceId,
            CategoryModel.virtualInvestmentExpenseId,
          )
        : await categoryRepository.getCategory(
            workspaceId,
            CategoryModel.virtualInvestmentIncomeId,
          );
  }

  Future<void> cancelInstallment(
    String installmentId, {
    ReplicationCascade replicationCascade = ReplicationCascade.none,
  }) async {
    final installment = await repository.getInstallment(
      workspaceId,
      installmentId,
    );

    await repository.updateInstallment(
      workspaceId,
      installment.copyWith(
        status: InstallmentStatus.removed,
        replicationCascade: replicationCascade,
      ),
    );
  }

  Future<QueryChunk<InstallmentModel>> queryInstallments({
    required int limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    dynamic lastOrderId,
  }) async {
    return repository.queryInstallments(
      workspaceId,
      limit: limit,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
      description: description,
      minAmount: minAmount,
      maxAmount: maxAmount,
      status: status,
      chunkRef: lastOrderId,
    );
  }

  Future<void> addCategoryPlanning(CategoryPlanningModel planning) async {
    await repository.addCategoryPlanning(workspaceId, planning);
  }

  Future<void> updateCategoryPlanning(CategoryPlanningModel planning) async {
    await repository.updateCategoryPlanning(workspaceId, planning);
  }

  Future<List<CategoryPlanningModel>> getCategoryPlannings({
    String? startMonth,
    String? endMonth,
  }) async {
    return repository.getCategoryPlannings(
      workspaceId,
      startMonth: startMonth,
      endMonth: endMonth,
    );
  }

  Future<dynamic> getInstallment(String installmentId) async {
    return await repository.getInstallment(workspaceId, installmentId);
  }

  Stream<List<InstallmentModel>> watchInstallments({
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  }) {
    return repository.watchInstallments(
      workspaceId,
      limit: limit,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
      status: status,
    );
  }

  Stream<InstallmentModel?> watchNextInvoice(String accountId) {
    return repository.watchNextInvoice(workspaceId, accountId);
  }

  Stream<double> watchWeeklyXp(int year, int week) {
    return repository.watchWeeklyXp(workspaceId, year, week);
  }
}
