import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

class AutomaticTransactionConsolidationWidget extends ConsumerWidget {
  const AutomaticTransactionConsolidationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(AutomaticTransactionViewProviders.automaticTransactions);
    final notifier = ref.read(AutomaticTransactionViewProviders.automaticTransactions.notifier);
    final notificationService = ref.watch(AutomaticTransactionDomainProviders.notificationService);
    final l10n = AppLocalizations.of(context)!;

    if (state.pendingTransactions.isEmpty) {
      if (!Platform.isAndroid) return const SizedBox.shrink();
      
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
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.deepTurquoise),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.automaticTransactionTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.automaticTransactionSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
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
                onConsolidate: () => _handleConsolidate(context, ref, transaction),
                onIgnore: () => notifier.ignore(transaction),
                onMove: (workspaceId) => notifier.moveToWorkspace(transaction, workspaceId),
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
    final queryParams = {
      'type': transaction.type.name,
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

    context.push(
      Uri(path: '/transactions/form', queryParameters: queryParams).toString(),
      extra: {'category': transaction.suggestedCategory},
    ).then((result) {
      if (result == true) {
        ref.read(AutomaticTransactionViewProviders.automaticTransactions.notifier)
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

    return Card(
      margin: const EdgeInsets.all(16),
      color: AppColors.deepTurquoise.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.deepTurquoise, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: AppColors.deepTurquoise),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.automaticTransactionRequestPermission,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepTurquoise,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.automaticTransactionPermissionRequired,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGrant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTurquoise,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
    final locale = context.locale;
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final currentWorkspace = workspaceState.currentWorkspace;
    final otherWorkspaces = workspaceState.availableWorkspaces
        .where((w) => w.id != currentWorkspace?.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                          color: transaction.type == OrderType.expense
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            transaction.description,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      transaction.date.formated("dd/MM/yyyy HH:mm", locale),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                transaction.amount.asCurrency(locale: locale),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.type == OrderType.expense
                      ? Colors.redAccent
                      : Colors.green,
                ),
              ),
            ],
          ),
          if (transaction.suggestedCategory != null || transaction.suggestedAccount != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (transaction.suggestedCategory != null)
                    Chip(
                      avatar: Icon(Icons.category, size: 12),
                      label: Text(
                        transaction.suggestedCategory!.name,
                        style: const TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (transaction.suggestedAccount != null)
                    Chip(
                      avatar: Icon(Icons.account_balance_wallet, size: 12),
                      label: Text(
                        transaction.suggestedAccount!.name,
                        style: const TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (otherWorkspaces.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  tooltip: "Mover para outro Workspace",
                  onSelected: onMove,
                  itemBuilder: (context) => otherWorkspaces
                      .map((w) => PopupMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ))
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
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onConsolidate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTurquoise,
                      foregroundColor: Colors.white,
                    ),
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
