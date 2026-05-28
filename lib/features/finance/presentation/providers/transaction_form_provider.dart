import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';
import 'package:funances/features/finance/presentation/providers/transaction_providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

enum TransactionFormType { simple, installment, recurrent }

class TransactionFormState {
  final TransactionType currentType;
  final TransactionFormType formType;
  final String description;
  final double amount;
  final int installments;
  final DateTime selectedDate;
  final CategoryModel? selectedCategory;
  final String? selectedAccountId;
  final String? toAccountId;
  final String? existingOrderId;
  final String? planningId;
  final bool isTransfer;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  TransactionFormState({
    required this.currentType,
    required this.formType,
    required this.description,
    required this.amount,
    required this.installments,
    required this.selectedDate,
    this.selectedCategory,
    this.selectedAccountId,
    this.toAccountId,
    this.existingOrderId,
    this.planningId,
    required this.isTransfer,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  factory TransactionFormState.initial({
    required TransactionType initialType,
    OrderModel? initialOrder,
    CategoryModel? initialCategory,
    String? initialAccountId,
    String? initialToAccountId,
    bool isTransfer = false,
    double? initialAmount,
  }) {
    DateTime selectedDate = DateTime.now();
    if (initialType == TransactionType.plannedExpense ||
        initialType == TransactionType.plannedIncome) {
      if (selectedDate.isBefore(DateTime.now())) {
        selectedDate = DateTime.now();
      }
    }

    final formType = (initialOrder?.installmentsCount ?? 1) > 1 
          ? TransactionFormType.installment 
          : TransactionFormType.simple;

    return TransactionFormState(
      currentType: initialType,
      formType: formType,
      description: initialOrder?.description ?? '',
      amount: initialAmount ?? initialOrder?.totalAmount ?? 0.0,
      installments: initialOrder?.installmentsCount ?? 1,
      selectedDate: initialOrder?.date ?? selectedDate,
      selectedCategory: initialCategory ?? initialOrder?.category,
      selectedAccountId: initialAccountId ?? (initialOrder?.metadata?['fromAccountId'] ?? initialOrder?.metadata?['accountId']),
      toAccountId: initialToAccountId ?? initialOrder?.metadata?['toAccountId'],
      existingOrderId: initialOrder?.id,
      planningId: initialOrder?.planningId,
      isTransfer: isTransfer || (initialOrder?.type == OrderType.transfer),
    );
  }

  TransactionFormState copyWith({
    TransactionType? currentType,
    TransactionFormType? formType,
    String? description,
    double? amount,
    int? installments,
    DateTime? selectedDate,
    CategoryModel? selectedCategory,
    String? selectedAccountId,
    String? toAccountId,
    String? existingOrderId,
    String? planningId,
    bool? isTransfer,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return TransactionFormState(
      currentType: currentType ?? this.currentType,
      formType: formType ?? this.formType,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      installments: installments ?? this.installments,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      existingOrderId: existingOrderId ?? this.existingOrderId,
      planningId: planningId ?? this.planningId,
      isTransfer: isTransfer ?? this.isTransfer,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class TransactionFormNotifier extends StateNotifier<TransactionFormState> {
  final Ref ref;
  
  TransactionFormNotifier({
    required this.ref,
    required TransactionType initialType,
    OrderModel? initialOrder,
    CategoryModel? initialCategory,
    String? initialAccountId,
    String? initialToAccountId,
    bool isTransfer = false,
    double? initialAmount,
  }) : super(TransactionFormState.initial(
          initialType: initialType,
          initialOrder: initialOrder,
          initialCategory: initialCategory,
          initialAccountId: initialAccountId,
          initialToAccountId: initialToAccountId,
          isTransfer: isTransfer,
          initialAmount: initialAmount,
        ));

  void updateDescription(String value) => state = state.copyWith(description: value);
  void updateAmount(double value) => state = state.copyWith(amount: value);
  void updateInstallments(int value) => state = state.copyWith(installments: value);
  void updateDate(DateTime value) => state = state.copyWith(selectedDate: value);
  void updateCategory(CategoryModel? value) => state = state.copyWith(selectedCategory: value);
  void updateAccountId(String? value) => state = state.copyWith(selectedAccountId: value);
  void updateToAccountId(String? value) => state = state.copyWith(toAccountId: value);
  void updateFormType(TransactionFormType value) => state = state.copyWith(formType: value);
  void updateCurrentType(TransactionType value) => state = state.copyWith(currentType: value);
  void updateIsTransfer(bool value) => state = state.copyWith(isTransfer: value);

  Future<void> submit() async {
    if (state.selectedCategory == null && !state.isTransfer) {
      state = state.copyWith(errorMessage: 'Category is required');
      return;
    }
    if (state.selectedAccountId == null) {
      state = state.copyWith(errorMessage: 'Account is required');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final status = (state.currentType == TransactionType.plannedExpense ||
            state.currentType == TransactionType.plannedIncome)
        ? OrderStatus.active
        : OrderStatus.paid;

    OrderType type = OrderType.expense;
    if (state.isTransfer) {
      type = OrderType.transfer;
    } else if (state.currentType == TransactionType.income ||
        state.currentType == TransactionType.plannedIncome) {
      type = OrderType.income;
    }

    final metadata = <String, dynamic>{'accountId': state.selectedAccountId};
    if (state.isTransfer) {
      metadata['fromAccountId'] = state.selectedAccountId;
      metadata['toAccountId'] = state.toAccountId;
    }

    int installments = 1;
    if (state.formType == TransactionFormType.installment) {
      installments = state.installments;
    }

    PlanningType? planningType;
    final isPlannedFlow = state.currentType == TransactionType.plannedExpense ||
        state.currentType == TransactionType.plannedIncome;
    
    if (isPlannedFlow) {
      if (state.formType == TransactionFormType.installment) {
        planningType = PlanningType.parcelado;
      } else if (state.formType == TransactionFormType.recurrent) {
        planningType = PlanningType.recurrent;
      } else {
        planningType = PlanningType.unique;
      }
    }

    DateTime endDate = state.selectedDate;
    if (planningType == PlanningType.recurrent) {
      endDate = state.selectedDate.add(const Duration(days: 365 * 100));
    } else if (planningType == PlanningType.parcelado) {
      endDate = DateTime(
        state.selectedDate.year,
        state.selectedDate.month + (installments - 1),
        state.selectedDate.day,
      );
    }

    final result = await ref.read(transactionNotifierProvider.notifier).saveTransaction(
          description: state.description,
          amount: state.amount,
          category: state.selectedCategory,
          date: state.selectedDate,
          type: type,
          status: status,
          installments: installments,
          metadata: metadata,
          existingOrderId: state.existingOrderId,
          isPlannedFlow: isPlannedFlow,
          planningType: planningType,
          planningInstallments: installments,
          startDate: state.selectedDate,
          endDate: endDate,
          planningId: state.planningId,
        );

    if (result is AsyncError) {
      state = state.copyWith(isLoading: false, errorMessage: result.error.toString());
    } else {
      state = state.copyWith(isLoading: false, isSuccess: true);
    }
  }
}

final transactionFormProvider = StateNotifierProvider.family<TransactionFormNotifier, TransactionFormState, TransactionFormArgs>((ref, args) {
  return TransactionFormNotifier(
    ref: ref,
    initialType: args.initialType,
    initialOrder: args.initialOrder,
    initialCategory: args.initialCategory,
    initialAccountId: args.initialAccountId,
    initialToAccountId: args.initialToAccountId,
    isTransfer: args.isTransfer,
    initialAmount: args.initialAmount,
  );
});

class TransactionFormArgs {
  final TransactionType initialType;
  final OrderModel? initialOrder;
  final CategoryModel? initialCategory;
  final String? initialAccountId;
  final String? initialToAccountId;
  final bool isTransfer;
  final double? initialAmount;

  TransactionFormArgs({
    required this.initialType,
    this.initialOrder,
    this.initialCategory,
    this.initialAccountId,
    this.initialToAccountId,
    this.isTransfer = false,
    this.initialAmount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFormArgs &&
          runtimeType == other.runtimeType &&
          initialType == other.initialType &&
          initialOrder?.id == other.initialOrder?.id &&
          initialCategory?.id == other.initialCategory?.id &&
          initialAccountId == other.initialAccountId &&
          initialToAccountId == other.initialToAccountId &&
          isTransfer == other.isTransfer &&
          initialAmount == other.initialAmount;

  @override
  int get hashCode =>
      initialType.hashCode ^
      (initialOrder?.id.hashCode ?? 0) ^
      (initialCategory?.id.hashCode ?? 0) ^
      initialAccountId.hashCode ^
      initialToAccountId.hashCode ^
      isTransfer.hashCode ^
      initialAmount.hashCode;
}
