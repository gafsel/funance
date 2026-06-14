import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

class TransactionFormNotifier
    extends FormNotifier<TransactionFormState, dynamic> {
  final FinanceService financeService;
  final CategoryService categoryService;

  TransactionFormNotifier(
    super.initialState, {
    required this.financeService,
    required this.categoryService,
  }) : super();

  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  void updateAmount(double value) => state = state.copyWith(amount: value);

  void updateAmountType(TransactionAmountType value) =>
      state = state.copyWith(amountType: value);

  void updateInstallmentCount(int value) =>
      state = state.copyWith(installmentCount: value);

  void updateDueDate(DateTime value) => state = state.copyWith(dueDate: value);

  void updateCategory(CategoryModel? value) =>
      state = state.copyWith(category: value);

  void updateAccountIdTarget(String? value) {
    state = state.copyWith(
      accountIdTarget: value,
      accountIdSource: value == state.accountIdSource
          ? null
          : state.accountIdSource,
    );
    _checkVirtualCategory();
  }

  void updateAccountIdSource(String? value) {
    state = state.copyWith(
      accountIdSource: value,
      accountIdTarget: value == state.accountIdTarget
          ? null
          : state.accountIdTarget,
    );
    _checkVirtualCategory();
  }

  void _checkVirtualCategory() async {
    if (state.type != OrderType.transfer) return;

    final sourceId = state.accountIdSource;
    final targetId = state.accountIdTarget;

    if (sourceId == null && targetId == null) return;

    CategoryModel? virtualCategory;

    if (targetId != null) {
      try {
        final targetAccount = await financeService.getAccount(targetId);
        if (targetAccount.type == AccountType.debt ||
            targetAccount.type == AccountType.investment) {
          virtualCategory = targetAccount.type == AccountType.debt
              ? await categoryService.getCategory(
                  CategoryModel.virtualDebtExpenseId,
                )
              : await categoryService.getCategory(
                  CategoryModel.virtualInvestmentExpenseId,
                );
        }
      } catch (_) {}
    }

    if (virtualCategory == null && sourceId != null) {
      try {
        final sourceAccount = await financeService.getAccount(sourceId);
        if (sourceAccount.type == AccountType.debt ||
            sourceAccount.type == AccountType.investment) {
          virtualCategory = sourceAccount.type == AccountType.debt
              ? await categoryService.getCategory(
                  CategoryModel.virtualDebtIncomeId,
                )
              : await categoryService.getCategory(
                  CategoryModel.virtualInvestmentIncomeId,
                );
        }
      } catch (_) {}
    }

    if (virtualCategory != null) {
      state = state.copyWith(category: virtualCategory);
    }
  }

  void updateInstallmentType(InstallmentType value) {
    if (state.creation) {
      state = state.copyWith(installmentType: value);
    }
  }

  void updateOrderType(OrderType type) {
    if (state.creation) {
      state = state.copyWith(
        type: type,
        category: type == OrderType.transfer ? null : state.category,
      );
    }
  }

  void updatePaidDate(DateTime? value) {
    state = state.copyWith(
      dueDate: state.creation || state.amount > 0
          ? state.dueDate
          : value ?? state.dueDate,
      paidDate: value,
    );
  }

  void updatePaidAmount(double? value) =>
      state = state.copyWith(paidAmount: value);

  void updateReplicationCascade(ReplicationCascade? value) =>
      state = state.copyWith(replicateCascade: value);

  void updateStatus(InstallmentStatus value) {
    if (value == InstallmentStatus.paid || value == InstallmentStatus.settled) {
      state = state.copyWith(
        status: value,
        paidAmount: state.amount,
        paidDate: state.dueDate.isAfter(DateTime.now())
            ? DateTime.now()
            : state.dueDate,
      );
    } else {
      state = state.copyWith(status: value, paidDate: null, paidAmount: null);
    }
  }

  void unsettle() {
    state = state.copyWith(status: InstallmentStatus.paid);
  }

  Future<void> delete() async {
    if (state.installmentId == null) return;

    await financeService.cancelInstallment(
      state.installmentId!,
      replicationCascade: state.replicateCascade ?? ReplicationCascade.none,
    );
  }

  @override
  Future<dynamic> submit() async {
    if (state.formType == TransactionFormType.order) {
      final order = state.asOrderModel();

      if (state.creation) {
        final saved = await financeService.addOrder(order);

        state = state.copyWith(orderId: saved.id);

        return saved;
      } else {
        await financeService.updateOrder(order);

        return order;
      }
    } else {
      final installment = state.asInstallmentModel();

      await financeService.updateInstallment(installment);

      return installment;
    }
  }

  bool get shouldAskCascade {
    if (state.creation || state.formType != TransactionFormType.installment) {
      return false;
    }

    // Se for uma parcela única, não faz sentido perguntar cascade
    if (state.installmentType == InstallmentType.single) {
      return false;
    }

    final original = state.installmentId != null
        ? state
              .asInstallmentModel() // Na verdade precisaria do original pra comparar, mas vamos assumir que se mudou algo além desses 3, pergunta.
        : null;

    // A lógica de "não se aplica pra alterações de status, data de pagamento ou valor de pagamento"
    // será tratada no momento da submissão na UI para decidir se abre a modal ou não.
    return true;
  }
}
