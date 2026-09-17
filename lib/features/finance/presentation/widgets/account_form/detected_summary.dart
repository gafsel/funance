import 'package:flutter/material.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/account_form/account_form_info_chip.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Resumo do que a leitura do documento encontrou, com o diálogo da lista.
///
/// Entre anexar o extrato e salvar a conta existe um passo de confiança: o
/// usuário precisa ver o que foi detectado antes de confirmar. Esse passo é
/// autocontido — não toca no estado do formulário, só mostra — então não tem
/// por que ocupar espaço no arquivo da tela.
Widget buildDetectedSummary(
  BuildContext context,
  AccountFormState state,
  AppLocalizations l10n,
) {
  final theme = Theme.of(context);
  final palette = context.palette;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.accountDetectedDataTitle, style: theme.textTheme.titleSmall),
      AppSpacing.gapSm,
      Row(
        children: [
          buildAccountFormInfoChip(
            Icons.receipt_long,
            l10n.accountDetectedTransactions(state.detectedOrders.length),
          ),
          if (state.detectedOrders.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: () => _showDetectedList(
                context,
                l10n.accountDetectedTransactionsTitle,
                state.detectedOrders.map((o) {
                  final descricao = displayOr(
                    o.description,
                    l10n.noDescription,
                  );
                  return '$descricao - ${o.amount.asCurrency(locale: context.locale)}';
                }).toList(),
              ),
              child: Text(l10n.accountViewTransactions),
            ),
          ],
        ],
      ),
      AppSpacing.gapSm,
      Text(
        l10n.accountDetectedConfirmation,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: palette.ink3,
        ),
      ),
    ],
  );
}

void _showDetectedList(BuildContext context, String title, List<String> items) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) => Padding(
            padding: AppSpacing.vXs,
            child: Text(
              items[index],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
