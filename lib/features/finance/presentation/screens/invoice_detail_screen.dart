import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/detail_header.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_filter_bottom_sheet.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_view.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_payment_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/presentation/retry.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final InstallmentModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A conta da fatura é o cartão (lado credit/target). Depois que a fatura é
    // paga, accountIdSource passa a ser a conta corrente que pagou — usá-la
    // aqui deixaria header e FAB apontando para a conta errada. A mesma
    // cadeia alimenta a chave das famílias da fatura (`invoiceKey`).
    final accountId = invoice.resolvedAccountId ?? "";
    final accountAsync = ref.watch(AccountViewProviders.byId(accountId));

    final locale = context.locale;

    return LayoutBuilder(
      builder: (context, constraints) {
        // O painel se mede pelas próprias constraints, não pela janela.
        final isSmallWidth = constraints.layout.isCompact;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverDetailHeader(
                  title: invoice.description,
                  subtitle: invoice.amount.asCurrency(locale: locale),
                  subtitleColor: AppColors.inkInverse,
                  backgroundColor: accountAsync.when(
                    data: (account) =>
                        account?.color.asColor() ?? AppColors.surfaceDeep,
                    loading: () => AppColors.surfaceDeep,
                    error: (_, _) => AppColors.surfaceDeep,
                  ),
                  logo: accountAsync.when(
                    data: (account) => account != null
                        ? AccountLogo(
                            account: account,
                            size: 40,
                            showMembers: true,
                          )
                        : null,
                    loading: () => null,
                    error: (_, _) => null,
                  ),
                  expandedHeight: isSmallWidth ? 480 : 320,
                  chips: [
                    DetailHeaderChip(
                      icon: invoice.status == InstallmentStatus.settled
                          ? Icons.done_all
                          : invoice.status == InstallmentStatus.paid
                          ? Icons.check_circle
                          : Icons.schedule,
                      label: invoice.status == InstallmentStatus.settled
                          ? l10n.statusSettled
                          : invoice.status == InstallmentStatus.paid
                          ? l10n.statusPaid
                          : l10n.statusPending,
                      backgroundColor:
                          invoice.status == InstallmentStatus.settled
                          ? AppColors.violet
                          : invoice.status == InstallmentStatus.paid
                          ? AppColors.success
                          : AppColors.goldDeep,
                    ),
                    DetailHeaderChip(
                      icon: Icons.calendar_today,
                      label: invoice.dueDate.formated(
                        l10n.formatSimpleDate,
                        locale,
                      ),
                    ),
                  ],
                  actions: [
                    if (invoice.status == InstallmentStatus.pending)
                      DetailHeaderAction(
                        icon: Icons.payment,
                        label: l10n.registerInvoicePayment,
                        onPressed: () async {
                          final result = await TransactionPaymentSheet.show(
                            context,
                            invoice,
                          );

                          if (result is InstallmentModel && context.mounted) {
                            context.pop(true);
                          }
                        },
                        tooltip: l10n.registerInvoicePayment,
                      ),
                    DetailHeaderAction(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.reconciliationTitle,
                      onPressed: () {
                        final account = accountAsync.valueOrNull;
                        if (account != null) {
                          context.push(
                            '/reconciliation?accountId=${account.id}',
                          );
                        }
                      },
                      tooltip: l10n.reconciliationTitle,
                    ),
                    DetailHeaderAction(
                      icon: Icons.edit_outlined,
                      label: l10n.editButton,
                      onPressed: () {
                        context.push(
                          '/transactions/form?installmentId=${invoice.id}',
                        );
                      },
                      tooltip: l10n.editButton,
                    ),
                  ],
                  // A cor do conteúdo da legenda: o cabeçalho é sempre
                  // escuro, então a tinta é a inversa nos dois temas.
                  sideContent: _buildPieChart(
                    100,
                    30,
                    20,
                    AppColors.inkInverse,
                  ),
                ),
              ];
            },
            // F1.8: a janela do ciclo é do servidor, gravada na própria
            // parcela da fatura. Sem ela (fatura anterior ao backfill) a lista
            // não tem período: mostrar o extrato de um intervalo chutado seria
            // pior do que dizer que a fatura ainda está fechando. Nem a barra
            // de filtro é montada — ela instancia o notifier, que consulta na
            // construção.
            body: invoice.invoiceKey.hasServerCycle
                ? Column(
                    children: [
                      _buildFilterBar(context, ref, invoice),
                      Expanded(
                        child: TransactionListView(
                          provider:
                              FinanceViewProviders.invoiceInstallmentsList(
                                invoice.invoiceKey,
                              ),
                          accountId: invoice.resolvedAccountId,
                        ),
                      ),
                    ],
                  )
                : _buildCycleUnavailable(context),
          ),
          // Cor, forma e tinta do ícone vêm do
          // `floatingActionButtonTheme`.
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push(
                '/transactions/form?type=expense&accountIdSource=$accountId',
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildCycleUnavailable(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, color: palette.ink3),
            AppSpacing.gapSm,
            Text(
              context.l10n.invoiceCycleUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    InstallmentModel invoice,
  ) {
    final provider = FinanceViewProviders.invoiceInstallmentsList(
      invoice.invoiceKey,
    );
    final state = ref.watch(provider);
    final hasFilter =
        state.query.categoryId != null ||
        state.query.type != null ||
        state.query.description != null ||
        state.query.minAmount != null ||
        state.query.maxAmount != null ||
        state.query.status != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.transactions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.transparent,
                builder: (context) => TransactionFilterBottomSheet(
                  initialQuery: state.query,
                  hiddenFields: const {
                    TransactionFilterField.account,
                    TransactionFilterField.amountRange,
                  },
                  onApply: (query) {
                    ref.read(provider.notifier).reset(query: query);
                  },
                ),
              );
            },
            icon: Icon(
              hasFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hasFilter ? AppColors.goldDeep : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
    double size,
    double radius,
    double centerSpaceRadius,
    Color contentColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isSmallWidth = constraints.layout.isCompact;

        return Consumer(
          builder: (context, ref, _) {
            final pieChartAsync = ref.watch(
              FinanceViewProviders.invoicePieChart(invoice.invoiceKey),
            );

            return Column(
              crossAxisAlignment: isSmallWidth
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.center,
              children: [
                Container(
                  // O disco fica sobre o cabeçalho, que é escuro nos dois
                  // temas: o papel aqui é constante, não o do tema.
                  padding: const EdgeInsets.all(2),
                  decoration: const ShapeDecoration(
                    shape: CircleBorder(),
                    color: AppColors.paperLight,
                  ),
                  height: size + 2,
                  width: size + 2,
                  child: pieChartAsync.when(
                    data: (categoryTotals) {
                      if (categoryTotals.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final sections = categoryTotals.map((entry) {
                        return PieChartSectionData(
                          color: entry.category.color.asColor(),
                          value: entry.amount,
                          title: '',
                          radius: radius,
                        );
                      }).toList();

                      return PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                          centerSpaceRadius: centerSpaceRadius,
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    // O gráfico É o conteúdo deste bloco: sumir em silêncio
                    // fazia a fatura parecer sem categorias.
                    error: (err, _) => ErrorView.forError(
                      context,
                      err,
                      onRetry: () =>
                          Retry.invoiceChart(ref, invoice.invoiceKey),
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                pieChartAsync.when(
                  data: (categoryTotals) {
                    if (categoryTotals.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      alignment: isSmallWidth
                          ? WrapAlignment.center
                          : WrapAlignment.start,
                      children: categoryTotals.map((cat) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cat.category.color.asColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              cat.category.displayName(context.l10n),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: contentColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
