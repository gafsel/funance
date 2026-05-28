import '../models/order_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/planning_model.dart';
import '../models/category_month_summary_model.dart';

abstract class IFinanceRepository {
  // Orders
  Future<List<OrderModel>> getOrders(
    String workspaceId, {
    OrderStatus? status,
    OrderType? type,
    int? limit,
    OrderModel? lastOrder,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<OrderModel?> getOrder(String workspaceId, String orderId);
  Future<void> addOrder(String workspaceId, OrderModel order);
  Future<void> updateOrder(String workspaceId, OrderModel order);
  Future<void> deleteOrder(String workspaceId, String orderId);

  // Ledger Entries
  Future<List<LedgerEntryModel>> getLedgerEntries(String workspaceId, {String? orderId});
  Future<void> addLedgerEntry(String workspaceId, LedgerEntryModel entry);
  Future<void> updateLedgerEntry(String workspaceId, LedgerEntryModel entry);
  Future<void> deleteLedgerEntry(String workspaceId, String entryId);

  // Plannings
  Future<void> addPlanning(String workspaceId, PlanningModel planning);

  // Summaries
  Future<List<CategoryMonthSummaryModel>> getCategorySummaries(String workspaceId, int year, int month);
  Stream<List<CategoryMonthSummaryModel>> watchCategorySummaries(String workspaceId, int year, int month);
}
