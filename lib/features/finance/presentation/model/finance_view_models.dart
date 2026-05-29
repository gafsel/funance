import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:uuid/uuid.dart';

part 'finance_view_models.freezed.dart';

@freezed
sealed class TransactionCreationArgs with _$TransactionCreationArgs {
  factory TransactionCreationArgs({
    required OrderType type,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
  }) = _TransactionCreationArgs;
}

enum TransactionFormType { order, installment }

@freezed
sealed class TransactionFormState with _$TransactionFormState {
  const TransactionFormState._();

  const factory TransactionFormState({
    String? installmentId,
    String? orderId,
    required TransactionFormType formType,
    required OrderType type,
    required InstallmentType installmentType,
    @Default("") String description,
    @Default(0.0) double amount,
    int? intallmentNumber,
    int? installmentCount,
    required DateTime dueDate,
    @Default(InstallmentStatus.pending) InstallmentStatus status,
    DateTime? paidDate,
    double? paidAmount,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    ReplicationCascade? replicateCascade,
  }) = _TransactionFormState;

  bool get creation => formType == TransactionFormType.order && orderId == null;

  factory TransactionFormState.creation({
    required OrderType type,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
  }) {
    return TransactionFormState(
      formType: TransactionFormType.order,
      type: type,
      category: category,
      dueDate: DateTime.now(),
      installmentType: InstallmentType.single,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
    );
  }

  factory TransactionFormState.updateOrder(OrderModel order) {
    return TransactionFormState(
      formType: TransactionFormType.order,
      orderId: order.id,
      type: order.type,
      category: order.category,
      dueDate: order.firstDueDate,
      installmentType: order.installmentType,
      installmentCount: order.installmentCount,
      accountIdTarget: order.accountIdTarget,
      accountIdSource: order.accountIdSource,
      amount: order.amount,
      description: order.description,
    );
  }

  factory TransactionFormState.updateInstallment(InstallmentModel installment) {
    return TransactionFormState(
      formType: TransactionFormType.installment,
      installmentId: installment.id,
      orderId: installment.orderId,
      type: installment.type,
      category: installment.category,
      dueDate: installment.dueDate,
      installmentType: installment.installmentType,
      installmentCount: installment.installmentCount,
      intallmentNumber: installment.installmentNumber,
      accountIdTarget: installment.accountIdTarget,
      accountIdSource: installment.accountIdSource,
      amount: installment.amount,
      status: installment.status,
      description: installment.description,
      paidAmount: installment.paidAmount,
      paidDate: installment.paidDate,
      replicateCascade: ReplicationCascade.none,
    );
  }

  OrderModel asOrderModel() {
    return OrderModel(
      id: orderId ?? Uuid().v4(),
      amount: amount,
      description: description,
      dueDay: dueDate.day,
      startMonth: dueDate.formated("YYYY-MM"),
      installmentType: installmentType,
      installmentCount: installmentCount,
      status: OrderStatus.active,
      type: type,
      accounts: {
        if (accountIdSource != null &&
            (type == OrderType.expense || type == OrderType.transfer))
          accountIdSource!: AccountImpact.debt,
        if (accountIdSource != null && type == OrderType.income)
          accountIdSource!: AccountImpact.credit,
        if (accountIdTarget != null && type == OrderType.transfer)
          accountIdTarget!: AccountImpact.credit,
      },
      category: category,
    );
  }

  InstallmentModel asInstallmentModel() {
    return InstallmentModel(
      id: installmentId!,
      orderId: orderId!,
      amount: amount,
      description: description,
      dueDate: dueDate,
      status: status,
      type: type,
      installmentType: installmentType,
      category: category,
      accounts: {
        if ((type == OrderType.expense || type == OrderType.transfer))
          accountIdSource!: AccountImpact.debt,
        if (type == OrderType.income) accountIdSource!: AccountImpact.credit,
        if (type == OrderType.transfer) accountIdTarget!: AccountImpact.credit,
      },
      paidDate: paidDate,
      paidAmount: paidAmount,
      installmentCount: installmentCount,
      installmentNumber: intallmentNumber,
      replicationCascade: replicateCascade,
    );
  }
}

@freezed
sealed class TransactionQuery with _$TransactionQuery {
  factory TransactionQuery({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) = _TransactionQuery;
}
