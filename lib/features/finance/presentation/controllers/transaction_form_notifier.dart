import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

class TransactionFormNotifier
    extends FormNotifier<TransactionFormState, dynamic> {
  final FinanceService financeService;
  final CategoryService categoryService;
  final AnalyticsService analytics;

  TransactionFormNotifier(
    super.initialState, {
    required this.financeService,
    required this.categoryService,
    required this.analytics,
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
    // Captura o status anterior antes de salvar: é o que diz se esta submissão
    // foi a que quitou a parcela.
    final wasAlreadyPaid = _isPaid(state.status);

    final dynamic result;
    if (state.formType == TransactionFormType.order) {
      final order = state.asOrderModel();

      if (state.creation) {
        final saved = await financeService.addOrder(order);

        state = state.copyWith(orderId: saved.id);

        result = saved;
      } else {
        await financeService.updateOrder(order);

        result = order;
      }
    } else {
      final installment = state.asInstallmentModel();

      await financeService.updateInstallment(installment);

      result = installment;
    }

    await _logSaved(wasAlreadyPaid: wasAlreadyPaid);

    return result;
  }

  static bool _isPaid(InstallmentStatus status) =>
      status == InstallmentStatus.paid || status == InstallmentStatus.settled;

  /// Emite os eventos do funil. Nunca propaga erro: analytics não pode
  /// derrubar o salvamento de um lançamento.
  Future<void> _logSaved({required bool wasAlreadyPaid}) async {
    try {
      await analytics.logTransactionSaved(
        status: state.status.name,
        hadPlanning: await _hadPlanning(),
        type: state.type.name,
      );

      // Só conta como pagamento quando a parcela já existia e ainda não estava
      // quitada — evita contar duas vezes ao reeditar algo já pago.
      final isInstallment = state.formType == TransactionFormType.installment;
      if (isInstallment && _isPaid(state.status)) {
        await analytics.logInstallmentPaid();

        // Uma missão semanal é exatamente uma parcela da semana corrente que
        // passou a paga/quitada.
        if (!wasAlreadyPaid && _isInCurrentWeek(state.dueDate)) {
          await analytics.logMissionCompleted();
        }
      }
    } catch (_) {
      // Silencioso de propósito.
    }
  }

  /// true se a categoria já tinha planejamento vigente no mês OU se o
  /// lançamento casou com uma parcela pendente já existente.
  Future<bool> _hadPlanning() async {
    if (state.formType == TransactionFormType.installment) return true;

    final category = state.category;
    if (category == null) return false;

    try {
      final month = state.dueDate.formated("yyyy-MM");
      final plannings = await financeService.getCategoryPlannings(
        startMonth: month,
        endMonth: month,
      );

      return plannings.any((p) => p.category.id == category.id);
    } catch (_) {
      return false;
    }
  }

  static bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
  }

  bool get shouldAskCascade {
    if (state.creation || state.formType != TransactionFormType.installment) {
      return false;
    }

    // Se for uma parcela única, não faz sentido perguntar cascade
    if (state.installmentType == InstallmentType.single) {
      return false;
    }

    // A lógica de "não se aplica pra alterações de status, data de pagamento ou valor de pagamento"
    // será tratada no momento da submissão na UI para decidir se abre a modal ou não.
    return true;
  }
}
