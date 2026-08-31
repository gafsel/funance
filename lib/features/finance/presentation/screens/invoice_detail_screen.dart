import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
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

class InvoiceDetailScreen extends ConsumerWidget {
  final InstallmentModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A conta da fatura é o cartão (lado credit/target). Depois que a fatura é
    // paga, accountIdSource passa a ser a conta corrente que pagou — usá-la
    // aqui deixaria header e FAB apontando para a conta errada.
    final accountId =
        invoice.accountIdTarget ??
        invoice.accountIdSource ??
        invoice.accounts.keys.firstOrNull ??
        "";
    final accountAsync = ref.watch(AccountViewProviders.byId(accountId));

    final locale = context.locale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallWidth = constraints.maxWidth < 600;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverDetailHeader(
                  title: invoice.description,
                  subtitle: invoice.amount.asCurrency(locale: locale),
                  subtitleColor: Colors.white,
                  backgroundColor: accountAsync.when(
                    data: (account) =>
                        account?.color.asColor() ?? AppColors.deepTurquoise,
                    loading: () => AppColors.deepTurquoise,
                    error: (_, __) => AppColors.deepTurquoise,
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
                    error: (_, __) => null,
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
                          ? AppColors.deepPurple
                          : invoice.status == InstallmentStatus.paid
                          ? AppColors.limeGreen
                          : AppColors.antiqueGold,
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
                          context.push('/reconciliation', extra: account);
                        }
                      },
                      tooltip: l10n.reconciliationTitle,
                    ),
                    DetailHeaderAction(
                      icon: Icons.edit_outlined,
                      label: l10n.editButton,
                      onPressed: () {
                        context.push(
                          '/transactions/form',
                          extra: {'installment': invoice},
                        );
                      },
                      tooltip: l10n.editButton,
                    ),
                  ],
                  sideContent: _buildPieChart(
                    100,
                    30,
                    20,
                    AppColors
                        .pureWhite, // Passando a cor do conteúdo para a legenda
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                _buildFilterBar(context, ref, invoice),
                Expanded(
                  child: TransactionListView(
                    provider: FinanceViewProviders.invoiceInstallmentsList(
                      invoice,
                    ),
                    accountId: invoice.accountIdTarget,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push(
                '/transactions/form?type=expense&accountIdSource=$accountId',
              );
            },
            backgroundColor: AppColors.successGold,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: AppColors.darkNavy),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    InstallmentModel invoice,
  ) {
    final provider = FinanceViewProviders.invoiceInstallmentsList(invoice);
    final state = ref.watch(provider);
    final hasFilter =
        state.query.categoryId != null ||
        state.query.type != null ||
        state.query.description != null ||
        state.query.minAmount != null ||
        state.query.maxAmount != null ||
        state.query.status != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.transactions,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
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
              color: hasFilter ? AppColors.antiqueGold : null,
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
        final isSmallWidth = constraints.maxWidth < 600;

        return Consumer(
          builder: (context, ref, _) {
            final pieChartAsync = ref.watch(
              FinanceViewProviders.invoicePieChart(invoice),
            );

            return Column(
              crossAxisAlignment: isSmallWidth
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: ShapeDecoration(
                    shape: CircleBorder(),
                    color: Colors.white,
                  ),
                  height: size + 2,
                  width: size + 2,
                  child: pieChartAsync.when(
                    data: (categoryTotals) {
                      if (categoryTotals.isEmpty)
                        return const SizedBox.shrink();

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
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
                pieChartAsync.when(
                  data: (categoryTotals) {
                    if (categoryTotals.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
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
                            const SizedBox(width: 4),
                            Text(
                              cat.category.name,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: contentColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
