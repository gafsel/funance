import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_match_status_ui.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/reconciliation_transaction_form.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation_history_picker.dart';

/// As ações possíveis sobre um casamento.
///
/// A lista é a mesma nos dois layouts; só a direção muda — `OverflowBar` no
/// cartão mobile, `Column` na coluna de ações do desktop.
class MatchActions extends StatelessWidget {
  const MatchActions({
    super.key,
    required this.match,
    required this.account,
    required this.onChanged,
    required this.onLinkManual,
    required this.onUnlink,
    this.isVertical = false,
  });

  final ReconciliationMatch match;
  final AccountModel account;
  final ValueChanged<ReconciliationMatch> onChanged;
  final ValueChanged<InstallmentModel> onLinkManual;
  final VoidCallback onUnlink;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSystemOnly = match.isSystemOnly;

    final actions = [
      if (match.documentTransaction != null && match.systemInstallment != null)
        TextButton.icon(
          onPressed: onUnlink,
          icon: const Icon(Icons.link_off),
          label: Text(l10n.reconciliationActionUnlink),
        ),
      if (!isSystemOnly &&
          (match.status == ReconciliationMatchStatus.unmatched ||
              (match.status == ReconciliationMatchStatus.matched &&
                  match.systemInstallment == null)))
        TextButton.icon(
          onPressed: () async {
            final result = await showModalBottomSheet<ReconciliationMatch?>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  ReconciliationTransactionForm(match: match, account: account),
            );

            if (result != null) {
              onChanged(result);
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.reconciliationActionRegister),
        ),
      if (isSystemOnly)
        TextButton.icon(
          onPressed: () => onChanged(
            match.copyWith(status: ReconciliationMatchStatus.matched),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(l10n.reconciliationActionKeep),
          style: match.status == ReconciliationMatchStatus.matched
              ? TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                )
              : null,
        ),
      if (!isSystemOnly)
        TextButton.icon(
          onPressed: () {
            final dTx = match.documentTransaction;
            final sInst = match.systemInstallment;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ReconciliationHistoryPicker(
                initialQuery: TransactionQuery(
                  accountId: account.id,
                  startDate:
                      (dTx?.date ?? sInst?.referenceDate ?? DateTime.now())
                          .subtract(const Duration(days: 7)),
                  endDate: (dTx?.date ?? sInst?.referenceDate ?? DateTime.now())
                      .add(const Duration(days: 7)),
                ),
                onSelected: (inst) {
                  onLinkManual(inst);
                  Navigator.pop(context);
                },
              ),
            );
          },
          icon: const Icon(Icons.link),
          label: Text(l10n.reconciliationActionLink),
        ),
      if (match.status != ReconciliationMatchStatus.ignored)
        TextButton.icon(
          onPressed: () => onChanged(
            match.copyWith(status: ReconciliationMatchStatus.ignored),
          ),
          icon: Icon(isSystemOnly ? Icons.delete_outline : Icons.block),
          label: Text(
            isSystemOnly
                ? l10n.reconciliationActionRemove
                : l10n.reconciliationActionIgnore,
          ),
        )
      else
        TextButton.icon(
          onPressed: () => onChanged(
            match.copyWith(
              status: match.systemInstallment != null
                  ? ReconciliationMatchStatus.matched
                  : ReconciliationMatchStatus.unmatched,
            ),
          ),
          icon: const Icon(Icons.restore),
          label: Text(l10n.reconciliationActionRestore),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            backgroundColor: Colors.red.withValues(alpha: 0.1),
          ),
        ),
    ];

    if (isVertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: actions,
      );
    }

    return OverflowBar(alignment: MainAxisAlignment.end, children: actions);
  }
}
