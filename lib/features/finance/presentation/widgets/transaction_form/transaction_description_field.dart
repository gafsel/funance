import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_amount_field.dart';

/// A descrição do lançamento — editável ou só exibida.
///
/// Num lançamento liquidado ela vira título centralizado: o usuário está
/// lendo um recibo, não preenchendo um campo.
class TransactionDescriptionField extends StatelessWidget {
  const TransactionDescriptionField({
    super.key,
    required this.state,
    required this.notifier,
    required this.isEditable,
  });

  final TransactionFormState state;
  final TransactionFormNotifier notifier;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final v = context.validations;

    if (isEditable) {
      return TextFormField(
        initialValue: state.description,
        decoration: InputDecoration(
          labelText: l10n.transactionDescriptionLabel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: notifier.updateDescription,
        validator: v.all([v.notEmpty(), v.length(max: 150, min: 3)]),
        enabled: true,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          state.description,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Tarja com o tipo do lançamento, só na edição.
///
/// Na criação o tipo é escolhível em "Mais opções"; numa edição ele já está
/// decidido e o que falta é dizer qual é.
class TransactionTypeChip extends StatelessWidget {
  const TransactionTypeChip({super.key, required this.state});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(
          switch (state.type) {
            OrderType.expense => l10n.transactionTypeExpense,
            OrderType.income => l10n.transactionTypeIncome,
            OrderType.transfer => l10n.transactionTypeTransfer,
          },
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: TransactionAmountField.colorFor(context, state.type),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
