// ─────────────────────────────────────────────────────────────────────────────
// Providers de LANÇAMENTO, fatura, conciliação e 50-30-20 para as telas.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/presentation/controllers/account_statement_notifier.dart';
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
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/observability/app_logger.dart';
import 'package:funances/features/finance/presentation/providers/finance_domain_providers.dart';
import 'package:funances/features/finance/presentation/providers/period_summary_providers.dart';

class FinanceViewProviders {
  /// Uma parcela pelo id — como as rotas de detalhe carregam o que abrem.
  ///
  /// `AsyncValue.data(null)` quer dizer "não existe": a tela mostra que o
  /// lançamento sumiu em vez de piscar e voltar para a home.
  static final installmentById = StreamProvider.autoDispose
      .family<InstallmentModel?, String>((ref, installmentId) {
        return ref
            .watch(FinanceDomainProviders.service)
            .watchInstallment(installmentId);
      });

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
            installmentType: args.installmentType,
            category: args.category,
            accountIdSource: args.accountIdSource,
            accountIdTarget: args.accountIdTarget,
            amount: args.amount,
            description: args.description,
            date: args.date,
            today: ref.watch(todayProvider),
          ),
          financeService: ref.watch(FinanceDomainProviders.service),
          analytics: ref.watch(analyticsServiceProvider),
          today: ref.watch(todayProvider),
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
          analytics: ref.watch(analyticsServiceProvider),
        );
      });

  /// Formulário de quitação de uma parcela.
  ///
  /// `args.paidOn` distingue quitar na data do vencimento (o fluxo comum, com
  /// `paidOn` nulo) de "registrei hoje e isto era o agendamento", que vem do
  /// casamento dentro do formulário de criação e paga com a data de hoje.
  static final transactionPaymentForm = StateNotifierProvider.autoDispose
      .family<
        TransactionFormNotifier,
        TransactionFormState,
        TransactionPaymentArgs
      >((ref, args) {
        return TransactionFormNotifier(
          TransactionFormState.updateInstallment(
            args.installment,
            status: InstallmentStatus.paid,
            paidOn: args.paidOn,
          ),
          financeService: ref.watch(FinanceDomainProviders.service),
          analytics: ref.watch(analyticsServiceProvider),
          today: ref.watch(todayProvider),
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
        // Sem ela — fatura anterior a F1.8, antes do backfill — a consulta usa
        // um intervalo VAZIO (fim antes do início) em vez de um intervalo
        // chutado: o notifier carrega na construção, e uma query sem filtro
        // traria os últimos lançamentos do workspace inteiro como se fossem
        // desta fatura. A tela não chega a montar esta lista (mostra o aviso de
        // fatura em fechamento); o intervalo vazio é a rede de segurança.
        final query = invoice.hasServerCycle
            ? TransactionQuery(
                accountId: invoice.accountId,
                startDate: invoice.cycleStart,
                endDate: invoice.cycleEnd,
              )
            : TransactionQuery(
                accountId: invoice.accountId,
                startDate: invoice.dueDate,
                endDate: invoice.dueDate.addCalendarDays(-1),
              );

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
        return TransactionWizardNotifier(
          TransactionWizardState(
            type: args.type,
            accountIdSource: args.accountIdSource,
          ),
        );
      });

  static final categoryPlanningForm = StateNotifierProvider.autoDispose
      .family<
        CategoryPlanningNotifier,
        CategoryPlanningState,
        CategoryPlanningArgs
      >((ref, args) {
        return CategoryPlanningNotifier(
          planningService: ref.watch(CategoryPlanningDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
          analytics: ref.watch(analyticsServiceProvider),
          type: args.type,
          date: ref.watch(todayProvider),
          highlightCategoryId: args.highlightCategoryId,
          suggestedAmount: args.suggestedAmount,
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
          AppLogger.debug(
            'Fatura ${invoice.invoiceId} sem janela de ciclo do servidor; '
            'aguardando a sincronização em vez de calcular no cliente.',
            name: 'providers',
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
            // Soma por categoria em CENTAVOS: um `+` de double por parcela
            // desviava o total da fatia do gráfico da soma das linhas.
            final map = data
                .where((installment) => installment.type == OrderType.expense)
                .fold<Map<CategoryModel, Money>>({}, (map, installment) {
                  final amount = installment.referenceAmount.asMoney;
                  map.update(
                    installment.category!,
                    (value) => value + amount,
                    ifAbsent: () => amount,
                  );
                  return map;
                });

            final list =
                map.entries
                    .toList()
                    .map(
                      (entry) => CategoryAmountModel(
                        category: entry.key,
                        amount: entry.value.toDouble(),
                      ),
                    )
                    .toList()
                  ..sort((e1, e2) => e1.amount < e2.amount ? 1 : -1);

            if (list.length > 10) {
              return Stream.value([
                ...list.sublist(0, 9),
                CategoryAmountModel(
                  // Categoria sintética: sem nome guardado, porque o nome é
                  // "Outros" no idioma de quem lê (ver `displayName`).
                  category: const CategoryModel(
                    id: CategoryModel.othersId,
                    name: '',
                    icon: 'category',
                    color: '#333333',
                  ),
                  amount: Money.sumOf(
                    list.sublist(9),
                    (cat) => cat.amount,
                  ).toDouble(),
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
      planningService: ref.watch(CategoryPlanningDomainProviders.service),
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
        final totalPlanned = Money.sumOf(
          state.items,
          (item) => item.effectiveAmount,
        ).toDouble();
        final totalActual = Money.sumOf(
          state.items,
          (item) => item.actualAmount,
        ).toDouble();
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

        final currentTotal = Money.sumOf(
          items,
          (item) => item.effectiveAmount,
        ).toDouble();
        final currentActual = Money.sumOf(
          items,
          (item) => item.actualAmount,
        ).toDouble();
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
