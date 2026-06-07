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
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final InstallmentModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accountId =
        invoice.accountIdSource ?? invoice.accounts.keys.firstOrNull ?? "";
    final accountAsync = ref.watch(AccountViewProviders.byId(accountId));
    final installmentsAsync = ref.watch(
      FinanceViewProviders.invoiceInstallments(invoice),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoiceDetailTitle)),
      body: Column(
        children: [
          _buildHeader(context, ref, invoice, accountAsync),
          if (invoice.status == InstallmentStatus.pending)
            Padding(
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
          Expanded(
            child: installmentsAsync.when(
              data: (installments) {
                if (installments.isEmpty) {
                  return Center(child: Text(l10n.noTransactionsInPeriod));
                }

                // Filtrar para remover o próprio invoice da lista (se ele aparecer na query)
                final filtered = installments
                    .where((i) => i.id != invoice.id)
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(0),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return InkWell(
                      onTap: () async {
                        await context.push(
                          '/transactions/form',
                          extra: {'installment': item},
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12,
                        ),
                        child: _buildInstallmentItem(context, item),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                print(stack.toString());

                return Center(child: Text(error.toString()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    InstallmentModel invoice,
    AsyncValue<AccountModel?> accountAsync,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Text(invoice.description, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            invoice.amount.asCurrency(locale: locale),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                context,
                Icons.calendar_today,
                invoice.dueDate.formated(l10n.formatSimpleDate, locale),
              ),
              const SizedBox(width: 12),
              _buildInfoChip(context, Icons.credit_card, accountName),
            ],
          ),
        ],
      ),
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
