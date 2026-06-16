import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_filter_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/model/transaction_filter_view_models.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

enum TransactionFilterField {
  description,
  category,
  account,
  type,
  status,
  amountRange,
}

class TransactionFilterBottomSheet extends StatelessWidget {
  final TransactionQuery initialQuery;
  final ValueChanged<TransactionQuery> onApply;
  final Set<TransactionFilterField> hiddenFields;

  const TransactionFilterBottomSheet({
    super.key,
    required this.initialQuery,
    required this.onApply,
    this.hiddenFields = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = FinanceViewProviders.transactionFilter(initialQuery);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
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
                    backgroundColor: AppColors.pureWhite.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Theme(
              data: theme.copyWith(
                inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                  fillColor: Colors.black12,
                  prefixIconColor: Colors.white70,
                  suffixIconColor: Colors.white70,
                  prefixStyle: TextStyle(color: Colors.white70),
                  labelStyle: theme.inputDecorationTheme.labelStyle?.copyWith(
                    color: Colors.white70,
                  ),
                  floatingLabelStyle: theme
                      .inputDecorationTheme
                      .floatingLabelStyle
                      ?.copyWith(color: Colors.white),
                ),
                hintColor: Colors.white60,
              ),
              child:
                  ResponsiveForm<
                    TransactionFilterState,
                    TransactionQuery,
                    TransactionFilterNotifier
                  >(
                    provider,
                    submitLabel: l10n.historyFilterApply,
                    submitButtonColor: AppColors.successGold,
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
                            onPressed: () =>
                                ref.read(provider.notifier).clear(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.pureWhite,
                              side: const BorderSide(
                                color: AppColors.pureWhite,
                              ),
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

                      bool isHidden(TransactionFilterField field) =>
                          hiddenFields.contains(field);

                      return [
                        if (!isHidden(TransactionFilterField.description))
                          FullWidthItem(
                            TextFormField(
                              initialValue: state.description,
                              onChanged: notifier.updateDescription,
                              decoration: InputDecoration(
                                labelText: l10n.historyFilterDescriptionLabel,
                              ),
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        if (!isHidden(TransactionFilterField.account))
                          FullWidthItem(
                            AccountFormField(
                              initialValue: state.accountId,
                              onChanged: notifier.updateAccountId,
                              decoration: InputDecoration(
                                labelText: l10n.historyFilterAccountLabel,
                              ),
                              showAddOption: false,
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        if (!isHidden(TransactionFilterField.type))
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
                        if (!isHidden(TransactionFilterField.category)) ...[
                          if (state.type == OrderType.transfer) ...[
                            FullWidthItem(
                              CategoryFormField.transfer(
                                decoration: InputDecoration(
                                  labelText: l10n.historyFilterCategoryLabel,
                                ),
                                style: const TextStyle(
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          ] else ...[
                            FullWidthItem(
                              CategoryFormField(
                                emptyMeansAll: true,
                                showNewOption: false,
                                categoryType: state.type?.categoryType,
                                initialValue: state.category,
                                onChanged: notifier.updateCategory,
                                decoration: InputDecoration(
                                  labelText: l10n.historyFilterCategoryLabel,
                                ),
                                style: const TextStyle(
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (!isHidden(TransactionFilterField.status))
                          FullWidthItem(
                            ChipFormField<InstallmentStatus>(
                              initialValue: state.status,
                              onChanged: notifier.updateStatus,
                              decoration: InputDecoration(
                                labelText: l10n.historyFilterStatusLabel,
                              ),
                              options:
                                  [
                                    InstallmentStatus.pending,
                                    InstallmentStatus.paid,
                                    InstallmentStatus.settled,
                                  ].map((status) {
                                    return ChipFormFieldOption(
                                      value: status,
                                      label: l10n.fromInstallmentStatus(status),
                                    );
                                  }).toList(),
                            ),
                          ),
                        if (!isHidden(TransactionFilterField.amountRange)) ...[
                          FullWidthItem(
                            Row(
                              spacing: 16,
                              children: [
                                Expanded(
                                  child: MoneyFormField(
                                    initialValue: state.minAmount,
                                    onChanged: notifier.updateMinAmount,
                                    decoration: InputDecoration(
                                      labelText:
                                          l10n.historyFilterMinAmountLabel,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: MoneyFormField(
                                    initialValue: state.maxAmount,
                                    onChanged: notifier.updateMaxAmount,
                                    decoration: InputDecoration(
                                      labelText:
                                          l10n.historyFilterMaxAmountLabel,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ];
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
