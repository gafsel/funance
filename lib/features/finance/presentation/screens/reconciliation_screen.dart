import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/presentation/controllers/reconciliation_notifier.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation_history_picker.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/presentation/widgets/statement_upload_panel.dart';
import 'package:funances/features/finance/presentation/screens/account_selection_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/presentation/display_names.dart';

/// Escolha da conta antes de conciliar.
///
/// A conciliação é uma ação de conta, mas quem chega pelo FAB ("Conciliar
/// extrato") ainda não disse qual. Esta tela existe para que a rota
/// `/reconciliation` funcione SEM parâmetro — digitada, compartilhada ou
/// recarregada — em vez de mandar o usuário para a home.
class ReconciliationAccountPickerScreen extends StatelessWidget {
  const ReconciliationAccountPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reconciliationTitle)),
      body: AccountSelectionScreen(
        title: l10n.reconciliationChooseAccount,
        showAddOption: false,
        onAccountSelected: (account) {
          if (account == null) return;
          context.pushReplacement('/reconciliation?accountId=${account.id}');
        },
      ),
    );
  }
}

class ReconciliationScreen extends ConsumerWidget {
  final AccountModel account;

  const ReconciliationScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(FinanceViewProviders.reconciliation(account));
    final notifier = ref.read(
      FinanceViewProviders.reconciliation(account).notifier,
    );

    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reconciliationTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (state.step == ReconciliationStep.uploadFile) {
              notifier.reset();
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
    ReconciliationNotifier notifier,
  ) {
    return Column(
      children: [
        _buildSelectedAccountHeader(context, state, notifier),
        Expanded(child: _buildStepContent(context, state, notifier)),
      ],
    );
  }

  Widget _buildSelectedAccountHeader(
    BuildContext context,
    ReconciliationState state,
    ReconciliationNotifier notifier,
  ) {
    final account = state.selectedAccount;
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
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ReconciliationState state,
    ReconciliationNotifier notifier,
  ) {
    switch (state.step) {
      case ReconciliationStep.uploadFile:
        return _buildUploadFile(context, state, notifier);
      case ReconciliationStep.review:
        return _buildReview(context, state, notifier);
    }
  }

  Widget _buildUploadFile(
    BuildContext context,
    ReconciliationState state,
    ReconciliationNotifier notifier,
  ) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StatementUploadPanel(
          allowedExtensions: const ['pdf', 'ofx', 'png', 'jpg', 'jpeg'],
          title: l10n.reconciliationSelectAccount,
          dragOverTitle: l10n.statementDragOverTitle,
          supportedFormatsText: l10n.reconciliationSupportedFormats,
          selectFileButtonText: l10n.reconciliationChooseFile,
          onFileSelected: (document) async {
            final extension = document.extension;
            final uploadId = const Uuid().v4();
            final messenger = ScaffoldMessenger.of(context);
            final progressStream = notifier.reconciliationService
                .watchUploadProgress(uploadId);

            try {
              await showLoadingModal(
                context,
                notifier.uploadFile(document, uploadId: uploadId),
                child: AnalysisLoadingView(
                  title: l10n.reconciliationAnalyzing,
                  description: l10n.reconciliationAnalyzingDesc,
                  progressStream: progressStream,
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
            } catch (e) {
              // Antes a falha era silenciosa: o modal fechava e a tela ficava
              // parada na etapa de upload.
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    callableErrorMessage(
                      e,
                      l10n.reconciliationError,
                      offlineMessage: l10n.errorOfflineCallable,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildReview(
    BuildContext context,
    ReconciliationState state,
    ReconciliationNotifier notifier,
  ) {
    final l10n = context.l10n;
    final locale = context.locale;
    final scrollController = ScrollController();

    final suggestedMatches = state.matches
        .where((m) => m.status == ReconciliationMatchStatus.suggested)
        .toList();
    final suggestedCount = suggestedMatches.length;

    final suggestedAmount = Money.sumOf(
      suggestedMatches,
      (m) =>
          m.documentTransaction?.amount ??
          m.systemInstallment?.referenceAmount ??
          0.0,
    ).toDouble();

    final canConfirm = state.matches.every(
      (m) =>
          m.status == ReconciliationMatchStatus.matched ||
          m.status == ReconciliationMatchStatus.ignored,
    );

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
            if (suggestedCount > 3)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      notifier.confirmAllSuggestions();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (scrollController.hasClients) {
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.done_all),
                    label: Text(
                      l10n.reconciliationBulkConfirmSuggestions(
                        suggestedAmount.asCurrency(locale: locale),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: state.matches.length,
                itemBuilder: (context, index) {
                  final match = state.matches[index];
                  return _MatchItem(
                    match: match,
                    onChanged: (newMatch) =>
                        notifier.updateMatch(index, newMatch),
                    onLinkManual: (inst) => notifier.linkManual(index, inst),
                    onUnlink: () => notifier.unlinkMatch(index),
                    account: state.selectedAccount,
                    isDesktop: isDesktop,
                  );
                },
              ),
            ),
            if (!canConfirm)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.reconciliationWarningUnanswered,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                      onPressed: canConfirm
                          ? (loading) async {
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );

                              await loading(
                                notifier.confirmReconciliation(
                                  uncategorizedLabel: l10n.categoryOthers,
                                ),
                              );

                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(l10n.reconciliationSuccess),
                                ),
                              );

                              navigator.pop();
                            }
                          : null,
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
  final VoidCallback onUnlink;
  final AccountModel account;
  final bool isDesktop;

  const _MatchItem({
    required this.match,
    required this.onChanged,
    required this.onLinkManual,
    required this.onUnlink,
    required this.account,
    this.isDesktop = false,
  });

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

    final isSystemOnly = docTx == null && sysInst != null;
    final isLinked = docTx != null && sysInst != null;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isSystemOnly) {
      if (match.status == ReconciliationMatchStatus.ignored) {
        statusColor = Colors.red;
        statusText = l10n.reconciliationStatusRemove;
        statusIcon = Icons.delete_sweep;
      } else if (match.status == ReconciliationMatchStatus.matched) {
        statusColor = Colors.green;
        statusText = l10n.reconciliationStatusKeep;
        statusIcon = Icons.check_circle;
      } else {
        statusColor = Colors.purple;
        statusText = l10n.reconciliationStatusSystemOnly;
        statusIcon = Icons.info_outline;
      }
    } else {
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
      color: isSystemOnly ? Colors.purple.withValues(alpha: 0.05) : null,
      child: Column(
        children: [
          ListTile(
            leading: Icon(statusIcon, color: statusColor),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Indicator
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Document Transaction (Pool 1)
            Expanded(
              child: dTx != null
                  ? Column(
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
                          displayOr(dTx.description, l10n.noDescription),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(dTx.date.formated(l10n.formatSimpleDate)),
                        Text(
                          dTx.amount.asCurrency(locale: locale),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: dTx.type == OrderType.income
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    )
                  : Column(
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
                        const SizedBox(height: 8),
                        Text(
                          l10n.reconciliationNotInDocument,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 16),
            MatchConnectorWidget(status: match.status, isLinked: isLinked),
            const SizedBox(width: 16),
            // System Pool (Pool 2)
            Expanded(
              child:
                  sInst != null ||
                      createdOrder != null ||
                      match.customDescription != null
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
                            description ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          Text(
                            (sInst?.referenceAmount ??
                                    createdOrder?.amount ??
                                    (dTx?.amount ?? 0).abs())
                                .asCurrency(locale: locale),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  (match.customType ??
                                          sInst?.type ??
                                          createdOrder?.type ??
                                          dTx?.type ??
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
                if (match.status == ReconciliationMatchStatus.matched)
                  TextButton.icon(
                    onPressed: () async {
                      final result =
                          await showModalBottomSheet<ReconciliationMatch?>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
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
    final isSystemOnly =
        match.documentTransaction == null && match.systemInstallment != null;

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

class ReconciliationTransactionForm extends StatefulWidget {
  final ReconciliationMatch match;
  final AccountModel account;

  const ReconciliationTransactionForm({
    super.key,
    required this.match,
    required this.account,
  });

  @override
  State<ReconciliationTransactionForm> createState() =>
      _ReconciliationTransactionFormState();
}

class _ReconciliationTransactionFormState
    extends State<ReconciliationTransactionForm> {
  late String description;
  CategoryModel? category;
  late OrderType type;
  String? targetAccountId;
  int? installmentCount;
  bool isRecurring = false;

  @override
  void initState() {
    super.initState();
    description =
        widget.match.customDescription ??
        widget.match.systemInstallment?.description ??
        widget.match.documentTransaction?.description ??
        "";
    category =
        widget.match.customCategory ??
        widget.match.systemInstallment?.category ??
        widget.match.documentTransaction?.category;
    final docTx = widget.match.documentTransaction;
    final sysInst = widget.match.systemInstallment;

    // Se temos transação do documento, confiamos no tipo dela
    // Caso contrário (transação só do sistema), confiamos no tipo do sistema
    type = (widget.match.customType ?? docTx?.type ?? sysInst?.type)!;

    targetAccountId =
        widget.match.targetAccountId ??
        widget.match.systemInstallment?.accountIdTarget;
    installmentCount =
        widget.match.installmentCount ??
        widget.match.systemInstallment?.installmentCount;
    isRecurring = (installmentCount ?? 1) > 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.locale;
    final dTx = widget.match.documentTransaction;
    final sInst = widget.match.systemInstallment;

    final isCredit = dTx != null
        ? dTx.type == OrderType.income
        : (sInst?.type == OrderType.income);
    final isDebit = !isCredit;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.reconciliationActionRegister,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.pureWhite),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Read-only metadata fields showing amount, date, status, account
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: dTx != null
                          ? dTx.amount.abs().asCurrency(locale: locale)
                          : sInst?.referenceAmount.asCurrency(locale: locale),
                      decoration: InputDecoration(
                        labelText: l10n.transactionAmountLabel,
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: Colors.grey,
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      enabled: false,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          (dTx?.date ?? sInst?.referenceDate ?? DateTime.now())
                              .formated(l10n.formatSimpleDate, locale),
                      decoration: InputDecoration(
                        labelText: l10n.date,
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      enabled: false,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: l10n.transactionStatusSettled,
                      decoration: InputDecoration(
                        labelText: l10n.transactionStatusLabel,
                        prefixIcon: const Icon(
                          Icons.assignment_turned_in,
                          color: Colors.grey,
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      enabled: false,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.account.name,
                      decoration: InputDecoration(
                        labelText: type == OrderType.transfer
                            ? (isCredit
                                  ? l10n.transactionToAccountLabel
                                  : l10n.transactionFromAccountLabel)
                            : l10n.reconciliationAccountLabel,
                        prefixIcon: const Icon(
                          Icons.account_balance,
                          color: Colors.grey,
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      enabled: false,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: description,
                onChanged: (value) => setState(() => description = value),
                decoration: InputDecoration(
                  labelText: l10n.transactionDescriptionLabel,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                style: const TextStyle(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 16),
              ChipFormField<OrderType>(
                initialValue: type,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      type = value;
                      if (type == OrderType.transfer) {
                        category = null;
                      }
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.transactionTypeLabel,
                ),
                options: [
                  if (isCredit)
                    ChipFormFieldOption(
                      value: OrderType.income,
                      label: l10n.transactionTypeIncome,
                    ),
                  if (isDebit)
                    ChipFormFieldOption(
                      value: OrderType.expense,
                      label: l10n.transactionTypeExpense,
                    ),
                  ChipFormFieldOption(
                    value: OrderType.transfer,
                    label: l10n.transactionTypeTransfer,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (type == OrderType.transfer) ...[
                AccountFormField(
                  initialValue: targetAccountId,
                  excludeAccountId: widget.account.id,
                  onChanged: (value) => setState(() => targetAccountId = value),
                  decoration: InputDecoration(
                    labelText: isCredit
                        ? l10n.transactionFromAccountLabel
                        : l10n.transactionToAccountLabel,
                  ),
                ),
              ] else ...[
                CategoryFormField(
                  initialValue: category,
                  categoryType: type.categoryType,
                  onChanged: (value) => setState(() => category = value),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  l10n.transactionTypeInstallment,
                  style: const TextStyle(color: AppColors.pureWhite),
                ),
                value: isRecurring,
                onChanged: (value) => setState(() {
                  isRecurring = value;
                  if (!value) installmentCount = null;
                  if (value && installmentCount == null) installmentCount = 2;
                }),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: theme.colorScheme.primary,
              ),
              if (isRecurring) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: installmentCount?.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      setState(() => installmentCount = int.tryParse(value)),
                  decoration: InputDecoration(
                    labelText: l10n.transactionInstallmentsLabel,
                    prefixIcon: const Icon(Icons.repeat),
                  ),
                  style: const TextStyle(color: AppColors.pureWhite),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updatedMatch = widget.match.copyWith(
                      status: ReconciliationMatchStatus.matched,
                      customDescription: description,
                      customCategory: category,
                      customType: type,
                      targetAccountId: targetAccountId,
                      installmentCount: installmentCount,
                    );
                    Navigator.pop(context, updatedMatch);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchConnectorWidget extends StatelessWidget {
  final ReconciliationMatchStatus status;
  final bool isLinked;

  const MatchConnectorWidget({
    super.key,
    required this.status,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLinked) {
      return const SizedBox(
        width: 60,
        child: Center(
          child: Icon(Icons.link_off, color: Colors.grey, size: 20),
        ),
      );
    }

    Color color;
    bool isDashed = false;
    IconData icon;

    switch (status) {
      case ReconciliationMatchStatus.matched:
        color = Colors.green;
        isDashed = false;
        icon = Icons.link;
        break;
      case ReconciliationMatchStatus.suggested:
        color = Colors.orange;
        isDashed = true;
        icon = Icons.link;
        break;
      case ReconciliationMatchStatus.ignored:
        color = Colors.red;
        isDashed = false;
        icon = Icons.link_off;
        break;
      case ReconciliationMatchStatus.unmatched:
        color = Colors.grey;
        isDashed = false;
        icon = Icons.link_off;
        break;
    }

    return SizedBox(
      width: 60,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(60, 40),
            painter: ConnectorPainter(
              color: color,
              isDashed: isDashed,
              hasCenterGap: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}

class ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  final bool hasCenterGap;

  ConnectorPainter({
    required this.color,
    required this.isDashed,
    required this.hasCenterGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2;
    final double startX = 0;
    final double endX = size.width;

    if (hasCenterGap) {
      final double midX = size.width / 2;
      final double gap = 12.0;
      _drawLine(canvas, paint, startX, midX - gap, y);
      _drawLine(canvas, paint, midX + gap, endX, y);
    } else {
      _drawLine(canvas, paint, startX, endX, y);
    }
  }

  void _drawLine(Canvas canvas, Paint paint, double x1, double x2, double y) {
    if (!isDashed) {
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    } else {
      const double dashWidth = 4.0;
      const double dashSpace = 3.0;
      double currentX = x1;
      while (currentX < x2) {
        final double nextX = (currentX + dashWidth).clamp(x1, x2);
        canvas.drawLine(Offset(currentX, y), Offset(nextX, y), paint);
        currentX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isDashed != isDashed ||
        oldDelegate.hasCenterGap != hasCenterGap;
  }
}
