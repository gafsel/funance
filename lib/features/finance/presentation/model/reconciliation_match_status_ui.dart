import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Como um casamento de conciliação se apresenta: cor, rótulo e ícone.
///
/// Este `switch` vivia dentro do layout mobile de `_MatchItem` e era passado
/// ao layout desktop por **cinco parâmetros posicionais**
/// (`context, locale, statusColor, statusText, statusIcon`) — ou seja, o
/// desktop dependia de o mobile ter sido calculado primeiro. Agora os dois
/// perguntam ao mesmo lugar.
///
/// As cores vêm de [AppColors] e não de `context.palette` porque a assinatura
/// não recebe `BuildContext` — e os papéis usados aqui (semânticas, violeta e
/// a tinta terciária) têm o mesmo valor nos dois temas.
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
          color: AppColors.danger,
          text: l10n.reconciliationStatusRemove,
          icon: Icons.delete_sweep,
        ),
        ReconciliationMatchStatus.matched => (
          color: AppColors.success,
          text: l10n.reconciliationStatusKeep,
          icon: Icons.check_circle,
        ),
        _ => (
          color: AppColors.violet,
          text: l10n.reconciliationStatusSystemOnly,
          icon: Icons.info_outline,
        ),
      };
    }

    return switch (status) {
      ReconciliationMatchStatus.matched => (
        color: AppColors.success,
        text: l10n.reconciliationStatusMatched,
        icon: Icons.check_circle,
      ),
      ReconciliationMatchStatus.suggested => (
        color: AppColors.warning,
        text: l10n.reconciliationStatusSuggested,
        icon: Icons.help,
      ),
      ReconciliationMatchStatus.unmatched => (
        color: AppColors.tealInk,
        text: l10n.reconciliationStatusUnmatched,
        icon: Icons.add_circle,
      ),
      ReconciliationMatchStatus.ignored => (
        // Tinta terciária: o mesmo valor nos dois temas.
        color: AppColors.ink3Light,
        text: l10n.reconciliationStatusIgnored,
        icon: Icons.block,
      ),
    };
  }
}
