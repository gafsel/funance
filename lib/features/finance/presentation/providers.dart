import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/data/repositories/account_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/period_summary_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/planning_repository_impl.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/planning_service.dart';
import 'package:funances/features/finance/presentation/controllers/account_form_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/category_planning_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_wizard_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/reconciliation_notifier.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

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
        );
      });

  static final history = StateNotifierProvider(
    (ref) => TransactionListNotifier(
      financeiroService: ref.watch(FinanceDomainProviders.service),
    ),
  );

  static final wizard = StateNotifierProvider.autoDispose
      .family<TransactionWizardNotifier, TransactionWizardState, TransactionWizardArgs>((
    ref,
    args,
  ) {
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

  static final reconciliation = StateNotifierProvider.autoDispose<
      ReconciliationNotifier,
      ReconciliationState
  >((ref) {
    return ReconciliationNotifier(
      accountService: ref.watch(AccountDomainProviders.service),
      financeService: ref.watch(FinanceDomainProviders.service),
      categoryService: ref.watch(CategoryDomainProviders.service),
    );
  });

  static final reconciliationPicker = StateNotifierProvider<
      TransactionListNotifier,
      InfiniteListState<TransactionQuery, InstallmentModel>
  >((ref) {
    return TransactionListNotifier(
      financeiroService: ref.watch(FinanceDomainProviders.service),
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
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(
        id: categoryId,
        name: 'Unknown',
        icon: 'help',
        color: '0xFF000000',
      ),
    );

    result.add(
      OverviewCategorySummary(
        category: category,
        generalPlannedAmount: data.generalPlannedAmount,
        specificPlannedAmount: data.specificPlannedAmount,
        actualAmount: data.actualAmount,
      ),
    );
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
