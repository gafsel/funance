import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:uuid/uuid.dart';

part 'finance_view_models.freezed.dart';

@freezed
sealed class CategoryPlanningArgs with _$CategoryPlanningArgs {
  factory CategoryPlanningArgs({required CategoryType type}) =
      _CategoryPlanningArgs;
}

@freezed
sealed class CategoryPlanningFormItem with _$CategoryPlanningFormItem {
  factory CategoryPlanningFormItem({
    required CategoryModel category,
    @Default(0.0) double amount,
    String? planningId,
    @Default(false) bool isDirty,
  }) = _CategoryPlanningFormItem;
}

@freezed
sealed class CategoryPlanningState with _$CategoryPlanningState {
  factory CategoryPlanningState({
    @Default([]) List<CategoryPlanningFormItem> items,
    @Default(true) bool isLoading,
  }) = _CategoryPlanningState;
}

@freezed
sealed class CategoryPlanning503020Item with _$CategoryPlanning503020Item {
  const CategoryPlanning503020Item._();

  factory CategoryPlanning503020Item({
    required CategoryModel category,
    @Default(0.0) double generalAmount,
    @Default(0.0) double specificAmount,
    @Default(0.0) double actualAmount,
    String? planningId,
    @Default(false) bool isDirty,
  }) = _CategoryPlanning503020Item;

  double get effectiveAmount => generalAmount > 0 ? generalAmount : specificAmount;
}

@freezed
sealed class CategoryPlanning503020State with _$CategoryPlanning503020State {
  factory CategoryPlanning503020State({
    required DateTime date,
    @Default([]) List<CategoryPlanning503020Item> items,
    @Default(0.0) double totalIncomes,
    @Default(0.0) double totalActualIncomes,
    @Default(true) bool isLoading,
    @Default(false) bool isSubmitting,
  }) = _CategoryPlanning503020State;
}

@freezed
sealed class Planning503020DistributionGroup with _$Planning503020DistributionGroup {
  const factory Planning503020DistributionGroup({
    @Default(0.0) double plannedAmount,
    @Default(0.0) double actualAmount,
    @Default(0.0) double idealPercentage,
  }) = _Planning503020DistributionGroup;
}

@freezed
sealed class Planning503020Distribution with _$Planning503020Distribution {
  const factory Planning503020Distribution({
    required Planning503020DistributionGroup essential,
    required Planning503020DistributionGroup comfort,
    required Planning503020DistributionGroup investment,
    @Default(0.0) double totalIncome,
    @Default(0.0) double totalActualIncome,
  }) = _Planning503020Distribution;
}

enum TransactionWizardStep { category, transactions, form }

@freezed
sealed class TransactionWizardArgs with _$TransactionWizardArgs {
  factory TransactionWizardArgs({
    required OrderType type,
    @Default(false) bool skipTransactions,
    String? accountIdSource,
  }) = _TransactionWizardArgs;
}

@freezed
sealed class TransactionWizardState with _$TransactionWizardState {
  const factory TransactionWizardState({
    required OrderType type,
    CategoryModel? selectedCategory,
    InstallmentModel? selectedInstallment,
    @Default(TransactionWizardStep.category) TransactionWizardStep step,
    @Default(false) bool skipTransactions,
    String? accountIdSource,
  }) = _TransactionWizardState;
}

@freezed
sealed class TransactionCreationArgs with _$TransactionCreationArgs {
  factory TransactionCreationArgs({
    required OrderType type,
    InstallmentStatus? status,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    String? description,
    DateTime? date,
    double? amount,
  }) = _TransactionCreationArgs;
}

enum TransactionFormType { order, installment }

enum TransactionAmountType { total, installment }

@freezed
sealed class TransactionFormState with _$TransactionFormState {
  const TransactionFormState._();

  const factory TransactionFormState({
    String? installmentId,
    String? orderId,
    required TransactionFormType formType,
    required OrderType type,
    required InstallmentType installmentType,
    @Default(TransactionAmountType.total) TransactionAmountType amountType,
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
    @Default(false) bool isInvoice,
  }) = _TransactionFormState;

  bool get creation => formType == TransactionFormType.order && orderId == null;
  bool get isPlanning => amount > 0.0;

  factory TransactionFormState.creation({
    required OrderType type,
    InstallmentStatus? status,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    String? description,
    DateTime? date,
    double? amount,
  }) {
    return TransactionFormState(
      formType: TransactionFormType.order,
      type: type,
      category: category,
      dueDate: date ?? DateTime.now(),
      paidDate:
          status == InstallmentStatus.paid ||
              status == InstallmentStatus.settled
          ? date ?? DateTime.now()
          : null,
      status: status ?? InstallmentStatus.pending,
      installmentType: InstallmentType.single,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
      description: description ?? "",
      amount: amount ?? 0.0,
      paidAmount:
          status == InstallmentStatus.paid ||
              status == InstallmentStatus.settled
          ? amount ?? 0.0
          : null,
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
      isInvoice: order.isInvoice,
    );
  }

  factory TransactionFormState.updateInstallment(
    InstallmentModel installment, {
    InstallmentStatus? status,
  }) {
    final effectiveStatus = status ?? installment.status;

    DateTime? paidDate = installment.paidDate;
    double? paidAmount = installment.paidAmount;

    if (status == InstallmentStatus.paid ||
        status == InstallmentStatus.settled) {
      paidAmount = installment.amount;
      paidDate = installment.dueDate.isAfter(DateTime.now())
          ? DateTime.now()
          : installment.dueDate;
    } else if (status == InstallmentStatus.pending) {
      paidAmount = null;
      paidDate = null;
    }

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
      status: effectiveStatus,
      description: installment.description,
      paidAmount: paidAmount,
      paidDate: paidDate,
      replicateCascade: ReplicationCascade.none,
      isInvoice: installment.isInvoice,
    );
  }

  OrderModel asOrderModel() {
    double finalAmount = amount;
    if (installmentType == InstallmentType.installment &&
        amountType == TransactionAmountType.installment &&
        installmentCount != null) {
      finalAmount = amount * installmentCount!;
    }

    return OrderModel(
      id: orderId ?? Uuid().v4(),
      amount: finalAmount,
      description: description,
      dueDay: dueDate.day,
      startMonth: dueDate.formated("yyyy-MM"),
      installmentType: installmentType,
      installmentCount: installmentCount,
      status: OrderStatus.active,
      installmentCreationStatus: status,
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
      isInvoice: isInvoice,
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
      isInvoice: isInvoice,
    );
  }
}

@freezed
sealed class TransactionTotals with _$TransactionTotals {
  const factory TransactionTotals({
    @Default(0.0) double plannedIncomes,
    @Default(0.0) double realizedIncomes,
    @Default(0.0) double plannedExpenses,
    @Default(0.0) double realizedExpenses,
    @Default(0.0) double plannedTransfers,
    @Default(0.0) double realizedTransfers,
    @Default(0.0) double plannedInvoices,
    @Default(0.0) double realizedInvoices,
    @Default(0.0) double plannedVirtualDebtExpense,
    @Default(0.0) double realizedVirtualDebtExpense,
    @Default(0.0) double plannedVirtualDebtIncome,
    @Default(0.0) double realizedVirtualDebtIncome,
    @Default(0.0) double plannedVirtualInvestmentExpense,
    @Default(0.0) double realizedVirtualInvestmentExpense,
    @Default(0.0) double plannedVirtualInvestmentIncome,
    @Default(0.0) double realizedVirtualInvestmentIncome,
  }) = _TransactionTotals;

  const TransactionTotals._();

  double get plannedBalance => plannedIncomes - plannedExpenses;

  double get realizedBalance => realizedIncomes - realizedExpenses;
}

@freezed
sealed class TransactionQuery with _$TransactionQuery {
  factory TransactionQuery({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    @Default(true) bool descending,
  }) = _TransactionQuery;
}
