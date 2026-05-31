import 'package:funances/core/model/core_models.dart';

import '../models/category_planning_model.dart';
import '../models/installment_model.dart';
import '../models/order_model.dart';

abstract class IFinanceRepository {
  // Orders
  Future<QueryChunk<InstallmentModel>> queryInstallments(
    String workspaceId, {
    int? limit,
    dynamic chunkRef,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<OrderModel?> getOrder(String workspaceId, String orderId);

  Future<void> addOrder(String workspaceId, OrderModel order);

  Future<void> updateOrder(String workspaceId, OrderModel order);

  Future<void> deleteOrder(String workspaceId, String orderId);

  // Installments
  Future<List<InstallmentModel>> getInstallments(
    String workspaceId, {
    String? orderId,
  });

  Future<void> addInstallment(String workspaceId, InstallmentModel entry);

  Future<void> updateInstallment(String workspaceId, InstallmentModel entry);

  Future<void> deleteInstallment(String workspaceId, String entryId);

  Future<InstallmentModel> getInstallment(
    String workspaceId,
    String installmentId,
  );

  // Category Planning
  Future<void> addCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  );

  Future<void> updateCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  );

  Future<List<CategoryPlanningModel>> getCategoryPlannings(
    String workspaceId, {
    String? startMonth,
    String? endMonth,
  });
}
