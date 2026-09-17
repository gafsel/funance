import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_typography.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O valor do lançamento — editável ou só exibido.
///
/// O rótulo depende do tipo de parcelamento E de qual valor o usuário está
/// digitando (o total ou o da parcela): num lançamento recorrente "R$ 200" é
/// por mês, num parcelado pode ser o total ou cada parcela, e dizer só
/// "Valor" nos três casos é o tipo de ambiguidade que faz alguém parcelar
/// doze vezes o valor cheio sem perceber.
class TransactionAmountField extends StatelessWidget {
  const TransactionAmountField({
    super.key,
    required this.state,
    required this.notifier,
    required this.isEditable,
  });

  final TransactionFormState state;
  final TransactionFormNotifier notifier;
  final bool isEditable;

  /// Rótulo do campo de valor, para este estado do formulário.
  static String labelFor(AppLocalizations l10n, TransactionFormState state) {
    if (state.installmentType == InstallmentType.recurring) {
      return l10n.transactionAmountRecurringLabel;
    }

    if (state.installmentType == InstallmentType.installment) {
      if (!state.creation ||
          state.amountType == TransactionAmountType.installment) {
        return l10n.transactionAmountInstallmentLabel;
      }
      return l10n.transactionAmountTotalLabel;
    }

    return l10n.transactionAmountLabel;
  }

  /// A cor do valor é a do tipo do lançamento: vermelho sai, verde entra,
  /// primária só se move de lugar.
  static Color colorFor(BuildContext context, OrderType type) => switch (type) {
    OrderType.expense => context.palette.dangerText,
    OrderType.income => context.palette.successText,
    OrderType.transfer => Theme.of(context).colorScheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final v = context.validations;
    final amountLabel = labelFor(l10n, state);
    final amountColor = colorFor(context, state.type);
    final amountStyle = theme.textTheme.headlineSmall
        ?.copyWith(color: amountColor)
        .tabularFigures;

    if (isEditable) {
      return MoneyFormField(
        initialValue: state.amount,
        style: amountStyle,
        // Fill, borda e rótulo vêm do `inputDecorationTheme`; só o respiro
        // maior é daqui, porque o valor é o campo herói da tela.
        decoration: InputDecoration(
          labelText: amountLabel,
          alignLabelWithHint: true,
          contentPadding: AppSpacing.allMd,
        ),
        onChanged: (v) => notifier.updateAmount(v ?? 0.0),
        validator: v.all([v.notNull()]),
        enabled: true,
      );
    }

    return Center(
      child: Padding(
        padding: AppSpacing.vXs,
        child: Column(
          children: [
            Text(
              amountLabel,
              style: theme.textTheme.labelMedium?.copyWith(color: palette.ink3),
            ),
            AppSpacing.gapXxs,
            MoneyText(state.amount, style: amountStyle),
          ],
        ),
      ),
    );
  }
}
