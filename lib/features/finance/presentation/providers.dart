import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/date_extension.dart';
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
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/repositories/planning_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/automatic_transaction_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/notification_listener_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/data/repositories/planning_analysis_repository_impl.dart';
import 'package:funances/features/finance/domain/repositories/planning_analysis_repository.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/domain/services/planning_analysis_service.dart';
import 'package:funances/features/finance/domain/repositories/reconciliation_repository.dart';
import 'package:funances/features/finance/data/repositories/reconciliation_repository_impl.dart';
import 'package:funances/features/finance/domain/services/reconciliation_service.dart';
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
    return AutomaticTransactionService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
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

/// O único consumidor restante é o onboarding, que grava os planejamentos
/// sugeridos direto pelo repositório. O `PlanningService` e o
/// `PlanningViewProviders.currentList` que existiam aqui eram um slice morto,
/// paralelo a `FinanceService.getCategoryPlannings`.
class PlanningDomainProviders {
  static final repository = Provider<IPlanningRepository>(
    (ref) => PlanningRepositoryImpl(),
  );
}

class AccountDomainProviders {
  static final repository = Provider<IAccountRepository>((ref) {
    return AccountRepositoryImpl();
  });

  static final service = Provider<AccountService>(
    (ref) => AccountService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
      workspaceRepository: ref.read(WorkspaceDomainProviders.repository),
    ),
  );
}

class FinanceDomainProviders {
  static final repository = Provider<IFinanceRepository>(
    (ref) => FinanceRepositoryImpl(),
  );

  static final service = Provider(
    (ref) => FinanceService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
      accountRepository: ref.read(AccountDomainProviders.repository),
      categoryRepository: ref.watch(CategoryDomainProviders.repository),
    ),
  );
}

class PlanningAnalysisDomainProviders {
  static final repository = Provider.autoDispose<IPlanningAnalysisRepository>((
    ref,
  ) {
    return PlanningAnalysisRepositoryImpl();
  });

  static final service = Provider.autoDispose<PlanningAnalysisService>((ref) {
    return PlanningAnalysisService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.watch(repository),
    );
  });
}

class ReconciliationDomainProviders {
  static final repository = Provider<IReconciliationRepository>((ref) {
    return ReconciliationRepositoryImpl();
  });

  static final service = Provider<ReconciliationService>((ref) {
    return ReconciliationService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
      accountService: ref.watch(AccountDomainProviders.service),
      financeService: ref.watch(FinanceDomainProviders.service),
      categoryService: ref.watch(CategoryDomainProviders.service),
    );
  });
}

/// Chave estável de uma fatura.
///
/// Chavear a família pelo `InstallmentModel` inteiro vazava um provider a
/// cada edição: freezed gera um valor novo (e portanto uma chave nova) quando
/// qualquer campo muda, e o provider antigo ficava para trás. O id identifica
/// a fatura; a conta, o vencimento e a janela do ciclo são o que o provider
/// precisa, e nenhum deles muda ao editar valor ou descrição.
///
/// F1.8: `cycleStart`/`cycleEnd` vêm PRONTOS do servidor, gravados na própria
/// parcela da fatura. Antes o app recalculava a janela com uma cópia Dart da
/// regra que já divergia da do servidor no clamp do dia — e, como o id da order
/// de fatura deriva da data, os dois podiam falar de faturas diferentes.
typedef InvoiceKey = ({
  String invoiceId,
  String accountId,
  DateTime dueDate,
  DateTime? cycleStart,
  DateTime? cycleEnd,
});

extension InvoiceKeyWindow on InvoiceKey {
  /// `true` quando o servidor já publicou a janela desta fatura.
  bool get hasServerCycle =>
      accountId.isNotEmpty && cycleStart != null && cycleEnd != null;
}

extension InvoiceKeyExtension on InstallmentModel {
  /// Usa a mesma cadeia de resolução de conta da tela de detalhe
  /// (`resolvedAccountId`): cair em string vazia aqui faria o provider
  /// consultar sem filtro de conta e listar o extrato inteiro.
  InvoiceKey get invoiceKey => (
    invoiceId: id,
    accountId: resolvedAccountId ?? "",
    dueDate: dueDate,
    cycleStart: cycleStart,
    cycleEnd: cycleEnd,
  );
}

class AccountViewProviders {
  static final latestBalanceById = StreamProvider.autoDispose
      .family<AccountBalanceModel, String>((ref, accountId) {
        return ref
            .watch(AccountDomainProviders.service)
            .getLatestAccountBalance(accountId);
      });

  static final all = StreamProvider(
    (ref) => ref.watch(AccountDomainProviders.service).getAccounts(),
  );

  static final byId = StreamProvider.autoDispose.family<AccountModel?, String>((
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

  static final form = StateNotifierProvider.autoDispose
      .family<AccountFormNotifier, AccountFormState, AccountFormArgs>((
        ref,
        args,
      ) {
        return AccountFormNotifier(
          accountService: ref.watch(AccountDomainProviders.service),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
          analytics: ref.watch(analyticsServiceProvider),
          account: args.account,
          type: args.type,
        );
      });

  /// Soma dos saldos das contas de um tipo.
  ///
  /// Os saldos são combinados num único stream em vez de um `ref.watch` por
  /// conta dentro do `map`: o `watch` em loop registrava uma dependência nova
  /// a cada rebuild e somava 0 para toda conta cujo saldo ainda não tivesse
  /// chegado, mostrando um total errado como se fosse definitivo. Agora o
  /// provider só emite quando todas as contas já responderam — enquanto isso
  /// fica em `AsyncLoading`, e a tela deve mostrar carregamento em vez de
  /// zero.
  static final latestBalanceByType = StreamProvider.autoDispose
      .family<double, AccountType>((ref, type) {
        final List<AccountModel> accounts = ref.watch(
          AccountViewProviders.byTypeMap.select(
            (acc) => acc.value?[type] ?? const <AccountModel>[],
          ),
        );

        if (accounts.isEmpty) {
          return Stream.value(0);
        }

        final service = ref.watch(AccountDomainProviders.service);

        return Rx.combineLatestList(
          accounts.map((account) => service.getLatestAccountBalance(account.id)),
        ).map(
          (balances) => balances.fold<double>(
            0,
            (total, balance) => total + balance.balance,
          ),
        );
      });

  /// Resumo da próxima fatura, LIDO do documento da conta (F1.8).
  ///
  /// O servidor é a única fonte de vencimento, fechamento e janela de ciclo.
  /// `null` significa "ainda não sei" — conta que não é cartão, ou cartão cujo
  /// resumo o servidor ainda não gravou (base anterior ao backfill). A tela
  /// mostra "calculando" nesse caso, e nunca um valor inventado.
  static final nextInvoiceByAccountId = StreamProvider.autoDispose
      .family<NextInvoice?, String>((ref, accountId) {
        final accountAsync = ref.watch(AccountViewProviders.byId(accountId));

        return accountAsync.when(
          data: (account) => Stream.value(
            account is CreditCardAccount ? account.nextInvoice : null,
          ),
          error: (error, stack) => Stream.error(error, stack),
          loading: () => const Stream.empty(),
        );
      });

  /// A PARCELA da próxima fatura, para navegar até a tela de detalhe (que
  /// recebe um `InstallmentModel`).
  ///
  /// FALLBACK TEMPORÁRIO documentado: enquanto a rota `/invoices/detail`
  /// receber o modelo inteiro, o app ainda precisa da parcela. A consulta é a
  /// mesma que o servidor faz para montar `nextInvoice`, então as duas
  /// concordam; o que saiu do cliente foi o CÁLCULO da fatura, não a leitura.
  /// Quando a rota passar a receber só o id, este provider sai.
  static final nextInvoiceInstallmentByAccountId = StreamProvider.autoDispose
      .family<InstallmentModel?, String>((ref, accountId) {
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
          analytics: ref.watch(analyticsServiceProvider),
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
          analytics: ref.watch(analyticsServiceProvider),
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
          analytics: ref.watch(analyticsServiceProvider),
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
          analytics: ref.watch(analyticsServiceProvider),
        );
      });

  static final transactionFilter = StateNotifierProvider.autoDispose
      .family<
        TransactionFilterNotifier,
        TransactionFilterState,
        TransactionQuery
      >((ref, query) {
        // `read` numa família autoDispose devolve sempre AsyncLoading na
        // primeira leitura (e ainda agenda o dispose do provider), então o
        // filtro de categoria vindo do detalhe de fatura era descartado em
        // silêncio. Com `watch` + `select` o notifier é reconstruído uma vez,
        // quando a categoria resolve, e não a cada emissão da lista.
        final category = query.categoryId == null
            ? null
            : ref.watch(
                CategoryViewProviders.byId(
                  query.categoryId!,
                ).select((async) => async.valueOrNull),
              );

        return TransactionFilterNotifier(
          TransactionFilterState.fromQuery(query, category: category),
        );
      });

  static final history = StateNotifierProvider.autoDispose<
    TransactionListNotifier,
    InfiniteListState<TransactionQuery, InstallmentModel>
  >((ref) {
    // A aba de histórico guarda filtros e as páginas já carregadas; sem o
    // keepAlive elas seriam descartadas a cada ida e volta para outra aba.
    ref.keepAlive();
    return TransactionListNotifier(
      financeiroService: ref.watch(FinanceDomainProviders.service),
    );
  });

  static final invoiceInstallmentsList =
      StateNotifierProvider.autoDispose.family<
        TransactionListNotifier,
        InfiniteListState<TransactionQuery, InstallmentModel>,
        InvoiceKey
      >((ref, invoice) {
        // A janela vem do servidor (gravada na própria parcela da fatura).
        // Sem ela — fatura anterior a F1.8, antes do backfill — a query fica
        // sem período em vez de usar um intervalo chutado: listar as compras
        // erradas é pior do que não listar nada.
        final query = invoice.hasServerCycle
            ? TransactionQuery(
                accountId: invoice.accountId,
                startDate: invoice.cycleStart,
                endDate: invoice.cycleEnd,
              )
            : TransactionQuery();

        return TransactionListNotifier(
          financeiroService: ref.watch(FinanceDomainProviders.service),
          initialQuery: query,
        );
      });

  static final goalTransactions =
      StateNotifierProvider.autoDispose.family<
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
      StateNotifierProvider.autoDispose.family<
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
        final today = ref.watch(todayProvider);

        return TransactionWizardNotifier(
          TransactionWizardState(
            type: args.type,
            skipTransactions: args.skipTransactions,
            accountIdSource: args.accountIdSource,
          ),
          financeService: ref.watch(FinanceDomainProviders.service),
          now: () => today,
        );
      });

  static final pendingInstallments = StreamProvider.autoDispose
      .family<List<InstallmentModel>, ({OrderType type, String? categoryId, String? accountId})>((
        ref,
        args,
      ) {
        final service = ref.watch(FinanceDomainProviders.service);
        final today = ref.watch(todayProvider);
        return service.watchInstallments(
          type: args.type,
          categoryId: args.categoryId,
          accountId: args.accountId,
          status: InstallmentStatus.pending,
          startDate: DateTime(today.year, today.month, 1),
          // Fim do dia para incluir os lançamentos do último dia do mês
          // (referenceDate é normalizado às 12:00).
          endDate: DateTime(today.year, today.month + 1, 0, 23, 59, 59),
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
          analytics: ref.watch(analyticsServiceProvider),
          type: args.type,
        );
      });

  static final reconciliation = StateNotifierProvider.autoDispose
      .family<ReconciliationNotifier, ReconciliationState, AccountModel>((
        ref,
        account,
      ) {
        return ReconciliationNotifier(
          reconciliationService: ref.watch(ReconciliationDomainProviders.service),
          account: account,
          analytics: ref.watch(analyticsServiceProvider),
        );
      });

  static final reconciliationPicker =
      StateNotifierProvider.autoDispose<
        TransactionListNotifier,
        InfiniteListState<TransactionQuery, InstallmentModel>
      >((ref) {
        return TransactionListNotifier(
          financeiroService: ref.watch(FinanceDomainProviders.service),
        );
      });

  static final invoiceInstallments = StreamProvider.autoDispose
      .family<List<InstallmentModel>, InvoiceKey>((ref, invoice) {
        if (!invoice.hasServerCycle) {
          developer.log(
            'Fatura ${invoice.invoiceId} sem janela de ciclo do servidor; '
            'aguardando a sincronização em vez de calcular no cliente.',
            name: 'funances.providers',
          );
          return const Stream.empty();
        }

        return ref
            .watch(FinanceDomainProviders.service)
            .watchInstallments(
              accountId: invoice.accountId,
              startDate: invoice.cycleStart,
              endDate: invoice.cycleEnd,
            );
      });

  static final invoicePieChart = StreamProvider.autoDispose
      .family<List<CategoryAmountModel>, InvoiceKey>((ref, invoice) {
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

            if (list.length > 10) {
              return Stream.value([
                ...list.sublist(0, 9),
                CategoryAmountModel(
                  category: CategoryModel(
                    id: "",
                    name: "Outros",
                    icon: "category",
                    color: "#333333",
                  ),
                  amount: list
                      .sublist(9)
                      .map((cat) => cat.amount)
                      .reduce((a1, a2) => a1 + a2),
                ),
              ]);
            }

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
  static final repository = Provider<IPeriodSummaryRepository>(
    (ref) => PeriodSummaryRepositoryImpl(),
  );

  static final service = Provider(
    (ref) => PeriodSummaryService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
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
  /// Chaveado por `YYYY-MM` (veja `DateTimeExtension.monthKey`): um
  /// `DateTime` como chave criaria uma família por instante distinto, já que
  /// o período nasce do relógio.
  static final monthSummary = StreamProvider.autoDispose
      .family<List<OverviewCategorySummary>, String>((ref, monthKey) {
        final service = ref.watch(PeriodSummaryDomainProviders.service);
        final List<CategoryModel> categories = ref
            .watch(CategoryViewProviders.allStream)
            .when(
              data: (data) => data,
              error: (_, _) => [],
              loading: () => [],
            );

        final (year, month) = DateTimeExtension.parseMonthKey(monthKey);

        return service
            .watchMonth(year, month)
            .map((summary) => _mapToOverview(summary, categories));
      });
}
