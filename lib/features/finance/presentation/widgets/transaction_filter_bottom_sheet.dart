import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_theme.dart';
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
        gradient: AppGradients.background,
        borderRadius: AppRadius.brSheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // O respiro que sobrou do puxador desenhado à mão: quem o desenha
          // agora é o `bottomSheetTheme`.
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: AppSpacing.allLg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.historyFilterTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.inkInverse,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.inkInverse,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.inkInverse.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            // O formulário inteiro mora sobre o gradiente escuro. Em vez de
            // repintar campo a campo (era o que a cópia manual do
            // `inputDecorationTheme` fazia), o bloco recebe o tema de jogo e
            // rótulo, dica, preenchimento e divisor passam a ler o brilho
            // certo sozinhos.
            child: Theme(
              data: AppTheme.onGame(context),
              child:
                  ResponsiveForm<
                    TransactionFilterState,
                    TransactionQuery,
                    TransactionFilterNotifier
                  >(
                    provider,
                    submitLabel: l10n.historyFilterApply,
                    submitButtonColor: AppColors.gold,
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
                            // O contorno claro é do bloco escuro, não do
                            // tema: o resto (raio, altura, tipografia) vem do
                            // `outlinedButtonTheme`.
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.inkInverse,
                              side: const BorderSide(
                                color: AppColors.inkInverse,
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
                              spacing: AppSpacing.md,
                              children: [
                                Expanded(
                                  child: MoneyFormField(
                                    initialValue: state.minAmount,
                                    onChanged: notifier.updateMinAmount,
                                    decoration: InputDecoration(
                                      labelText:
                                          l10n.historyFilterMinAmountLabel,
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
