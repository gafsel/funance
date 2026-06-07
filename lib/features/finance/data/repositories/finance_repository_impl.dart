import 'dart:developer';

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
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    dynamic chunkRef,
  }) async {
    try {
      Query query = _getWorkspaceDoc(workspaceId).collection('installments');

      if (accountId != null && accountId.isNotEmpty) {
        query = query.where('accountIds', arrayContains: accountId);
      }

      if (status != null) {
        query = query.where("status", isEqualTo: status.name);
      } else {
        query = query.where(
          "status",
          whereIn: [
            InstallmentStatus.pending.name,
            InstallmentStatus.paid.name,
            InstallmentStatus.settled.name,
          ],
        );
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('category.id', isEqualTo: categoryId);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (minAmount != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: minAmount);
      }

      if (maxAmount != null) {
        query = query.where('amount', isLessThanOrEqualTo: maxAmount);
      }

      if (startDate != null || endDate != null) {
        if (startDate != null) {
          query = query.where(
            "referenceDate",
            isGreaterThanOrEqualTo: startDate,
          );
        }

        if (endDate != null) {
          query = query.where("referenceDate", isLessThanOrEqualTo: endDate);
        }
      }
      query = query.orderBy("referenceDate", descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (chunkRef != null && chunkRef is DocumentSnapshot) {
        query = query.startAfterDocument(chunkRef);
      }

      var snapshot = await query.get();

      var items = snapshot.docs.map((doc) => doc.toInstallmentModel()).toList();

      if (description != null && description.isNotEmpty) {
        items = items
            .where(
              (item) => item.description.toLowerCase().contains(
                description.toLowerCase(),
              ),
            )
            .toList();
      }

      return QueryChunk(items: items, nextChunckRef: snapshot.docs.lastOrNull);
    } catch (e, s) {
      log(
        "Failed to query installments: ${e.toString()}",
        error: e,
        stackTrace: s,
      );

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
  Future<OrderModel> addOrder(String workspaceId, OrderModel order) async {
    try {
      final data = order.toJson();
      data.remove('id');
      final doc = await _getWorkspaceDoc(workspaceId).collection('orders').add(data);
      return order.copyWith(id: doc.id);
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

      final normalizedDueDate = DateTime(
        entry.dueDate.year,
        entry.dueDate.month,
        entry.dueDate.day,
        12,
      );
      data['dueDate'] = Timestamp.fromDate(normalizedDueDate);

      if (entry.paidDate != null) {
        final normalizedPaidDate = DateTime(
          entry.paidDate!.year,
          entry.paidDate!.month,
          entry.paidDate!.day,
          12,
        );
        data['paidDate'] = Timestamp.fromDate(normalizedPaidDate);
      }

      final normalizedReferenceDate = DateTime(
        entry.referenceDate.year,
        entry.referenceDate.month,
        entry.referenceDate.day,
        12,
      );
      data['referenceDate'] = Timestamp.fromDate(normalizedReferenceDate);

      data['referenceAmount'] = entry.referenceAmount;
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

      final normalizedDueDate = DateTime(
        entry.dueDate.year,
        entry.dueDate.month,
        entry.dueDate.day,
        12,
      );
      data['dueDate'] = Timestamp.fromDate(normalizedDueDate);

      if (entry.paidDate != null) {
        final normalizedPaidDate = DateTime(
          entry.paidDate!.year,
          entry.paidDate!.month,
          entry.paidDate!.day,
          12,
        );
        data['paidDate'] = Timestamp.fromDate(normalizedPaidDate);
      }

      final normalizedReferenceDate = DateTime(
        entry.referenceDate.year,
        entry.referenceDate.month,
        entry.referenceDate.day,
        12,
      );
      data['referenceDate'] = Timestamp.fromDate(normalizedReferenceDate);

      data['referenceAmount'] = entry.referenceAmount;
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

  @override
  Future<void> updateCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    try {
      final data = planning.toJson();
      data.remove('id');
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('category_planning').doc(planning.id).update(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<List<CategoryPlanningModel>> getCategoryPlannings(
    String workspaceId, {
    String? startMonth,
    String? endMonth,
  }) async {
    try {
      Query query = _getWorkspaceDoc(
        workspaceId,
      ).collection('category_planning');

      if (startMonth != null) {
        query = query.where('startMonth', isLessThanOrEqualTo: startMonth);
        query = query.where('endMonth', isGreaterThanOrEqualTo: startMonth);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CategoryPlanningModel.fromJson(data);
      }).toList();
    } catch (e, s) {
      log(
        "Failed to load category plannings ${e.toString()}",
        error: e,
        stackTrace: s,
      );

      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Stream<List<InstallmentModel>> watchInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  }) {
    Query query = _getWorkspaceDoc(workspaceId).collection('installments');

    if (accountId != null && accountId.isNotEmpty) {
      query = query.where('accountIds', arrayContains: accountId);
    }

    if (status != null) {
      query = query.where("status", isEqualTo: status.name);
    } else {
      query = query.where(
        "status",
        whereIn: [
          InstallmentStatus.pending.name,
          InstallmentStatus.paid.name,
          InstallmentStatus.settled.name,
        ],
      );
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('category.id', isEqualTo: categoryId);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (startDate != null || endDate != null) {
      if (startDate != null) {
        query = query.where("referenceDate", isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where("referenceDate", isLessThanOrEqualTo: endDate);
      }
    }
    query = query.orderBy("referenceDate", descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.toInstallmentModel()).toList();
    });
  }

  @override
  Stream<InstallmentModel?> watchNextInvoice(
    String workspaceId,
    String accountId,
  ) {
    Query query = _getWorkspaceDoc(workspaceId)
        .collection('installments')
        .where('isInvoice', isEqualTo: true)
        .where('accountIds', arrayContains: accountId)
        .where("status", isEqualTo: InstallmentStatus.pending.name)
        .orderBy("dueDate")
        .limit(1);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.toInstallmentModel()).firstOrNull;
    });
  }

  @override
  Stream<double> watchWeeklyXp(String workspaceId, int year, int week) {
    final weeklyXpId = "$year-W${week.toString().padLeft(2, "0")}";
    return _getWorkspaceDoc(
      workspaceId,
    ).collection('weekly_xp').doc(weeklyXpId).snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data() as Map<String, dynamic>;
      return (data['xp'] as num).toDouble();
    });
  }
}
