import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionFormNotifier extends FormNotifier<TransactionFormState, void> {
  final FinanceService financeService;

  TransactionFormNotifier(super.initialState, {required this.financeService}):super();

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

  void updatePaidDate(DateTime? value) => state = state.copyWith(paidDate: value);

  void updatePaidAmount(double? value) => state = state.copyWith(paidAmount: value);

  void updateStatus(InstallmentStatus value) {
    state = state.copyWith(
      status: value,
      paidAmount: value == InstallmentStatus.paid ? state.amount : state.paidAmount,
      paidDate: value == InstallmentStatus.paid ? DateTime.now() : state.paidDate,
    );
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
}
