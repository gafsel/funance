import 'package:flutter/material.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';

class TransactionPaymentSheet extends StatelessWidget {
  final InstallmentModel installment;

  const TransactionPaymentSheet({super.key, required this.installment});

  static Future<InstallmentModel?> show(
    BuildContext context,
    InstallmentModel installment,
  ) {
    return showModalBottomSheet<InstallmentModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TransactionPaymentSheet(installment: installment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final provider = FinanceViewProviders.transactionPaymentForm(installment);

    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: mq.padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.reconciliationConfirm,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(),
            ResponsiveForm<
              TransactionFormState,
              dynamic,
              TransactionFormNotifier
            >(
              provider,
              onCancel: () => Navigator.pop(context),
              onSubmit: (snapshot, loading) async {
                if (!snapshot.validate()) return;

                final notifier = snapshot.notifier;

                final result = await loading(notifier.submit());
                if (result == null) return;

                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.transactionSaveSuccess)),
                );

                navigator.pop(result as InstallmentModel);
              },
              fieldsBuilder: (context, snapshot) {
                final state = snapshot.model;
                final notifier = snapshot.notifier;

                return [
                  AccountFormField(
                    initialValue: state.accountIdSource,
                    decoration: InputDecoration(
                      labelText: l10n.transactionAccountLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (accountId) {
                      notifier.updateAccountIdSource(accountId);
                    },
                  ),
                  DateFormField(
                    initialValue: state.paidDate,
                    decoration: InputDecoration(
                      labelText: l10n.transactionDateLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (date) {
                      if (date != null) notifier.updatePaidDate(date);
                    },
                  ),
                  MoneyFormField(
                    initialValue: state.paidAmount,
                    decoration: InputDecoration(
                      labelText: l10n.transactionAmountLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) notifier.updatePaidAmount(value);
                    },
                  ),
                ];
              },
            ),
            SizedBox(height: mq.padding.bottom),
          ],
        ),
      ),
    );
  }
}
