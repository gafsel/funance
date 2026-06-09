import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final InstallmentModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accountId =
        invoice.accountIdSource ?? invoice.accounts.keys.firstOrNull ?? "";
    final accountAsync = ref.watch(AccountViewProviders.byId(accountId));
    final installmentsAsync = ref.watch(
      FinanceViewProviders.invoiceInstallments(invoice),
    );
    final pieChartAsync = ref.watch(
      FinanceViewProviders.invoicePieChart(invoice),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallWidth = constraints.maxWidth < 400;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isSmallWidth ? 430 : 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _buildHeader(
                    context,
                    ref,
                    invoice,
                    accountAsync,
                    pieChartAsync,
                  ),
                  titlePadding: EdgeInsets.zero,
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      final settings = context
                          .dependOnInheritedWidgetOfExactType<
                            FlexibleSpaceBarSettings
                          >();
                      if (settings == null) return const SizedBox.shrink();

                      final deltaExtent =
                          settings.maxExtent - settings.minExtent;
                      final t =
                          (1.0 -
                                  (settings.currentExtent -
                                          settings.minExtent) /
                                      deltaExtent)
                              .clamp(0.0, 1.0);

                      if (t > 0.7) {
                        return Container(
                          height: settings.minExtent,
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.invoiceDetailTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              if (invoice.status == InstallmentStatus.pending)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push(
                            '/transactions/form?forceEdit=true&status=paid',
                            extra: {'installment': invoice},
                          );
                        },
                        icon: const Icon(Icons.payment),
                        label: Text(l10n.registerInvoicePayment),
                      ),
                    ),
                  ),
                ),
              installmentsAsync.when(
                data: (installments) {
                  if (installments.isEmpty) {
                    return SliverFillRemaining(child: Center(child: Text(l10n.noTransactionsInPeriod)));
                  }

                  // Filtrar para remover o próprio invoice da lista (se ele aparecer na query)
                  final filtered = installments
                      .where((i) => i.id != invoice.id)
                      .toList();

                  return SliverList.list(
                    children: [
                      for (final item in filtered) ...[
                        InkWell(
                          onTap: () async {
                            await context.push(
                              '/transactions/form',
                              extra: {'installment': item},
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _buildInstallmentItem(context, item),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                      SizedBox(height: mq.padding.bottom + 16),
                    ],
                  );
                },
                loading: () => SliverFillRemaining(child: const Center(child: CircularProgressIndicator())),
                error: (error, stack) {
                  print(stack.toString());

                  return SliverFillRemaining(child: Center(child: Text(error.toString())));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    InstallmentModel invoice,
    AsyncValue<AccountModel?> accountAsync,
    AsyncValue<Map<CategoryModel, double>> pieChartAsync,
  ) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final accountName = accountAsync.when(
      data: (account) =>
          account?.name ?? invoice.accounts.keys.firstOrNull ?? "",
      loading: () => "...",
      error: (_, __) => invoice.accounts.keys.firstOrNull ?? "",
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final settings = context
            .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
        if (settings == null) return const SizedBox.shrink();

        final deltaExtent = settings.maxExtent - settings.minExtent;
        final t =
            (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent)
                .clamp(0.0, 1.0);

        final isSmallWidth = constraints.maxWidth < 400;

        return Container(
          padding: EdgeInsets.only(bottom: 10),
          color: theme.scaffoldBackgroundColor,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 48 + (16 * (1 - t)), 24, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 5,
                  offset: Offset(5, 5),
                ),
              ],
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32 * (1 - t)),
              ),
            ),
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.description,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoice.amount.asCurrency(locale: locale),
                              style:
                                  (isSmallWidth
                                          ? theme.textTheme.headlineSmall
                                          : theme.textTheme.headlineMedium)
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoChip(
                              context,
                              Icons.calendar_today,
                              invoice.dueDate.formated(
                                l10n.formatSimpleDate,
                                locale,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoChip(
                              context,
                              Icons.credit_card,
                              accountName,
                            ),
                          ],
                        ),
                      ),
                      if (!isSmallWidth) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPieChart(pieChartAsync, 100, 30, 20),
                        ),
                      ],
                    ],
                  ),
                  if (isSmallWidth) ...[
                    const SizedBox(height: 20),
                    Center(child: _buildPieChart(pieChartAsync, 100, 30, 20)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChart(
    AsyncValue<Map<CategoryModel, double>> pieChartAsync,
    double size,
    double radius,
    double centerSpaceRadius,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isSmallWidth = constraints.maxWidth < 400;

        return Column(
          crossAxisAlignment: isSmallWidth
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: size,
              width: size,
              child: pieChartAsync.when(
                data: (categoryTotals) {
                  if (categoryTotals.isEmpty) return const SizedBox.shrink();

                  final sections = categoryTotals.entries.map((entry) {
                    final color = entry.key.color.asColor();
                    return PieChartSectionData(
                      color: color,
                      value: entry.value,
                      title: '',
                      radius: radius,
                    );
                  }).toList();

                  return PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: centerSpaceRadius,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
            pieChartAsync.when(
              data: (categoryTotals) {
                if (categoryTotals.isEmpty) return const SizedBox.shrink();
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: isSmallWidth
                      ? WrapAlignment.center
                      : WrapAlignment.start,
                  children: categoryTotals.keys.map((cat) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: cat.color.asColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
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
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(
    BuildContext context,
    InstallmentModel installment,
  ) {
    final theme = Theme.of(context);
    final category = installment.category;
    final isExpense = installment.type == OrderType.expense;
    final l10n = context.l10n;
    final locale = context.locale;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (category?.color.asColor() ?? AppColors.deepTurquoise)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category?.icon.asIcon() ?? Icons.category,
            color: category?.color.asColor() ?? AppColors.deepTurquoise,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                installment.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                installment.referenceDate.formated(
                  l10n.formatSimpleDate,
                  locale,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        Text(
          (isExpense
                  ? -installment.referenceAmount
                  : installment.referenceAmount)
              .asCurrency(locale: context.locale),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isExpense ? AppColors.error : AppColors.limeGreen,
          ),
        ),
      ],
    );
  }
}
