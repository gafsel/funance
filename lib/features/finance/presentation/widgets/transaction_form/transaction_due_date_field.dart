import 'package:flutter/material.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

/// Data de vencimento/transação — campo ou metadado.
class TransactionDueDateField extends StatelessWidget {
  const TransactionDueDateField({
    super.key,
    required this.state,
    required this.notifier,
  });

  final TransactionFormState state;
  final TransactionFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "${l10n.transactionDateLabel}: ",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state.dueDate.formated(l10n.formatSimpleDate),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A versão editável. Fica separada porque NÃO é `FullWidthItem`: em tela
/// larga ela divide a linha com outro campo, e a de leitura não.
DateFormField transactionDueDateInput(
  BuildContext context,
  TransactionFormState state,
  TransactionFormNotifier notifier,
) {
  final l10n = context.l10n;
  final v = context.validations;

  return DateFormField(
    initialValue: state.dueDate,
    onChanged: (date) {
      if (date != null) {
        notifier.updateDueDate(date);
      }
    },
    decoration: InputDecoration(
      labelText: l10n.transactionDateLabel,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: v.all([v.notNull()]),
  );
}
