import 'package:flutter/material.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_match_status_ui.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/match_actions.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/match_item_desktop.dart';

/// Um casamento entre uma linha do extrato e uma parcela do sistema.
///
/// Em tela estreita é um cartão empilhado; em tela larga, a linha de duas
/// colunas de [MatchItemDesktopRow]. Os dois leem o mesmo
/// [ReconciliationMatchVisual] — antes o layout mobile calculava cor, rótulo e
/// ícone e os repassava ao desktop por cinco parâmetros posicionais.
class ReconciliationMatchItem extends StatelessWidget {
  const ReconciliationMatchItem({
    super.key,
    required this.match,
    required this.onChanged,
    required this.onLinkManual,
    required this.onUnlink,
    required this.account,
    this.isDesktop = false,
  });

  final ReconciliationMatch match;
  final ValueChanged<ReconciliationMatch> onChanged;
  final ValueChanged<InstallmentModel> onLinkManual;
  final VoidCallback onUnlink;
  final AccountModel account;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final docTx = match.documentTransaction;
    final sysInst = match.systemInstallment;
    final createdOrder = match.createdOrder;
    final category =
        match.customCategory ?? sysInst?.category ?? createdOrder?.category;
    final description =
        match.customDescription ??
        sysInst?.description ??
        createdOrder?.description;

    final isSystemOnly = match.isSystemOnly;
    final isLinked = docTx != null && sysInst != null;
    final visual = match.visualFor(l10n);

    if (isDesktop) {
      return MatchItemDesktopRow(
        match: match,
        account: account,
        visual: visual,
        onChanged: onChanged,
        onLinkManual: onLinkManual,
        onUnlink: onUnlink,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isSystemOnly ? Colors.purple.withValues(alpha: 0.05) : null,
      child: Column(
        children: [
          ListTile(
            leading: Icon(visual.icon, color: visual.color),
            title: Text(
              displayOr(
                docTx?.description ?? sysInst?.description,
                l10n.noDescription,
              ),
            ),
            subtitle: Text(
              (docTx?.date ?? sysInst?.referenceDate ?? DateTime.now())
                  .formated(l10n.formatSimpleDate, locale),
            ),
            trailing: Text(
              (docTx?.amount ?? sysInst?.referenceAmount ?? 0).asCurrency(
                locale: locale,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    (docTx?.type ?? sysInst?.type ?? OrderType.expense) ==
                        OrderType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
          if (isLinked ||
              createdOrder != null ||
              match.customDescription != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(sysInst?.referenceDate ?? createdOrder?.firstDueDate ?? docTx?.date ?? DateTime.now()).formated(l10n.formatSimpleDate)} • ${(sysInst?.referenceAmount ?? createdOrder?.amount ?? docTx?.amount.abs() ?? 0).asCurrency(locale: locale)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (category != null)
                            Text(
                              category.displayName(l10n),
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (match.status == ReconciliationMatchStatus.suggested)
                      TextButton(
                        onPressed: () => onChanged(
                          match.copyWith(
                            status: ReconciliationMatchStatus.matched,
                          ),
                        ),
                        child: Text(l10n.reconciliationActionConfirm),
                      ),
                  ],
                ),
              ),
            ),
          MatchActions(
            match: match,
            account: account,
            onChanged: onChanged,
            onLinkManual: onLinkManual,
            onUnlink: onUnlink,
          ),
        ],
      ),
    );
  }
}
