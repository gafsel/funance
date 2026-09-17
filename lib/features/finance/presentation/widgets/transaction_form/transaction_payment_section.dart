import 'package:flutter/material.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

/// Informações de pagamento: quando e quanto foi de fato pago.
///
/// Só aparece depois que o lançamento existe e já foi pago ou liquidado —
/// numa criação não há o que informar, e num agendamento futuro a pergunta
/// ainda não faz sentido.
List<Widget> transactionPaymentFields(
  BuildContext context,
  TransactionFormState state,
  TransactionFormNotifier notifier, {
  required bool isSettled,
}) {
  final theme = Theme.of(context);
  final l10n = context.l10n;
  final v = context.validations;

  return [
    FullWidthItem(const Divider()),
    FullWidthItem(
      Text(l10n.paymentInfo, style: theme.textTheme.titleMedium),
    ),
    DateFormField(
      initialValue: state.paidDate,
      onChanged: (date) {
        if (date != null) {
          notifier.updatePaidDate(date);
        }
      },
      decoration: InputDecoration(labelText: l10n.transactionDateLabel),
      validator: v.all([v.notNull()]),
      enabled: !isSettled,
    ),
    MoneyFormField(
      initialValue: state.paidAmount,
      decoration: InputDecoration(labelText: l10n.transactionAmountLabel),
      onChanged: (value) => notifier.updatePaidAmount(value ?? 0.0),
      validator: v.all([v.notNull()]),
      enabled: !isSettled,
    ),
  ];
}
