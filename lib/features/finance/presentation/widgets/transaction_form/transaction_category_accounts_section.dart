import 'package:flutter/material.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';

/// Categoria e contas, no modo editável.
///
/// Devolve uma LISTA e não um widget de propósito: o `ResponsiveForm` decide
/// a largura item a item (`FullWidthItem` ocupa a linha inteira, o resto
/// divide em colunas). Agrupar estes campos num widget só os faria virar uma
/// coluna única em tela larga.
List<Widget> transactionCategoryAndAccountFields(
  BuildContext context,
  TransactionFormState state,
  TransactionFormNotifier notifier,
) {
  final theme = Theme.of(context);
  final l10n = context.l10n;
  final v = context.validations;

  return [
    if (state.isInvoice)
      CategoryFormField.invoice(
        decoration: InputDecoration(
          labelText: l10n.transactionCategoriesSection,
        ),
      )
    else if (state.type == OrderType.transfer) ...[
      CategoryFormField.transfer(
        decoration: InputDecoration(
          labelText: l10n.transactionCategoriesSection,
        ),
      ),
      // A transferência não escolhe categoria: o servidor deriva uma
      // categoria virtual dos tipos das contas. O chip conta isso em vez de
      // trocar a categoria por baixo dos panos.
      if (state.transferAccounting != null)
        FullWidthItem(
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                state.transferAccounting == TransferAccounting.debt
                    ? Icons.trending_down
                    : Icons.savings_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                state.transferAccounting == TransferAccounting.debt
                    ? l10n.transactionTransferCountsAsDebt
                    : l10n.transactionTransferCountsAsInvestment,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
    ] else
      CategoryFormField(
        initialValue: state.category,
        categoryType: state.type.categoryType,
        decoration: InputDecoration(
          labelText: l10n.transactionCategoriesSection,
        ),
        onChanged: notifier.updateCategory,
        validator: v.all([v.notNull()]),
        autoOpen: state.creation && state.type != OrderType.transfer,
      ),

    AccountFormField(
      // O FormField semeia o valor no primeiro build; a conta padrão chega
      // depois, de uma consulta. A key faz o campo renascer com o default já
      // preenchido.
      key: ValueKey('account-source-${state.accountIdSource}'),
      initialValue: state.accountIdSource,
      decoration: InputDecoration(
        labelText: state.type == OrderType.transfer
            ? l10n.transactionFromAccountLabel
            : l10n.transactionAccountLabel,
      ),
      onChanged: notifier.updateAccountIdSource,
      // Conta é obrigatória também em agendamento: um lançamento futuro sem
      // conta não entra em projeção de saldo nenhuma.
      validator: v.all([v.notEmpty()]),
      autoOpen:
          state.creation &&
          !state.resolvingAccount &&
          state.accountIdSource == null,
    ),
    if (state.type == OrderType.transfer)
      AccountFormField(
        initialValue: state.accountIdTarget,
        decoration: InputDecoration(labelText: l10n.transactionToAccountLabel),
        onChanged: notifier.updateAccountIdTarget,
        validator: v.all([v.notEmpty()]),
        autoOpen:
            state.creation &&
            state.accountIdSource != null &&
            state.type == OrderType.transfer,
      ),
  ];
}
