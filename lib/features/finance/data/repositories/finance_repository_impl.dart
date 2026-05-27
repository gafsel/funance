import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/ledger_entry_model.dart';
import '../../domain/models/category_month_summary_model.dart';
import '../../domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements IFinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _getWorkspaceDoc(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId);
  }

  // Orders
  @override
  Future<List<OrderModel>> getOrders(String workspaceId, {OrderStatus? status, OrderType? type, int? limit, OrderModel? lastOrder}) async {
    Query query = _getWorkspaceDoc(workspaceId).collection('orders');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    
    query = query.orderBy('date', descending: true);

    if (lastOrder != null) {
      query = query.startAfter([Timestamp.fromDate(lastOrder.date)]);
    }

    if (limit != null) {
      query = query.limit(limit);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }

  @override
  Future<OrderModel?> getOrder(String workspaceId, String orderId) async {
    final doc = await _getWorkspaceDoc(workspaceId).collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  @override
  Future<void> addOrder(String workspaceId, OrderModel order) async {
    final data = order.toJson();
    data.remove('id');
    data['date'] = Timestamp.fromDate(order.date);
    await _getWorkspaceDoc(workspaceId).collection('orders').add(data);
  }

  @override
  Future<void> updateOrder(String workspaceId, OrderModel order) async {
    final data = order.toJson();
    data.remove('id');
    data['date'] = Timestamp.fromDate(order.date);
    await _getWorkspaceDoc(workspaceId).collection('orders').doc(order.id).update(data);
  }

  @override
  Future<void> deleteOrder(String workspaceId, String orderId) async {
    await _getWorkspaceDoc(workspaceId).collection('orders').doc(orderId).delete();
  }

  // Ledger Entries
  @override
  Future<List<LedgerEntryModel>> getLedgerEntries(String workspaceId, {String? orderId}) async {
    Query query = _getWorkspaceDoc(workspaceId).collection('ledger_entries');
    
    if (orderId != null) {
      query = query.where('order_id', isEqualTo: orderId);
    }
    
    final snapshot = await query.orderBy('due_date', descending: true).get();
    return snapshot.docs.map((doc) => LedgerEntryModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> addLedgerEntry(String workspaceId, LedgerEntryModel entry) async {
    final data = entry.toJson();
    data.remove('id');
    data['due_date'] = Timestamp.fromDate(entry.dueDate);
    await _getWorkspaceDoc(workspaceId).collection('ledger_entries').add(data);
  }

  @override
  Future<void> updateLedgerEntry(String workspaceId, LedgerEntryModel entry) async {
    final data = entry.toJson();
    data.remove('id');
    data['due_date'] = Timestamp.fromDate(entry.dueDate);
    await _getWorkspaceDoc(workspaceId).collection('ledger_entries').doc(entry.id).update(data);
  }

  @override
  Future<void> deleteLedgerEntry(String workspaceId, String entryId) async {
    await _getWorkspaceDoc(workspaceId).collection('ledger_entries').doc(entryId).delete();
  }

  // Summaries
  @override
  Future<List<CategoryMonthSummaryModel>> getCategorySummaries(String workspaceId, int year, int month) async {
    final snapshot = await _getWorkspaceDoc(workspaceId)
        .collection('category_month_summaries')
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .get();
    
    return snapshot.docs.map((doc) => CategoryMonthSummaryModel.fromFirestore(doc)).toList();
  }

  @override
  Stream<List<CategoryMonthSummaryModel>> watchCategorySummaries(String workspaceId, int year, int month) {
    return _getWorkspaceDoc(workspaceId)
        .collection('category_month_summaries')
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryMonthSummaryModel.fromFirestore(doc))
            .toList());
  }
}
