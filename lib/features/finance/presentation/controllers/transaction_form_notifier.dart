import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionFormNotifier extends FormNotifier<TransactionFormState, void> {
  final FinanceService financeService;

  TransactionFormNotifier(super.initialState, {required this.financeService})
    : super();

  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  void updateAmount(double value) => state = state.copyWith(amount: value);

  void updateInstallmentCount(int value) =>
      state = state.copyWith(installmentCount: value);

  void updateDueDate(DateTime value) => state = state.copyWith(dueDate: value);

  void updateCategory(CategoryModel? value) =>
      state = state.copyWith(category: value);

  void updateAccountIdTarget(String? value) =>
      state = state.copyWith(accountIdTarget: value);

  void updateAccountIdSource(String? value) =>
      state = state.copyWith(accountIdSource: value);

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

  void updatePaidDate(DateTime? value) =>
      state = state.copyWith(paidDate: value);

  void updatePaidAmount(double? value) =>
      state = state.copyWith(paidAmount: value);

  void updateReplicationCascade(ReplicationCascade? value) =>
      state = state.copyWith(replicateCascade: value);

  void updateStatus(InstallmentStatus value) {
    if (value == InstallmentStatus.paid) {
      state = state.copyWith(
        status: value,
        paidAmount: state.amount,
        paidDate: state.dueDate.isAfter(DateTime.now())
            ? DateTime.now()
            : state.dueDate,
      );
    } else {
      state = state.copyWith(status: value);
    }
  }

  void unsettle() {
    state = state.copyWith(status: InstallmentStatus.paid);
  }

  Future<bool> submit() async {
    if (state.formType == TransactionFormType.order) {
      final order = state.asOrderModel();

      if (state.creation) {
        await financeService.addOrder(order);

        state = state.copyWith(orderId: order.id);
      } else {
        await financeService.updateOrder(order);
      }

      return true;
    } else {
      final installment = state.asInstallmentModel();

      await financeService.updateInstallment(installment);

      return true;
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
