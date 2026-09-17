
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/core/model/core_models.dart';

import '../../domain/models/category_planning_model.dart';
import '../../domain/models/installment_model.dart';
import '../../domain/models/order_model.dart';
import '../../domain/repositories/finance_repository.dart';
import '../models/installment_mapper.dart';
import '../models/order_mapper.dart';
import 'package:funances/core/observability/app_logger.dart';


/// Troca o ISO que o converter produziu por um `Timestamp`, SEM tocar na hora.
///
/// A regra do meio-dia mora num lugar só: `DateTimeTwelvePmConverter`. Este
/// arquivo a repetia campo a campo, recalculando `DateTime(ano, mês, dia, 12)`
/// em cima de um valor que já vinha normalizado — duas cópias da mesma regra,
/// das quais só uma seria lembrada no dia em que a regra mudasse.
///
/// Campo ausente ou nulo passa intacto: num `update`, `paidDate: null` é a
/// forma de limpar a data de pagamento.
void _isoToTimestamp(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is String) {
    data[field] = Timestamp.fromDate(DateTime.parse(value));
  }
}

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
    bool descending = true,
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
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          );
        }

        if (endDate != null) {
          query = query.where(
            "referenceDate",
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
        }
      }

      query = query.orderBy("referenceDate", descending: descending);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (chunkRef != null && chunkRef is DocumentSnapshot) {
        query = query.startAfterDocument(chunkRef);
      }

      final snapshot = await query.get();

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

      AppLogger.debug(
        'Firestore devolveu ${snapshot.docs.length} documentos; '
        '${items.length} após o filtro (descendente: $descending)',
        name: 'finance',
      );

      return QueryChunk(items: items, nextChunckRef: snapshot.docs.lastOrNull);
    } catch (e, s) {
      AppLogger.error('Falha ao consultar parcelas', e, s);

      throw BusinessException.from(e, s);
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
      throw BusinessException.from(e, s);
    }
  }

  @override
  Future<Written<OrderModel>> addOrder(
    String workspaceId,
    OrderModel order, {
    String? documentId,
  }) async {
    try {
      final data = order.toJson();
      data.remove('id');
      // `doc()` sem argumento gera o id localmente, sem ida ao servidor; o
      // `add()` que havia aqui só devolvia a referência depois que o servidor
      // respondia, e offline isso nunca acontecia.
      //
      // Com `documentId`, o id vem de quem chamou — é a conciliação, que o
      // deriva da linha do extrato para ser idempotente no retry.
      final orders = _getWorkspaceDoc(workspaceId).collection('orders');
      final doc = documentId == null ? orders.doc() : orders.doc(documentId);
      final WriteOutcome outcome = await settleWrite(
        doc.set(data),
        entity: WriteEntity.transaction,
      );

      return (value: order.copyWith(id: doc.id), outcome: outcome);
    } catch (e, s) {
      throw BusinessException.from(e, s);
    }
  }

  @override
  Future<WriteOutcome> updateOrder(String workspaceId, OrderModel order) async {
    try {
      final data = order.toJson();
      data.remove('id');
      return await settleWrite(
        _getWorkspaceDoc(
          workspaceId,
        ).collection('orders').doc(order.id).update(data),
        entity: WriteEntity.transaction,
      );
    } catch (e, s) {
      throw BusinessException.from(e, s);
    }
  }

  @override
  Future<void> deleteOrder(String workspaceId, String orderId) async {
    try {
      await settleWrite(
        _getWorkspaceDoc(
          workspaceId,
        ).collection('orders').doc(orderId).delete(),
        entity: WriteEntity.transaction,
      );
    } catch (e, s) {
      throw BusinessException.from(e, s);
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
      throw BusinessException.from(e, s);
    }
  }

  @override
  Future<WriteOutcome> updateInstallment(
    String workspaceId,
    InstallmentModel entry,
  ) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      // xp é concedido e mantido pelo servidor; enviar 'xp: null' num doc que
      // não tem o campo conta como alteração e é negado pelas rules.
      data.remove('xp');

      // As três datas já saíram do `toJson` normalizadas para o meio-dia —
      // quem faz isso é o converter freezed. Aqui só falta o TIPO: o Firestore
      // guarda `Timestamp` e a consulta por `referenceDate` depende disso.
      _isoToTimestamp(data, 'dueDate');
      _isoToTimestamp(data, 'paidDate');
      _isoToTimestamp(data, 'referenceDate');

      return await settleWrite(
        _getWorkspaceDoc(
          workspaceId,
        ).collection('installments').doc(entry.id).update(data),
        entity: WriteEntity.installment,
      );
    } catch (e, s) {
      throw BusinessException.from(e, s);
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
      await settleWrite(
        _getWorkspaceDoc(
          workspaceId,
        ).collection('category_planning').doc().set(data),
        entity: WriteEntity.planning,
      );
    } catch (e, s) {
      throw BusinessException.from(e, s);
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
      await settleWrite(
        _getWorkspaceDoc(
          workspaceId,
        ).collection('category_planning').doc(planning.id).update(data),
        entity: WriteEntity.planning,
      );
    } catch (e, s) {
      throw BusinessException.from(e, s);
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
      AppLogger.error('Falha ao carregar os planejamentos', e, s);

      throw BusinessException.from(e, s);
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
    final Query query = _getWorkspaceDoc(workspaceId)
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
  Stream<InstallmentModel?> watchInstallment(
    String workspaceId,
    String installmentId,
  ) {
    return _getWorkspaceDoc(workspaceId)
        .collection('installments')
        .doc(installmentId)
        .snapshots()
        .map((doc) => doc.exists ? doc.toInstallmentModel() : null);
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
