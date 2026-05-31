import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/home/presentation/controller/history_filter_notifier.dart';
import 'package:funances/features/home/presentation/model/history_filter_view_models.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';

class HistoryFilterBottomSheet extends StatelessWidget {
  final TransactionQuery initialQuery;
  final ValueChanged<TransactionQuery> onApply;

  const HistoryFilterBottomSheet({
    super.key,
    required this.initialQuery,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = HomeViewProviders.historyFilter(initialQuery);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: double.infinity,
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
          const SizedBox(height: 24),
          Expanded(
            child: ResponsiveForm<HistoryFilterState, TransactionQuery,
                HistoryFilterNotifier>(
              provider,
              submitLabel: l10n.historyFilterApply,
              onSuccess: (query) {
                if (query != null) {
                  onApply(query);
                  Navigator.pop(context);
                }
              },
              extraActions: [
                Consumer(
                  builder: (context, ref, child) {
                    return OutlinedButton(
                      onPressed:
                          () => ref.read(provider.notifier).clear(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.pureWhite,
                        side: const BorderSide(color: AppColors.pureWhite),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                      ),
                      child: Text(l10n.historyFilterClear),
                    );
                  },
                ),
              ],
              fieldsBuilder: (context, snapshot) {
                final state = snapshot.model;
                final notifier = snapshot.notifier;

                return [
                  FullWidthItem(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.historyFilterTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.pureWhite,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.pureWhite.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descrição
                  TextFormField(
                    initialValue: state.description,
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterDescriptionLabel,
                      labelStyle: const TextStyle(color: AppColors.pureWhite),
                      prefixIcon: const Icon(
                        Icons.description,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    style: const TextStyle(color: AppColors.pureWhite),
                    onChanged: notifier.updateDescription,
                  ),

                  // Tipo de Transação
                  ChipFormField<OrderType>(
                    initialValue: state.type,
                    options: [
                      ChipFormFieldOption(
                        value: OrderType.income,
                        label: l10n.transactionTypeIncome,
                      ),
                      ChipFormFieldOption(
                        value: OrderType.expense,
                        label: l10n.transactionTypeExpense,
                      ),
                      ChipFormFieldOption(
                        value: OrderType.transfer,
                        label: l10n.transactionTypeTransfer,
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterTypeLabel,
                      labelStyle: const TextStyle(color: AppColors.pureWhite),
                    ),
                    onChanged: notifier.updateType,
                  ),

                  // Categoria
                  CategoryFormField(
                    initialValue: state.category,
                    categoryType: state.type?.categoryType,
                    emptyMeansAll: true,
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterCategoryLabel,
                      labelStyle: const TextStyle(color: AppColors.pureWhite),
                    ),
                    onChanged: notifier.updateCategory,
                  ),

                  // Status
                  ChipFormField<InstallmentStatus>(
                    initialValue: state.status,
                    options: [
                      ChipFormFieldOption(
                        value: InstallmentStatus.pending,
                        label: l10n.statusPending,
                      ),
                      ChipFormFieldOption(
                        value: InstallmentStatus.paid,
                        label: l10n.statusPaid,
                      ),
                      ChipFormFieldOption(
                        value: InstallmentStatus.settled,
                        label: l10n.statusSettled,
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterStatusLabel,
                      labelStyle: const TextStyle(color: AppColors.pureWhite),
                    ),
                    onChanged: notifier.updateStatus,
                  ),

                  // Faixa de Valor - Min
                  TextFormField(
                    initialValue: state.minAmount?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterMinAmountLabel,
                      labelStyle: const TextStyle(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    style: const TextStyle(color: AppColors.pureWhite),
                    keyboardType: TextInputType.number,
                    onChanged:
                        (val) =>
                            notifier.updateMinAmount(
                              double.tryParse(val),
                            ),
                  ),

                  // Faixa de Valor - Max
                  TextFormField(
                    initialValue: state.maxAmount?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: l10n.historyFilterMaxAmountLabel,
                      labelStyle: const TextStyle(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    style: const TextStyle(color: AppColors.pureWhite),
                    keyboardType: TextInputType.number,
                    onChanged:
                        (val) =>
                            notifier.updateMaxAmount(
                              double.tryParse(val),
                            ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }
}
