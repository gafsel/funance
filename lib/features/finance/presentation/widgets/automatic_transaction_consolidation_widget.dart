import 'package:funances/core/platform/app_platform.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AutomaticTransactionConsolidationWidget extends ConsumerWidget {
  const AutomaticTransactionConsolidationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      AutomaticTransactionViewProviders.automaticTransactions,
    );
    final notifier = ref.read(
      AutomaticTransactionViewProviders.automaticTransactions.notifier,
    );
    final notificationService = ref.watch(
      AutomaticTransactionDomainProviders.notificationService,
    );
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;

    if (state.pendingTransactions.isEmpty) {
      if (!AppPlatform.isAndroid) return const SizedBox.shrink();

      return FutureBuilder<bool>(
        future: notificationService.isPermissionGranted(),
        builder: (context, snapshot) {
          if (snapshot.data == false) {
            return _PermissionRequestCard(
              onGrant: () => notificationService.openPermissionSettings(),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    return Card(
      margin: AppSpacing.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.allMd,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: palette.tealText),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.automaticTransactionTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        l10n.automaticTransactionSubtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Botão de desenvolvimento: simular uma notificação de banco
                // não é coisa que um usuário faça, e num card de dinheiro ele
                // era um convite a criar lançamento falso. Fica só em debug.
                if (kDebugMode)
                  IconButton(
                    icon: const Icon(Icons.bug_report, size: 16),
                    onPressed: () => notifier.simulateNotification(),
                    tooltip: l10n.automaticTransactionSimulate,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.pendingTransactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = state.pendingTransactions[index];
              return _TransactionItem(
                transaction: transaction,
                onConsolidate: () =>
                    _handleConsolidate(context, ref, transaction),
                onIgnore: () => notifier.ignore(transaction),
                onMove: (workspaceId) =>
                    notifier.moveToWorkspace(transaction, workspaceId),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleConsolidate(
    BuildContext context,
    WidgetRef ref,
    AutomaticTransactionModel transaction,
  ) {
    // A transação bancária já aconteceu: consolidar é registrar um realizado,
    // com a data da notificação como data de pagamento. Sem o status
    // explícito o formulário abria como agendamento, e o extrato ganhava uma
    // conta a pagar no lugar de um gasto.
    final queryParams = {
      'type': transaction.type.name,
      'status': InstallmentStatus.paid.name,
      'description': transaction.description,
      'amount': transaction.amount.toString(),
      'date': transaction.date.toIso8601String(),
    };

    if (transaction.suggestedCategory != null) {
      queryParams['categoryId'] = transaction.suggestedCategory!.id;
    }

    final accountId = transaction.accountId ?? transaction.suggestedAccount?.id;
    if (accountId != null) {
      queryParams['accountIdSource'] = accountId;
    }

    context
        .push(
          Uri(
            path: '/transactions/form',
            queryParameters: queryParams,
          ).toString(),
        )
        .then((result) {
          if (result == true) {
            ref
                .read(
                  AutomaticTransactionViewProviders
                      .automaticTransactions
                      .notifier,
                )
                .loadTransactions();
          }
        });
  }
}

class _PermissionRequestCard extends StatelessWidget {
  final VoidCallback onGrant;

  const _PermissionRequestCard({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;

    return Card(
      margin: AppSpacing.allMd,
      color: palette.tealText.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: palette.tealText),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: palette.tealText),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.automaticTransactionRequestPermission,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.tealText,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapXs,
            Text(
              l10n.automaticTransactionPermissionRequired,
              style: theme.textTheme.bodySmall,
            ),
            AppSpacing.gapSm,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGrant,
                child: Text(l10n.automaticTransactionGrantPermission),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends ConsumerWidget {
  final AutomaticTransactionModel transaction;
  final VoidCallback onConsolidate;
  final VoidCallback onIgnore;
  final Function(String) onMove;

  const _TransactionItem({
    required this.transaction,
    required this.onConsolidate,
    required this.onIgnore,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final currentWorkspace = workspaceState.currentWorkspace;
    final otherWorkspaces = workspaceState.availableWorkspaces
        .where((w) => w.id != currentWorkspace?.id)
        .toList();

    // A cor vem do TIPO do lançamento, não do sinal do valor: o modelo
    // guarda o montante sempre positivo.
    final accent = transaction.type == OrderType.expense
        ? palette.dangerText
        : palette.successText;

    return Padding(
      padding: AppSpacing.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          transaction.type == OrderType.expense
                              ? Icons.arrow_circle_down
                              : Icons.arrow_circle_up,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            transaction.description,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      transaction.date.formated(
                        "dd/MM/yyyy HH:mm",
                        context.locale,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              MoneyText(
                transaction.amount,
                style: theme.textTheme.titleSmall?.copyWith(color: accent),
              ),
            ],
          ),
          if (transaction.suggestedCategory != null ||
              transaction.suggestedAccount != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  if (transaction.suggestedCategory != null)
                    StatusPill(
                      label: transaction.suggestedCategory!.name,
                      icon: Icons.category,
                      dense: true,
                    ),
                  if (transaction.suggestedAccount != null)
                    StatusPill(
                      label: transaction.suggestedAccount!.name,
                      icon: Icons.account_balance_wallet,
                      dense: true,
                    ),
                ],
              ),
            ),
          AppSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (otherWorkspaces.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  tooltip: l10n.automaticTransactionMoveWorkspace,
                  onSelected: onMove,
                  itemBuilder: (context) => otherWorkspaces
                      .map(
                        (w) => PopupMenuItem(value: w.id, child: Text(w.name)),
                      )
                      .toList(),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  TextButton(
                    onPressed: onIgnore,
                    child: Text(l10n.automaticTransactionIgnore),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: onConsolidate,
                    child: Text(l10n.automaticTransactionConsolidate),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
