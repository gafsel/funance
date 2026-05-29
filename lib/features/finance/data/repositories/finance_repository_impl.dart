import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/model/core_models.dart';

import '../../domain/models/category_planning_model.dart';
import '../../domain/models/installment_model.dart';
import '../../domain/models/order_model.dart';
import '../../domain/repositories/finance_repository.dart';
import '../models/installment_mapper.dart';
import '../models/order_mapper.dart';

class FinanceRepositoryImpl implements IFinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _getWorkspaceDoc(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId);
  }

  @override
  Future<QueryChunk<InstallmentModel>> queryInstallments(
    String workspaceId, {
    int? limit,
    dynamic chunkRef,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _getWorkspaceDoc(workspaceId)
          .collection('installments')
          .where("status", isNotEqualTo: InstallmentStatus.removed);

      if (accountId != null && accountId.isNotEmpty) {
        query = query.where('accounts.$accountId', isNull: false);
      }

      if (startDate != null) {
        query = query.where("referenceDate", isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where("referenceDate", isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy("referenceDate", descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (chunkRef != null) {
        query = query.startAfterDocument(chunkRef);
      }

      final snapshot = await query.get();
      return QueryChunk(
        items: snapshot.docs.map((doc) => doc.toInstallmentModel()).toList(),
        nextChunckRef: snapshot.docs.lastOrNull,
      );
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<OrderModel?> getOrder(String workspaceId, String orderId) async {
    try {
      final doc = await _getWorkspaceDoc(
        workspaceId,
      ).collection('orders').doc(orderId).get();
      if (!doc.exists) return null;
      return doc.toOrderModel();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> addOrder(String workspaceId, OrderModel order) async {
    try {
      final data = order.toJson();
      data.remove('id');
      await _getWorkspaceDoc(workspaceId).collection('orders').add(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateOrder(String workspaceId, OrderModel order) async {
    try {
      final data = order.toJson();
      data.remove('id');
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('orders').doc(order.id).update(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deleteOrder(String workspaceId, String orderId) async {
    try {
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('orders').doc(orderId).delete();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<List<InstallmentModel>> getInstallments(
    String workspaceId, {
    String? orderId,
  }) async {
    try {
      Query query = _getWorkspaceDoc(workspaceId).collection('installments');
      if (orderId != null) {
        query = query.where('orderId', isEqualTo: orderId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.toInstallmentModel()).toList();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> addInstallment(
    String workspaceId,
    InstallmentModel entry,
  ) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      data['dueDate'] = Timestamp.fromDate(entry.dueDate);
      if (entry.paidDate != null) {
        data['paidDate'] = Timestamp.fromDate(entry.paidDate!);
      }
      await _getWorkspaceDoc(workspaceId).collection('installments').add(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateInstallment(
    String workspaceId,
    InstallmentModel entry,
  ) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      data['dueDate'] = Timestamp.fromDate(entry.dueDate);
      if (entry.paidDate != null) {
        data['paidDate'] = Timestamp.fromDate(entry.paidDate!);
      }
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('installments').doc(entry.id).update(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deleteInstallment(String workspaceId, String entryId) async {
    try {
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('installments').doc(entryId).delete();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<InstallmentModel> getInstallment(
    String workspaceId,
    String installmentId,
  ) async {
    final doc = await _getWorkspaceDoc(
      workspaceId,
    ).collection('installments').doc(installmentId).get();
    return doc.toInstallmentModel();
  }

  @override
  Future<void> addCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    try {
      final data = planning.toJson();
      data.remove('id');
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('category_planning').add(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
