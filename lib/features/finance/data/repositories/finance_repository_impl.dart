import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/ledger_entry_model.dart';
import '../../domain/models/planning_model.dart';
import '../../domain/models/category_month_summary_model.dart';
import '../../domain/repositories/finance_repository.dart';
import 'package:funances/core/exceptions/business_exception.dart';

class FinanceRepositoryImpl implements IFinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _getWorkspaceDoc(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId);
  }

  @override
  Future<List<OrderModel>> getOrders(
    String workspaceId, {
    OrderStatus? status,
    OrderType? type,
    int? limit,
    OrderModel? lastOrder,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _getWorkspaceDoc(workspaceId).collection('orders');

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (accountId != null && accountId.isNotEmpty) {
        query = query.where('metadata.accountId', isEqualTo: accountId);
      }

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
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
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<OrderModel?> getOrder(String workspaceId, String orderId) async {
    try {
      final doc = await _getWorkspaceDoc(workspaceId).collection('orders').doc(orderId).get();
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> addOrder(String workspaceId, OrderModel order) async {
    try {
      final data = order.toJson();
      data.remove('id');
      data['date'] = Timestamp.fromDate(order.date);
      await _getWorkspaceDoc(workspaceId).collection('orders').add(data);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> updateOrder(String workspaceId, OrderModel order) async {
    try {
      final data = order.toJson();
      data.remove('id');
      data['date'] = Timestamp.fromDate(order.date);
      await _getWorkspaceDoc(workspaceId).collection('orders').doc(order.id).update(data);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> deleteOrder(String workspaceId, String orderId) async {
    try {
      await _getWorkspaceDoc(workspaceId).collection('orders').doc(orderId).delete();
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  // Ledger Entries
  @override
  Future<List<LedgerEntryModel>> getLedgerEntries(String workspaceId, {String? orderId}) async {
    try {
      Query query = _getWorkspaceDoc(workspaceId).collection('ledger_entries');
      
      if (orderId != null) {
        query = query.where('order_id', isEqualTo: orderId);
      }
      
      final snapshot = await query.orderBy('due_date', descending: true).get();
      return snapshot.docs.map((doc) => LedgerEntryModel.fromFirestore(doc)).toList();
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> addLedgerEntry(String workspaceId, LedgerEntryModel entry) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      data['due_date'] = Timestamp.fromDate(entry.dueDate);
      await _getWorkspaceDoc(workspaceId).collection('ledger_entries').add(data);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> updateLedgerEntry(String workspaceId, LedgerEntryModel entry) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      data['due_date'] = Timestamp.fromDate(entry.dueDate);
      await _getWorkspaceDoc(workspaceId).collection('ledger_entries').doc(entry.id).update(data);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> deleteLedgerEntry(String workspaceId, String entryId) async {
    try {
      await _getWorkspaceDoc(workspaceId).collection('ledger_entries').doc(entryId).delete();
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  // Plannings
  @override
  Future<void> addPlanning(String workspaceId, PlanningModel planning) async {
    try {
      final data = planning.toJson();
      data.remove('id');
      data['start_date'] = Timestamp.fromDate(planning.startDate);
      data['end_date'] = Timestamp.fromDate(planning.endDate);
      await _getWorkspaceDoc(workspaceId).collection('plannings').add(data);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  // Summaries
  @override
  Future<List<CategoryMonthSummaryModel>> getCategorySummaries(String workspaceId, int year, int month) async {
    try {
      final snapshot = await _getWorkspaceDoc(workspaceId)
          .collection('category_month_summaries')
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();
      
      return snapshot.docs.map((doc) => CategoryMonthSummaryModel.fromFirestore(doc)).toList();
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
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
