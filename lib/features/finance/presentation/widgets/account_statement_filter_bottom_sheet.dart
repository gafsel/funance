import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/home/presentation/controller/history_filter_notifier.dart';
import 'package:funances/features/home/presentation/model/history_filter_view_models.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';

class AccountStatementFilterBottomSheet extends StatelessWidget {
  final TransactionQuery initialQuery;
  final ValueChanged<TransactionQuery> onApply;

  const AccountStatementFilterBottomSheet({
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
                  FullWidthItem(
                    TextFormField(
                      initialValue: state.description,
                      onChanged: notifier.updateDescription,
                      decoration: InputDecoration(
                        labelText: l10n.historyFilterDescriptionLabel,
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                      style: const TextStyle(color: AppColors.pureWhite),
                    ),
                  ),
                  FullWidthItem(
                    CategoryFormField(
                      initialValue: state.category,
                      onChanged: notifier.updateCategory,
                    ),
                  ),
                  FullWidthItem(
                    ChipFormField<OrderType>(
                      initialValue: state.type,
                      onChanged: notifier.updateType,
                      decoration: InputDecoration(
                        labelText: l10n.historyFilterTypeLabel,
                      ),
                      options: OrderType.values.map((type) {
                        return ChipFormFieldOption(
                          value: type,
                          label: l10n.fromOrderType(type),
                        );
                      }).toList(),
                    ),
                  ),
                  FullWidthItem(
                    ChipFormField<InstallmentStatus>(
                      initialValue: state.status,
                      onChanged: notifier.updateStatus,
                      decoration: InputDecoration(
                        labelText: l10n.historyFilterStatusLabel,
                      ),
                      options: InstallmentStatus.values.map((status) {
                        return ChipFormFieldOption(
                          value: status,
                          label: l10n.fromInstallmentStatus(status),
                        );
                      }).toList(),
                    ),
                  ),
                  FullWidthItem(
                    MoneyFormField(
                      initialValue: state.minAmount,
                      onChanged: notifier.updateMinAmount,
                      decoration: InputDecoration(
                        labelText: l10n.historyFilterMinAmountLabel,
                        prefixIcon: const Icon(Icons.remove_circle_outline),
                      ),
                    ),
                  ),
                  FullWidthItem(
                    MoneyFormField(
                      initialValue: state.maxAmount,
                      onChanged: notifier.updateMaxAmount,
                      decoration: InputDecoration(
                        labelText: l10n.historyFilterMaxAmountLabel,
                        prefixIcon: const Icon(Icons.add_circle_outline),
                      ),
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
