import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_filter_bottom_sheet.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/widgets/money_text.dart';

class ReconciliationHistoryPicker extends ConsumerWidget {
  final TransactionQuery initialQuery;
  final ValueChanged<InstallmentModel> onSelected;

  const ReconciliationHistoryPicker({
    super.key,
    required this.initialQuery,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = FinanceViewProviders.reconciliationPicker;
    final state = ref.watch(provider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: AppGradients.background,
        borderRadius: AppRadius.brSheet,
      ),
      child: Column(
        children: [
          AppSpacing.gapSm,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inkInverse.withValues(alpha: 0.3),
              borderRadius: AppRadius.brXs,
            ),
          ),
          AppSpacing.gapMd,
          Padding(
            padding: AppSpacing.hLg,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.reconciliationPickTransaction,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.inkInverse,
                    ),
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
                        onApply: (query) {
                          ref.read(provider.notifier).reset(query: query);
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.filter_list,
                    color: AppColors.inkInverse,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.inkInverse),
                ),
              ],
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: InfiniteListView.separator(
              provider,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              separatorBuilder: (context, before, after) {
                final bool isSameGroup =
                    before != null &&
                    after != null &&
                    _isSameDay(before.referenceDate, after.referenceDate);

                if (after != null && (before == null || !isSameGroup)) {
                  return _buildDateHeader(context, after.referenceDate, l10n);
                }

                return const SizedBox.shrink();
              },
              itemBuilder: (context, item) {
                return _buildTransactionItem(context, item);
              },
              emptyStateBuilder: (context) => EmptyState.message(
                l10n.noTransactionsInPeriod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.addCalendarDays(-1);
    final checkDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (checkDate == today) {
      dateText = l10n.today;
    } else if (checkDate == yesterday) {
      dateText = l10n.yesterday;
    } else {
      dateText = DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(date);
    }

    return Padding(
      padding: AppSpacing.vMd,
      child: Text(
        dateText,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: AppColors.inkInverse2),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, InstallmentModel item) {
    final theme = Theme.of(context);
    // A cor da categoria é DADO. Quando não há categoria, o teal é o acento
    // legível sobre esta folha escura — o turquesa profundo sumiria nela.
    final color = item.category?.color.asColor() ?? AppColors.teal;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      color: AppColors.inkInverse.withValues(alpha: 0.05),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: ListTile(
        onTap: () => onSelected(item),
        leading: Container(
          padding: AppSpacing.allXs,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item.category?.icon.asIcon() ?? Icons.help_outline,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          displayOr(item.description, context.l10n.noDescription),
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.inkInverse,
          ),
        ),
        subtitle: Text(
          item.category?.displayName(context.l10n) ?? context.l10n.noCategory,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.inkInverse2,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MoneyText(
              item.referenceAmount,
              style: theme.textTheme.titleSmall?.copyWith(
                color: item.type == OrderType.income
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
            if (item.status == InstallmentStatus.settled)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxs),
                // A pílula lê `context.palette`, que nesta folha escura é a do
                // tema de papel: a cor vai explícita para continuar legível.
                child: StatusPill(
                  label: 'CONCILIADO',
                  dense: true,
                  color: AppColors.teal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
