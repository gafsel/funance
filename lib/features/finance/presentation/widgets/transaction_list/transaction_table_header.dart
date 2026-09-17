import 'package:flutter/material.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Faixa de títulos das colunas da tabela de transações (modo desktop).
///
/// As larguras aqui (90, 44, 120 e os `flex`) são as MESMAS de cada linha da
/// tabela: é o que faz cabeçalho e conteúdo ficarem alinhados. Mantê-los em
/// arquivos vizinhos, e não perdidos no meio da tela, é o que evita que um
/// ajuste de coluna seja feito só de um lado.
Widget buildTransactionTableHeader(
  BuildContext context,
  AppLocalizations l10n,
) {
  final theme = Theme.of(context);
  final textStyle = theme.textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.bold,
    color: theme.colorScheme.onSurfaceVariant,
  );

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(l10n.date, style: textStyle)),
        const SizedBox(width: 12),
        SizedBox(width: 44, child: Text('', style: textStyle)),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(l10n.historyFilterDescriptionLabel, style: textStyle),
        ),
        Expanded(
          flex: 1,
          child: Text(l10n.transactionInstallmentsLabel, style: textStyle),
        ),
        Expanded(
          flex: 2,
          child: Text(l10n.historyAccountLabel, style: textStyle),
        ),
        Expanded(
          flex: 1,
          child: Text(l10n.historyFilterStatusLabel, style: textStyle),
        ),
        SizedBox(
          width: 120,
          child: Text(
            l10n.transactionAmountLabel,
            style: textStyle,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}
