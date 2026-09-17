import 'package:flutter/material.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Como um casamento de conciliação se apresenta: cor, rótulo e ícone.
///
/// Este `switch` vivia dentro do layout mobile de `_MatchItem` e era passado
/// ao layout desktop por **cinco parâmetros posicionais**
/// (`context, locale, statusColor, statusText, statusIcon`) — ou seja, o
/// desktop dependia de o mobile ter sido calculado primeiro. Agora os dois
/// perguntam ao mesmo lugar.
typedef MatchStatusVisual = ({Color color, String text, IconData icon});

extension ReconciliationMatchVisual on ReconciliationMatch {
  /// Parcela que o sistema tem e o extrato não: o usuário decide se mantém
  /// (foi paga fora do extrato) ou remove (nunca aconteceu).
  bool get isSystemOnly =>
      documentTransaction == null && systemInstallment != null;

  MatchStatusVisual visualFor(AppLocalizations l10n) {
    if (isSystemOnly) {
      return switch (status) {
        ReconciliationMatchStatus.ignored => (
          color: Colors.red,
          text: l10n.reconciliationStatusRemove,
          icon: Icons.delete_sweep,
        ),
        ReconciliationMatchStatus.matched => (
          color: Colors.green,
          text: l10n.reconciliationStatusKeep,
          icon: Icons.check_circle,
        ),
        _ => (
          color: Colors.purple,
          text: l10n.reconciliationStatusSystemOnly,
          icon: Icons.info_outline,
        ),
      };
    }

    return switch (status) {
      ReconciliationMatchStatus.matched => (
        color: Colors.green,
        text: l10n.reconciliationStatusMatched,
        icon: Icons.check_circle,
      ),
      ReconciliationMatchStatus.suggested => (
        color: Colors.orange,
        text: l10n.reconciliationStatusSuggested,
        icon: Icons.help,
      ),
      ReconciliationMatchStatus.unmatched => (
        color: Colors.blue,
        text: l10n.reconciliationStatusUnmatched,
        icon: Icons.add_circle,
      ),
      ReconciliationMatchStatus.ignored => (
        color: Colors.grey,
        text: l10n.reconciliationStatusIgnored,
        icon: Icons.block,
      ),
    };
  }
}
