import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';

class TransactionPaymentSheet extends ConsumerStatefulWidget {
  final InstallmentModel installment;

  const TransactionPaymentSheet({
    super.key,
    required this.installment,
  });

  static Future<bool?> show(
    BuildContext context,
    InstallmentModel installment,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TransactionPaymentSheet(installment: installment),
    );
  }

  @override
  ConsumerState<TransactionPaymentSheet> createState() =>
      _TransactionPaymentSheetState();
}

class _TransactionPaymentSheetState
    extends ConsumerState<TransactionPaymentSheet> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final formState = ref.watch(
      FinanceViewProviders.updateInstallmentForm(widget.installment),
    );

    final notifier = ref.read(
      FinanceViewProviders.updateInstallmentForm(widget.installment).notifier,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                const SizedBox(height: 24),
                AccountFormField(
                  initialValue: formState.accountIdSource,
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
                const SizedBox(height: 16),
                DateFormField(
                  initialValue: formState.dueDate,
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
                const SizedBox(height: 16),
                MoneyFormField(
                  initialValue: formState.amount,
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
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.reconciliationConfirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
