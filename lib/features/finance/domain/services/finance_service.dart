import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';

class FinanceService {
  final String workspaceId;
  final IFinanceRepository repository;

  FinanceService({required this.workspaceId, required this.repository});

  Future<void> addOrder(OrderModel order) async {
    await repository.addOrder(workspaceId, order);
  }

  Future<void> updateOrder(OrderModel order) async {
    await repository.updateOrder(workspaceId, order);
  }

  Future<void> updateInstallment(InstallmentModel installment) async {
    await repository.updateInstallment(workspaceId, installment);
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
    return repository.watchNextInvoice(
      workspaceId,
      accountId,
    );
  }

  Stream<double> watchWeeklyXp(int year, int week) {
    return repository.watchWeeklyXp(workspaceId, year, week);
  }
}
