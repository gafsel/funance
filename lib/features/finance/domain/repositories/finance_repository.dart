import 'package:funances/core/model/core_models.dart';

import '../models/category_planning_model.dart';
import '../models/installment_model.dart';
import '../models/order_model.dart';

abstract class IFinanceRepository {
  // Orders
  Future<QueryChunk<InstallmentModel>> queryInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    bool descending = true,
    dynamic chunkRef,
  });

  Future<OrderModel?> getOrder(String workspaceId, String orderId);

  Future<OrderModel> addOrder(String workspaceId, OrderModel order);

  Future<void> updateOrder(String workspaceId, OrderModel order);

  Future<void> deleteOrder(String workspaceId, String orderId);

  // Installments
  Future<List<InstallmentModel>> getInstallments(
    String workspaceId, {
    String? orderId,
  });

  Future<void> updateInstallment(String workspaceId, InstallmentModel entry);

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

  Stream<List<InstallmentModel>> watchInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  });

  Stream<InstallmentModel?> watchNextInvoice(
    String workspaceId,
    String accountId,
  );

  Stream<double> watchWeeklyXp(String workspaceId, int year, int week);
}
