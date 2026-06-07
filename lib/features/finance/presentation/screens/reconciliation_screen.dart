import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation_history_picker.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/l10n/app_localizations.dart';

class ReconciliationScreen extends ConsumerWidget {
  const ReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(FinanceViewProviders.reconciliation);
    final notifier = ref.read(FinanceViewProviders.reconciliation.notifier);

    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reconciliationTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (state.step == ReconciliationStep.selectAccount) {
              Navigator.of(context).pop();
            } else {
              notifier.back();
            }
          },
        ),
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReconciliationState state,
    dynamic notifier,
  ) {
    return Column(
      children: [
        if (state.selectedAccount != null)
          _buildSelectedAccountHeader(context, state, notifier),
        Expanded(child: _buildStepContent(context, state, notifier)),
      ],
    );
  }

  Widget _buildSelectedAccountHeader(
    BuildContext context,
    ReconciliationState state,
    dynamic notifier,
  ) {
    final l10n = context.l10n;
    final account = state.selectedAccount!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: account.color.asColor().withValues(alpha: 0.1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: account.color.asColor(),
            child: Icon(account.icon.asIcon(), color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  account.type.name,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (state.step != ReconciliationStep.review || state.matches.isEmpty)
            TextButton.icon(
              onPressed: () => notifier.back(),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(l10n.reconciliationChangeAccount),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ReconciliationState state,
    dynamic notifier,
  ) {
    switch (state.step) {
      case ReconciliationStep.selectAccount:
        return _buildSelectAccount(context, notifier);
      case ReconciliationStep.uploadFile:
        return _buildUploadFile(context, state, notifier);
      case ReconciliationStep.review:
        return _buildReview(context, state, notifier);
    }
  }

  Widget _buildSelectAccount(
    BuildContext context,
    dynamic notifier,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final accountsAsync = ref.watch(AccountViewProviders.all);

        return accountsAsync.when(
          data: (accounts) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: account.color.asColor(),
                  child: Icon(account.icon.asIcon(), color: Colors.white),
                ),
                title: Text(account.name),
                subtitle: Text(account.type.name),
                onTap: () => notifier.selectAccount(account),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text(e.toString())),
        );
      },
    );
  }

  Widget _buildUploadFile(
    BuildContext context,
    ReconciliationState state,
    dynamic notifier,
  ) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              l10n.reconciliationSelectAccount,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(l10n.reconciliationSupportedFormats, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'ofx', 'png', 'jpg', 'jpeg'],
                );

                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  final extension =
                      result.files.single.extension?.toLowerCase() ??
                      file.path.split('.').last.toLowerCase();

                  if (context.mounted) {
                    showLoadingModal(
                      context,
                      notifier.uploadFile(file),
                      child: AnalysisLoadingView(
                        title: l10n.reconciliationAnalyzing,
                        description: l10n.reconciliationAnalyzingDesc,
                        firstPhaseDuration:
                            ['ofx', 'png', 'jpg', 'jpeg'].contains(extension)
                                ? const Duration(seconds: 20)
                                : const Duration(minutes: 1),
                        totalDuration:
                            ['ofx', 'png', 'jpg', 'jpeg'].contains(extension)
                                ? const Duration(seconds: 45)
                                : const Duration(minutes: 5),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.file_open),
              label: Text(l10n.reconciliationChooseFile),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(
    BuildContext context,
    ReconciliationState state,
    dynamic notifier,
  ) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.reconciliationTransactionsFound(state.matches.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.matches.length,
                itemBuilder: (context, index) {
                  final match = state.matches[index];
                  return _MatchItem(
                    match: match,
                    onChanged: (newMatch) =>
                        notifier.updateMatch(index, newMatch),
                    onLinkManual: (inst) => notifier.linkManual(index, inst),
                    accountId: state.selectedAccount!.id,
                    isDesktop: isDesktop,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => notifier.back(),
                      child: Text(l10n.reconciliationBack),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LoadingButton.elevated(
                      onPressed: (loading) async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        await loading(notifier.confirmReconciliation());

                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text(l10n.reconciliationSuccess)),
                        );

                        navigator.pop();
                      },
                      child: Text(l10n.reconciliationConfirm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MatchItem extends StatelessWidget {
  final ReconciliationMatch match;
  final Function(ReconciliationMatch) onChanged;
  final Function(InstallmentModel) onLinkManual;
  final String accountId;
  final bool isDesktop;

  const _MatchItem({
    required this.match,
    required this.onChanged,
    required this.onLinkManual,
    required this.accountId,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final l10n = context.l10n;
    final docTx = match.documentTransaction;
    final sysInst = match.systemInstallment;
    final createdOrder = match.createdOrder;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (match.status) {
      case ReconciliationMatchStatus.matched:
        statusColor = Colors.green;
        statusText = l10n.reconciliationStatusMatched;
        statusIcon = Icons.check_circle;
        break;
      case ReconciliationMatchStatus.suggested:
        statusColor = Colors.orange;
        statusText = l10n.reconciliationStatusSuggested;
        statusIcon = Icons.help;
        break;
      case ReconciliationMatchStatus.unmatched:
        statusColor = Colors.blue;
        statusText = l10n.reconciliationStatusUnmatched;
        statusIcon = Icons.add_circle;
        break;
      case ReconciliationMatchStatus.ignored:
        statusColor = Colors.grey;
        statusText = l10n.reconciliationStatusIgnored;
        statusIcon = Icons.block;
        break;
    }

    if (isDesktop) {
      return _buildDesktopLayout(
        context,
        locale,
        statusColor,
        statusText,
        statusIcon,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(statusIcon, color: statusColor),
            title: Text(docTx.description),
            subtitle: Text(docTx.date.formated(l10n.formatSimpleDate, locale)),
            trailing: Text(
              docTx.amount.asCurrency(locale: locale),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: docTx.type == OrderType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
          if (sysInst != null || createdOrder != null)
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
                            sysInst?.description ??
                                createdOrder?.description ??
                                "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(sysInst?.referenceDate ?? createdOrder?.firstDueDate ?? DateTime.now()).formated(l10n.formatSimpleDate)} • ${(sysInst?.referenceAmount ?? createdOrder?.amount ?? 0.0).asCurrency(locale: locale)}',
                            style: const TextStyle(fontSize: 12),
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
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    String locale,
    Color statusColor,
    String statusText,
    IconData statusIcon,
  ) {
    final l10n = context.l10n;
    final locale = context.locale;
    final docTx = match.documentTransaction;
    final sysInst = match.systemInstallment;
    final createdOrder = match.createdOrder;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Indicator
            Column(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Document Transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reconciliationExtratoLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    docTx.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(docTx.date.formated(l10n.formatSimpleDate)),
                  Text(
                    docTx.amount.asCurrency(locale: locale),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: docTx.type == OrderType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey),
            const SizedBox(width: 24),
            // System Installment
            Expanded(
              child: sysInst != null || createdOrder != null
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Text(
                    l10n.reconciliationSystemLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                          const SizedBox(height: 4),
                          Text(
                            sysInst?.description ??
                                createdOrder?.description ??
                                "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            (sysInst?.referenceDate ??
                                    createdOrder?.firstDueDate ??
                                    DateTime.now())
                                .formated(l10n.formatSimpleDate),
                          ),
                          Text(
                            (sysInst?.referenceAmount ??
                                    createdOrder?.amount ??
                                    0.0)
                                .asCurrency(locale: locale),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  (sysInst?.type ??
                                          createdOrder?.type ??
                                          OrderType.expense) ==
                                      OrderType.income
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reconciliationSystemLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.reconciliationNoMatchFound,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 16),
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
                if (isDesktop &&
                    match.status == ReconciliationMatchStatus.matched &&
                    match.systemInstallment != null)
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionFormScreen.updateInstallment(
                                installment: match.systemInstallment!,
                                status: InstallmentStatus.settled,
                              ),
                        ),
                      );

                      if (result != null && result is InstallmentModel) {
                        onLinkManual(result);
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(
                      l10n.reconciliationActionModify,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                _buildActions(context, isVertical: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, {bool isVertical = false}) {
    final l10n = context.l10n;
    final actions = [
      if (match.status == ReconciliationMatchStatus.unmatched)
        TextButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransactionFormScreen.creation(
                  accountIdSource:
                      match.documentTransaction.type == OrderType.expense
                      ? accountId
                      : null,
                  accountIdTarget:
                      match.documentTransaction.type == OrderType.income
                      ? accountId
                      : null,
                  status: InstallmentStatus.settled,
                  type: match.documentTransaction.type,
                  description: match.documentTransaction.description,
                  amount: match.documentTransaction.amount,
                  dueDate: match.documentTransaction.date,
                  category: match.documentTransaction.category,
                ),
              ),
            );

            if (result != null && result is InstallmentModel) {
              onLinkManual(result);
            } else if (result != null && result is OrderModel) {
              onChanged(
                match.copyWith(
                  status: ReconciliationMatchStatus.matched,
                  createdOrder: result,
                ),
              );
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.reconciliationActionRegister),
        ),
      TextButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ReconciliationHistoryPicker(
              initialQuery: TransactionQuery(
                accountId: accountId,
                startDate: match.documentTransaction.date.subtract(
                  const Duration(days: 7),
                ),
                endDate: match.documentTransaction.date.add(
                  const Duration(days: 7),
                ),
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
          icon: const Icon(Icons.block),
          label: Text(l10n.reconciliationActionIgnore),
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
