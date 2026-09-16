import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionWizardNotifier extends StateNotifier<TransactionWizardState> {
  final FinanceService financeService;

  /// Fonte do "hoje". O wizard vive aberto enquanto o usuário navega, então a
  /// janela precisa ser recalculada a cada consulta — e ser testável na
  /// virada do mês.
  final Clock now;

  TransactionWizardNotifier(
    super.state, {
    required this.financeService,
    Clock? now,
  }) : now = now ?? DateTime.now {
    if (state.type == OrderType.transfer) {
      if (state.skipTransactions) {
        state = state.copyWith(step: TransactionWizardStep.form);
        return;
      }

      state = state.copyWith(step: TransactionWizardStep.transactions);
      _checkPendingTransfer();
    }
  }

  /// Início e fim do mês corrente. O fim precisa cobrir o dia inteiro:
  /// `DateTime(y, m+1, 0)` seria meia-noite do último dia e excluiria os
  /// lançamentos desse dia (normalizados às 12:00).
  static ({DateTime start, DateTime end}) monthRange(DateTime today) {
    return (
      start: DateTime(today.year, today.month, 1),
      end: DateTime(today.year, today.month + 1, 0, 23, 59, 59),
    );
  }

  ({DateTime start, DateTime end}) _currentMonthRange() => monthRange(now());

  void _checkPendingTransfer() async {
    if (state.skipTransactions) return;
    try {
      final range = _currentMonthRange();
      final pending = await financeService.queryInstallments(
        limit: 1,
        type: OrderType.transfer,
        accountId: state.accountIdSource,
        status: InstallmentStatus.pending,
        startDate: range.start,
        endDate: range.end,
      );

      if (!mounted) return;
      if (pending.items.isEmpty) {
        state = state.copyWith(step: TransactionWizardStep.form);
      }
      // If items exist, it remains in transactions step which we set above
    } catch (e) {
      if (!mounted) return;
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
      final range = _currentMonthRange();
      final pending = await financeService.queryInstallments(
        limit: 1,
        type: state.type,
        categoryId: category.id,
        accountId: state.accountIdSource,
        status: InstallmentStatus.pending,
        startDate: range.start,
        endDate: range.end,
      );

      if (!mounted) return;
      // Resposta atrasada de uma categoria que não é mais a selecionada não
      // deve mudar o passo do wizard.
      if (state.selectedCategory?.id != category.id) return;

      if (pending.items.isEmpty) {
        state = state.copyWith(step: TransactionWizardStep.form);
      } else {
        state = state.copyWith(step: TransactionWizardStep.transactions);
      }
    } catch (e) {
      if (!mounted) return;
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
