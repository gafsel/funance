import 'package:flutter/material.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_match_status_ui.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/match_actions.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/match_connector.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/reconciliation_transaction_form.dart';

/// Linha de conciliação em telas largas: extrato à esquerda, sistema à
/// direita, conector no meio e as ações na ponta.
class MatchItemDesktopRow extends StatelessWidget {
  const MatchItemDesktopRow({
    super.key,
    required this.match,
    required this.account,
    required this.visual,
    required this.onChanged,
    required this.onLinkManual,
    required this.onUnlink,
  });

  final ReconciliationMatch match;
  final AccountModel account;
  final MatchStatusVisual visual;
  final ValueChanged<ReconciliationMatch> onChanged;
  final ValueChanged<InstallmentModel> onLinkManual;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final sysInst = match.systemInstallment;
    final createdOrder = match.createdOrder;
    final category =
        match.customCategory ?? sysInst?.category ?? createdOrder?.category;
    final description =
        match.customDescription ??
        sysInst?.description ??
        createdOrder?.description;

    final dTx = match.documentTransaction;
    final sInst = match.systemInstallment;
    final isLinked = dTx != null && sInst != null;

    final hasSystemSide =
        sInst != null ||
        createdOrder != null ||
        match.customDescription != null;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Indicator
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  Icon(visual.icon, color: visual.color, size: 32),
                  AppSpacing.gapXxs,
                  Text(
                    visual.text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: visual.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Pool 1 — o que o extrato diz
            Expanded(
              child: MatchPoolColumn(
                label: l10n.reconciliationExtratoLabel,
                emptyMessage: l10n.reconciliationNotInDocument,
                children: dTx == null
                    ? null
                    : [
                        Text(
                          displayOr(dTx.description, l10n.noDescription),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(dTx.date.formated(l10n.formatSimpleDate)),
                        MoneyText(
                          dTx.amount,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: dTx.type == OrderType.income
                                ? palette.successText
                                : palette.dangerText,
                          ),
                        ),
                      ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            MatchConnectorWidget(status: match.status, isLinked: isLinked),
            const SizedBox(width: AppSpacing.md),
            // Pool 2 — o que o sistema tem
            Expanded(
              child: MatchPoolColumn(
                label: l10n.reconciliationSystemLabel,
                emptyMessage: l10n.reconciliationNoMatchFound,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.05),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                    color: visual.color.withValues(alpha: 0.2),
                  ),
                ),
                children: !hasSystemSide
                    ? null
                    : [
                        Text(
                          description ?? "",
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          (sInst?.referenceDate ??
                                  createdOrder?.firstDueDate ??
                                  dTx?.date ??
                                  DateTime.now())
                              .formated(l10n.formatSimpleDate),
                        ),
                        if (category != null)
                          Text(
                            category.displayName(l10n),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.ink2,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        MoneyText(
                          sInst?.referenceAmount ??
                              createdOrder?.amount ??
                              (dTx?.amount ?? 0).abs(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color:
                                (match.customType ??
                                        sInst?.type ??
                                        createdOrder?.type ??
                                        dTx?.type ??
                                        OrderType.expense) ==
                                    OrderType.income
                                ? palette.successText
                                : palette.dangerText,
                          ),
                        ),
                      ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Actions
            Column(
              children: [
                if (match.status == ReconciliationMatchStatus.suggested)
                  ElevatedButton(
                    onPressed: () => onChanged(
                      match.copyWith(status: ReconciliationMatchStatus.matched),
                    ),
                    child: Text(l10n.reconciliationActionConfirm),
                  ),
                if (match.status == ReconciliationMatchStatus.matched)
                  TextButton.icon(
                    onPressed: () async {
                      final result =
                          await showModalBottomSheet<ReconciliationMatch?>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: AppColors.transparent,
                            builder: (context) => ReconciliationTransactionForm(
                              match: match,
                              account: account,
                            ),
                          );

                      if (result != null) {
                        onChanged(result);
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(
                      l10n.reconciliationActionModify,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                AppSpacing.gapXs,
                MatchActions(
                  match: match,
                  account: account,
                  onChanged: onChanged,
                  onLinkManual: onLinkManual,
                  onUnlink: onUnlink,
                  isVertical: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma das duas colunas da linha desktop.
///
/// As duas eram escritas por extenso, com o mesmo rótulo cinza de 10px em
/// cima e a mesma frase em itálico quando não havia contrapartida — ~120
/// linhas duplicadas. `children: null` é o caso vazio; `decoration` só existe
/// no lado do sistema, que é emoldurado pela cor do status.
class MatchPoolColumn extends StatelessWidget {
  const MatchPoolColumn({
    super.key,
    required this.label,
    required this.emptyMessage,
    required this.children,
    this.decoration,
  });

  final String label;
  final String emptyMessage;

  /// `null` quando esta pool não tem contrapartida nenhuma.
  final List<Widget>? children;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: palette.ink3,
    );

    final children = this.children;

    if (children == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          AppSpacing.gapXs,
          Text(
            emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.ink3,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        AppSpacing.gapXxs,
        ...children,
      ],
    );

    if (decoration == null) return column;

    return Container(
      padding: AppSpacing.allSm,
      decoration: decoration,
      child: column,
    );
  }
}
