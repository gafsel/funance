import 'package:funances/core/model/core_models.dart';
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
    String? lastOrderId,
  }) async {
    return repository.queryInstallments(
      workspaceId,
      limit: limit,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      chunkRef: lastOrderId,
    );
  }
}
