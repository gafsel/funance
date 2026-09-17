import 'package:flutter/material.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_colors.dart';
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.accountDetectedDataTitle,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkNavy,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          buildAccountFormInfoChip(
            Icons.receipt_long,
            l10n.accountDetectedTransactions(state.detectedOrders.length),
          ),
          if (state.detectedOrders.isNotEmpty) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _showDetectedList(
                context,
                l10n.accountDetectedTransactionsTitle,
                state.detectedOrders.map((o) {
                  final descricao = displayOr(o.description, l10n.noDescription);
                  return '$descricao - ${o.amount.asCurrency(locale: context.locale)}';
                }).toList(),
              ),
              child: Text(
                l10n.accountViewTransactions,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.deepTurquoise,
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      Text(
        l10n.accountDetectedConfirmation,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}

void _showDetectedList(
  BuildContext context,
  String title,
  List<String> items,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: TextStyle(color: AppColors.darkNavy)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              items[index],
              style: TextStyle(color: AppColors.darkNavy),
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
