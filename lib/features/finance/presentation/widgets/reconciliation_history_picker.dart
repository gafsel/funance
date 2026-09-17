import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_filter_bottom_sheet.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
        gradient: AppGradients.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.pureWhite.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.reconciliationPickTransaction,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.pureWhite,
                    ),
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
                        onApply: (query) {
                          ref.read(provider.notifier).reset(query: query);
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.filter_list, color: AppColors.pureWhite),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.pureWhite),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: InfiniteListView.separator(
              provider,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              separatorBuilder: (context, before, after) {
                final bool isSameGroup = before != null &&
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
              emptyStateBuilder: (context) => Center(
                child: Text(
                  l10n.noTransactionsInPeriod,
                  style: const TextStyle(color: AppColors.pureWhite),
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        dateText,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.pureWhite.withValues(alpha: 0.7),
            ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, InstallmentModel item) {
    final color = item.category?.color.asColor() ?? AppColors.deepTurquoise;
    final locale = context.locale;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.pureWhite.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => onSelected(item),
        leading: Container(
          padding: const EdgeInsets.all(8),
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
          item.description,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.category?.name ?? 'Sem categoria',
          style: TextStyle(
            color: AppColors.pureWhite.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.referenceAmount.asCurrency(locale: locale),
              style: TextStyle(
                color: item.type == OrderType.income
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.status == InstallmentStatus.settled)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.deepTurquoise.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CONCILIADO',
                  style: TextStyle(
                    color: AppColors.deepTurquoise,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
