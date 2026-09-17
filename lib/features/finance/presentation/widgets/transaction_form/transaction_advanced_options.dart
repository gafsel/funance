import 'package:flutter/material.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

/// "Mais opções": tipo do lançamento, parcelamento, número de parcelas e se o
/// valor digitado é o total ou o da parcela.
///
/// Está recolhido porque a maioria dos lançamentos é avulsa: quem precisa de
/// parcelamento sabe procurar, e quem não precisa não deveria ver quatro
/// campos a mais.
class TransactionAdvancedOptions extends StatelessWidget {
  const TransactionAdvancedOptions({
    super.key,
    required this.state,
    required this.notifier,
    required this.isSettled,
  });

  final TransactionFormState state;
  final TransactionFormNotifier notifier;
  final bool isSettled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final v = context.validations;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          l10n.transactionMoreOptions,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.all(8),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              if (state.creation)
                ChipFormField<OrderType>(
                  initialValue: state.type,
                  decoration: InputDecoration(
                    labelText: l10n.transactionOrderTypeLabel,
                  ),
                  options: [
                    ChipFormFieldOption(
                      value: OrderType.expense,
                      label: l10n.transactionTypeExpense,
                    ),
                    ChipFormFieldOption(
                      value: OrderType.income,
                      label: l10n.transactionTypeIncome,
                    ),
                    ChipFormFieldOption(
                      value: OrderType.transfer,
                      label: l10n.transactionTypeTransfer,
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      notifier.updateOrderType(v);
                    }
                  },
                  validator: v.all([v.notNull()]),
                ),
              if (state.type != OrderType.transfer) ...[
                ChipFormField<InstallmentType>(
                  initialValue: state.installmentType,
                  decoration: InputDecoration(
                    labelText: l10n.transactionTypeLabel,
                  ),
                  options: [
                    ChipFormFieldOption(
                      value: InstallmentType.single,
                      label: l10n.transactionTypeSimple,
                    ),
                    ChipFormFieldOption(
                      value: InstallmentType.installment,
                      label: l10n.transactionTypeInstallment,
                    ),
                    ChipFormFieldOption(
                      value: InstallmentType.recurring,
                      label: l10n.transactionTypeRecurrent,
                    ),
                  ],
                  onChanged: state.creation
                      ? (v) {
                          if (v != null) {
                            notifier.updateInstallmentType(v);
                          }
                        }
                      : null,
                ),
              ],
              if (state.installmentType == InstallmentType.installment)
                TextFormField(
                  initialValue: (state.installmentCount ?? 1).toString(),
                  onChanged: (installment) => notifier.updateInstallmentCount(
                    int.tryParse(installment) ?? 1,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.transactionInstallmentsLabel,
                  ),
                  validator: v.all([v.notEmpty()]),
                  enabled: state.creation,
                ),
              if (state.installmentType == InstallmentType.installment &&
                  state.creation &&
                  !isSettled)
                ChipFormField<TransactionAmountType>(
                  initialValue: state.amountType,
                  decoration: InputDecoration(
                    labelText: l10n.transactionAmountLabel,
                  ),
                  options: [
                    ChipFormFieldOption(
                      value: TransactionAmountType.total,
                      label: l10n.transactionAmountTotalLabel,
                    ),
                    ChipFormFieldOption(
                      value: TransactionAmountType.installment,
                      label: l10n.transactionAmountInstallmentLabel,
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      notifier.updateAmountType(v);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
