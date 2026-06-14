import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/data/repositories/account_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/automatic_transaction_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/period_summary_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/planning_repository_impl.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/automatic_transaction_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/invoice_service.dart';
import 'package:funances/features/finance/domain/services/notification_listener_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/domain/services/planning_service.dart';
import 'package:funances/features/finance/presentation/controllers/account_form_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/account_statement_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/automatic_transaction_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/category_planning_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/planning_50_30_20_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/reconciliation_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_filter_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_wizard_notifier.dart';
import 'package:funances/features/finance/presentation/model/transaction_filter_view_models.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

class AutomaticTransactionDomainProviders {
  static final repository = Provider<IAutomaticTransactionRepository>((ref) {
    return AutomaticTransactionRepositoryImpl();
  });

  static final service = Provider<AutomaticTransactionService>((ref) {
    final workspace = ref
        .watch(WorkspaceViewProviders.workspace)
        .currentWorkspace;
    return AutomaticTransactionService(
      workspaceId: workspace?.id ?? "",
      repository: ref.watch(repository),
    );
  });

  static final notificationService = Provider<INotificationListenerService>((
    ref,
  ) {
    return NotificationListenerService(service: ref.watch(service));
  });
}

class AutomaticTransactionViewProviders {
  static final automaticTransactions =
      StateNotifierProvider.autoDispose<
        AutomaticTransactionNotifier,
        AutomaticTransactionState
      >((ref) {
        return AutomaticTransactionNotifier(
          service: ref.watch(AutomaticTransactionDomainProviders.service),
          financeService: ref.watch(FinanceDomainProviders.service),
          notificationService: ref.watch(
            AutomaticTransactionDomainProviders.notificationService,
          ),
        );
      });
}

class PlanningDomainProviders {
  static final repository = Provider((ref) => PlanningRepositoryImpl());

  static final service = Provider(
    (ref) => PlanningService(
      workspaceId:
          ref.watch(WorkspaceViewProviders.workspace).currentWorkspace?.id ??
          "",
      repository: ref.read(repository),
    ),
  );
}

class AccountDomainProviders {
  static final repository = Provider<IAccountRepository>((ref) {
    return AccountRepositoryImpl();
  });

  static final service = Provider<AccountService>(
    (ref) => AccountService(
      workspaceId:
          ref.watch(WorkspaceViewProviders.workspace).currentWorkspace?.id ??
          "",
      repository: ref.read(repository),
      workspaceRepository: ref.read(WorkspaceDomainProviders.repository),
    ),
  );
}

class FinanceDomainProviders {
  static final repository = Provider((ref) => FinanceRepositoryImpl());

  static final service = Provider(
    (ref) => FinanceService(
      workspaceId:
          ref.watch(WorkspaceViewProviders.workspace).currentWorkspace?.id ??
          "",
      repository: ref.read(repository),
      accountRepository: ref.read(AccountDomainProviders.repository),
      categoryRepository: ref.watch(CategoryDomainProviders.repository),
    ),
  );
}

class AccountViewProviders {
  static final latestBalanceById =
      StreamProvider.family<AccountBalanceModel, String>((ref, accountId) {
        return ref
            .watch(AccountDomainProviders.service)
            .getLatestAccountBalance(accountId);
      });

  static final all = StreamProvider(
    (ref) => ref.watch(AccountDomainProviders.service).getAccounts(),
  );

  static final byId = StreamProvider.family<AccountModel?, String>((
    ref,
    accountId,
  ) {
    final accounts = ref.watch(all);

    return accounts.when(
      data: (data) => Stream.value(
        data.where((account) => account.id == accountId).firstOrNull,
      ),
      error: (error, stack) => Stream.error(error, stack),
      loading: () => Stream.empty(),
    );
  });

  static final byTypeMap = StreamProvider(
    (ref) => ref.watch(AccountDomainProviders.service).getAccountsByType(),
  );

  static final overviewType = StateProvider((ref) => AccountType.checking);

  static final form = StateNotifierProvider.autoDispose
      .family<AccountFormNotifier, AccountFormState, AccountFormArgs>((
        ref,
        args,
      ) {
        return AccountFormNotifier(
          accountService: ref.watch(AccountDomainProviders.service),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
          account: args.account,
          type: args.type,
        );
      });

  static final latestBalanceByType = Provider.family<double, AccountType>((
    ref,
    type,
  ) {
    final List<AccountModel> accounts = ref.watch(
      AccountViewProviders.byTypeMap.select((acc) => acc.value?[type] ?? []),
    );

    if (accounts.isEmpty) {
      return 0;
    }

    return accounts
        .map(
          (account) =>
              ref
                  .watch(AccountViewProviders.latestBalanceById(account.id))
                  .value
                  ?.balance ??
              0,
        )
        .reduce((v1, v2) => v1 + v2);
  });

  static final nextInvoiceByAccountId =
      StreamProvider.family<InstallmentModel?, String>((ref, accountId) {
        return ref
            .watch(FinanceDomainProviders.service)
            .watchNextInvoice(accountId);
      });

  static final balanceAtDate = StreamProvider.autoDispose
      .family<AccountBalanceModel, ({String accountId, DateTime date})>((
        ref,
        args,
      ) {
        return ref
            .watch(AccountDomainProviders.service)
            .getAccountBalanceAtDate(args.accountId, args.date);
      });
}

class PlanningViewProviders {
  static final currentList = StreamProvider((ref) {
    final service = ref.watch(PlanningDomainProviders.service);
    final date = DateTime.now();

    return service.watchPlannings(month: date.month, year: date.year);
  });
}

class FinanceViewProviders {
  static final creationForm = StateNotifierProvider.autoDispose
      .family<
        TransactionFormNotifier,
        TransactionFormState,
        TransactionCreationArgs
      >((ref, args) {
        return TransactionFormNotifier(
          TransactionFormState.creation(
            type: args.type,
            status: args.status,
            category: args.category,
            accountIdSource: args.accountIdSource,
            accountIdTarget: args.accountIdTarget,
            amount: args.amount,
            description: args.description,
            date: args.date,
          ),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
        );
      });

  static final updateOrderForm = StateNotifierProvider.autoDispose
      .family<TransactionFormNotifier, TransactionFormState, OrderModel>((
        ref,
        order,
      ) {
        return TransactionFormNotifier(
          TransactionFormState.updateOrder(order),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
        );
      });

  static final updateInstallmentForm = StateNotifierProvider.autoDispose
      .family<TransactionFormNotifier, TransactionFormState, InstallmentModel>((
        ref,
        installment,
      ) {
        return TransactionFormNotifier(
          TransactionFormState.updateInstallment(installment),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
        );
      });

  static final transactionPaymentForm = StateNotifierProvider.autoDispose
      .family<TransactionFormNotifier, TransactionFormState, InstallmentModel>((
        ref,
        installment,
      ) {
        return TransactionFormNotifier(
          TransactionFormState.updateInstallment(
            installment,
            status: InstallmentStatus.paid,
          ),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
        );
      });

  static final reconciliationForm = StateNotifierProvider.autoDispose
      .family<
        TransactionFormNotifier,
        TransactionFormState,
        TransactionFormState
      >((ref, initialState) {
        return TransactionFormNotifier(
          initialState,
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
        );
      });

  static final transactionFilter = StateNotifierProvider.autoDispose
      .family<
        TransactionFilterNotifier,
        TransactionFilterState,
        TransactionQuery
      >((ref, query) {
        final category = query.categoryId != null
            ? ref
                  .read(CategoryViewProviders.byId(query.categoryId!))
                  .valueOrNull
            : null;

        return TransactionFilterNotifier(
          TransactionFilterState.fromQuery(query, category: category),
        );
      });

  static final history = StateNotifierProvider(
    (ref) => TransactionListNotifier(
      financeiroService: ref.watch(FinanceDomainProviders.service),
    ),
  );

  static final invoiceInstallmentsList =
      StateNotifierProvider.family<
        TransactionListNotifier,
        InfiniteListState<TransactionQuery, InstallmentModel>,
        InstallmentModel
      >((ref, invoice) {
        final accountAsync = ref.watch(
          AccountViewProviders.byId(invoice.accountIdTarget ?? ""),
        );

        final query = accountAsync.when(
          data: (account) {
            if (account == null) return TransactionQuery();

            final (start, end) = InvoiceService.calculateInvoiceCycleRange(
              invoice.dueDate,
              account,
            );

            return TransactionQuery(
              accountId: account.id,
              startDate: start,
              endDate: end,
            );
          },
          error: (_, __) => TransactionQuery(),
          loading: () => TransactionQuery(),
        );

        return TransactionListNotifier(
          financeiroService: ref.watch(FinanceDomainProviders.service),
          initialQuery: query,
        );
      });

  static final goalTransactions =
      StateNotifierProvider.family<
        TransactionListNotifier,
        InfiniteListState<TransactionQuery, InstallmentModel>,
        TransactionQuery
      >((ref, query) {
        return TransactionListNotifier(
          financeiroService: ref.watch(FinanceDomainProviders.service),
          initialQuery: query,
        );
      });

  static final statement =
      StateNotifierProvider.family<
        AccountStatementNotifier,
        InfiniteListState<TransactionQuery, InstallmentModel>,
        ({String accountId, bool isFuture})
      >((ref, args) {
        return AccountStatementNotifier(
          financeiroService: ref.watch(FinanceDomainProviders.service),
          accountId: args.accountId,
          isFuture: args.isFuture,
        );
      });

  static final wizard = StateNotifierProvider.autoDispose
      .family<
        TransactionWizardNotifier,
        TransactionWizardState,
        TransactionWizardArgs
      >((ref, args) {
        return TransactionWizardNotifier(
          TransactionWizardState(
            type: args.type,
            skipTransactions: args.skipTransactions,
          ),
          financeService: ref.watch(FinanceDomainProviders.service),
        );
      });

  static final pendingInstallments = StreamProvider.autoDispose
      .family<List<InstallmentModel>, ({OrderType type, String? categoryId})>((
        ref,
        args,
      ) {
        final service = ref.watch(FinanceDomainProviders.service);
        final today = DateTime.now();
        return service.watchInstallments(
          type: args.type,
          categoryId: args.categoryId,
          status: InstallmentStatus.pending,
          startDate: DateTime(today.year, today.month, 1),
          endDate: DateTime(today.year, today.month + 1, 0),
        );
      });

  static final categoryPlanningForm = StateNotifierProvider.autoDispose
      .family<
        CategoryPlanningNotifier,
        CategoryPlanningState,
        CategoryPlanningArgs
      >((ref, args) {
        return CategoryPlanningNotifier(
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
          type: args.type,
        );
      });

  static final reconciliation = StateNotifierProvider.autoDispose
      .family<ReconciliationNotifier, ReconciliationState, AccountModel>((
        ref,
        account,
      ) {
        return ReconciliationNotifier(
          accountService: ref.watch(AccountDomainProviders.service),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
          account: account,
        );
      });

  static final reconciliationPicker =
      StateNotifierProvider<
        TransactionListNotifier,
        InfiniteListState<TransactionQuery, InstallmentModel>
      >((ref) {
        return TransactionListNotifier(
          financeiroService: ref.watch(FinanceDomainProviders.service),
        );
      });

  static final invoiceInstallments =
      StreamProvider.family<List<InstallmentModel>, InstallmentModel>((
        ref,
        invoice,
      ) {
        final accountAsync = ref.watch(
          AccountViewProviders.byId(invoice.accountIdTarget!),
        );

        return accountAsync.when(
          data: (account) {
            if (account == null) return Stream.value([]);

            final (start, end) = InvoiceService.calculateInvoiceCycleRange(
              invoice.dueDate,
              account,
            );

            return ref
                .watch(FinanceDomainProviders.service)
                .watchInstallments(
                  accountId: account.id,
                  startDate: start,
                  endDate: end,
                );
          },
          error: (e, s) {
            print(e.toString());

            return Stream.error(e, s);
          },
          loading: () => const Stream.empty(),
        );
      });

  static final invoicePieChart =
      StreamProvider.family<List<CategoryAmountModel>, InstallmentModel>((
        ref,
        invoice,
      ) {
        final installments = ref.watch(invoiceInstallments(invoice));

        return installments.when(
          data: (data) {
            final map = data
                .where((installment) => installment.type == OrderType.expense)
                .fold<Map<CategoryModel, double>>({}, (map, installment) {
                  map.update(
                    installment.category!,
                    (value) => value + installment.referenceAmount,
                    ifAbsent: () => installment.referenceAmount,
                  );
                  return map;
                });

            final list =
                map.entries
                    .toList()
                    .map(
                      (entry) => CategoryAmountModel(
                        category: entry.key,
                        amount: entry.value,
                      ),
                    )
                    .toList()
                  ..sort((e1, e2) => e1.amount < e2.amount ? 1 : -1);

            return Stream.value(list);
          },
          error: (e, s) => Stream.error(e, s),
          loading: () => const Stream.empty(),
        );
      });

  static final planning503020Service = Provider<Planning503020Service>((ref) {
    return Planning503020Service(
      financeService: ref.watch(FinanceDomainProviders.service),
      categoryService: ref.watch(CategoryDomainProviders.service),
      periodSummaryService: ref.watch(PeriodSummaryDomainProviders.service),
    );
  });

  static final planning503020 =
      StateNotifierProvider.autoDispose<
        Planning503020Notifier,
        CategoryPlanning503020State
      >((ref) {
        return Planning503020Notifier(
          planning503020Service: ref.watch(planning503020Service),
        );
      });

  static final planning503020Distribution = StreamProvider.autoDispose
      .family<Planning503020Distribution, DateTime>((ref, date) {
        return ref.watch(planning503020Service).watchDistribution(date);
      });

  static final planning503020GlobalProgress =
      Provider.autoDispose<CategoryGlobalProgressModel>((ref) {
        final state = ref.watch(planning503020);

        // Calculando renda total prevista (simplificado: soma de todos os planejamentos se tivéssemos acesso fácil,
        // mas aqui vamos focar na soma das despesas planejadas para referência ou usar um valor fixo se o sistema permitir.
        // Para o 50-30-20, o ideal é baseado no TOTAL planejado para o mês.
        final totalPlanned = state.items.fold<double>(
          0,
          (sum, item) => sum + item.effectiveAmount,
        );
        final totalActual = state.items.fold<double>(
          0,
          (sum, item) => sum + item.actualAmount,
        );
        final totalIncome = state.totalIncomes;

        final actualPercentage = totalIncome > 0
            ? (state.totalActualIncomes / totalIncome)
            : 0.0;
        final expenseActualPercentage = totalIncome > 0
            ? (totalActual / totalIncome)
            : 0.0;

        return CategoryGlobalProgressModel(
          totalPlanned: totalPlanned,
          totalActual: totalActual,
          totalIncome: totalIncome,
          actualPercentage: actualPercentage,
          expenseActualPercentage: expenseActualPercentage,
        );
      });

  static final planning503020AllocationProgress = Provider.autoDispose
      .family<CategoryAllocationProgressModel, CategoryAllocation>((
        ref,
        allocation,
      ) {
        final items = ref.watch(
          planning503020.select(
            (planning) => planning.items
                .where((item) => item.category.allocation == allocation)
                .toList(),
          ),
        );
        final totalPlanned = ref.watch(
          planning503020GlobalProgress.select((state) => state.totalPlanned),
        );
        final totalIncome = ref.watch(
          planning503020GlobalProgress.select((state) => state.totalIncome),
        );

        final currentTotal = items.fold<double>(
          0,
          (sum, item) => sum + item.effectiveAmount,
        );
        final currentActual = items.fold<double>(
          0,
          (sum, item) => sum + item.actualAmount,
        );
        final idealValue = totalIncome * allocation.idealPercentage;
        final currentPercentage = totalPlanned > 0
            ? (currentTotal / totalPlanned)
            : 0.0;
        final actualPercentage = totalPlanned > 0
            ? (currentActual / totalPlanned)
            : 0.0;

        // Indica se está dentro da meta (não ultrapassa o ideal em relação à receita)
        final isWithinRange = currentTotal <= idealValue;
        final isOver = currentTotal > idealValue;

        return CategoryAllocationProgressModel(
          currentTotal: currentTotal,
          currentActual: currentActual,
          idealValue: idealValue,
          currentPercentage: currentPercentage,
          actualPercentage: actualPercentage,
          isWithinRange: isWithinRange,
          isOver: isOver,
        );
      });
}

class PeriodSummaryDomainProviders {
  static final repository = Provider((ref) => PeriodSummaryRepositoryImpl());

  static final service = Provider(
    (ref) => PeriodSummaryService(
      workspaceId:
          ref.watch(WorkspaceViewProviders.workspace).currentWorkspace?.id ??
          "",
      repository: ref.read(repository),
    ),
  );
}

List<OverviewCategorySummary> _mapToOverview(
  PeriodSummaryModel? summary,
  List<CategoryModel> categories,
) {
  final List<OverviewCategorySummary> result = [];
  if (summary == null) return result;

  summary.categories.forEach((categoryId, data) {
    final category = categories.where((c) => c.id == categoryId).firstOrNull;

    if (category != null) {
      result.add(
        OverviewCategorySummary(
          category: category,
          generalPlannedAmount: data.generalPlannedAmount,
          specificPlannedAmount: data.specificPlannedAmount,
          actualAmount: data.actualAmount,
        ),
      );
    }
  });
  return result;
}

class PeriodSummaryViewProviders {
  static final monthSummary =
      StreamProvider.family<List<OverviewCategorySummary>, DateTime>((
        ref,
        period,
      ) {
        final service = ref.watch(PeriodSummaryDomainProviders.service);
        final List<CategoryModel> categories = ref
            .watch(CategoryViewProviders.allStream)
            .when(
              data: (data) => data,
              error: (_, __) => [],
              loading: () => [],
            );

        return service
            .watchMonth(period.year, period.month)
            .map((summary) => _mapToOverview(summary, categories));
      });

  static final yearSummary =
      StreamProvider.family<List<OverviewCategorySummary>, DateTime>((
        ref,
        period,
      ) {
        final service = ref.watch(PeriodSummaryDomainProviders.service);
        final List<CategoryModel> categories = ref
            .watch(CategoryViewProviders.allStream)
            .when(
              data: (data) => data,
              error: (_, __) => [],
              loading: () => [],
            );

        return service
            .watchYear(period.year)
            .map((summary) => _mapToOverview(summary, categories));
      });
}
