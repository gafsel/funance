import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionWizardNotifier extends StateNotifier<TransactionWizardState> {
  final FinanceService financeService;

  TransactionWizardNotifier(super.state, {required this.financeService}) {
    if (state.type == OrderType.transfer) {
      if (state.skipTransactions) {
        state = state.copyWith(step: TransactionWizardStep.form);
        return;
      }

      state = state.copyWith(step: TransactionWizardStep.transactions);
      _checkPendingTransfer();
    }
  }

  void _checkPendingTransfer() async {
    if (state.skipTransactions) return;
    try {
      final today = DateTime.now();
      final pending = await financeService.queryInstallments(
        limit: 1,
        type: OrderType.transfer,
        status: InstallmentStatus.pending,
        startDate: DateTime(today.year, today.month, 1),
        endDate: DateTime(today.year, today.month + 1, 0),
      );

      if (pending.items.isEmpty) {
        state = state.copyWith(step: TransactionWizardStep.form);
      }
      // If items exist, it remains in transactions step which we set above
    } catch (e) {
      state = state.copyWith(step: TransactionWizardStep.form);
    }
  }

  void selectCategory(CategoryModel category) async {
    state = state.copyWith(
      selectedCategory: category,
    );

    if (state.skipTransactions) {
      state = state.copyWith(step: TransactionWizardStep.form);
      return;
    }

    try {
      final today = DateTime.now();
      final pending = await financeService.queryInstallments(
        limit: 1,
        type: state.type,
        categoryId: category.id,
        status: InstallmentStatus.pending,
        startDate: DateTime(today.year, today.month, 1),
        endDate: DateTime(today.year, today.month + 1, 0),
      );

      if (pending.items.isEmpty) {
        state = state.copyWith(step: TransactionWizardStep.form);
      } else {
        state = state.copyWith(step: TransactionWizardStep.transactions);
      }
    } catch (e) {
      state = state.copyWith(step: TransactionWizardStep.form);
    }
  }

  void selectInstallment(InstallmentModel? installment) {
    state = state.copyWith(
      selectedInstallment: installment,
      step: TransactionWizardStep.form,
    );
  }

  void back() {
    if (state.step == TransactionWizardStep.transactions &&
        state.type == OrderType.transfer) {
      // For transfers, going back from transactions should go to form or eventually quit
      // But usually it should just stay or pop. In this wizard, we just pop at the screen level if needed.
      // However, the router handles the exit. If they go back from the first real step, it should pop.
      return;
    }

    if (state.step != TransactionWizardStep.category) {
      state = state.copyWith(
        step: TransactionWizardStep.values[state.step.index - 1],
      );
    }
  }
}
