import 'package:flutter/material.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/presentation/controllers/reconciliation_notifier.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/reconciliation_match_item.dart';

/// Segunda etapa: revisar o que o extrato trouxe.
///
/// Nada é gravado até o botão de confirmar, e ele só destrava quando todos os
/// casamentos foram respondidos — daí a tarja de aviso enquanto sobrar
/// pergunta em aberto.
class ReconciliationReviewView extends StatefulWidget {
  const ReconciliationReviewView({
    super.key,
    required this.state,
    required this.notifier,
  });

  final ReconciliationState state;
  final ReconciliationNotifier notifier;

  @override
  State<ReconciliationReviewView> createState() =>
      _ReconciliationReviewViewState();
}

class _ReconciliationReviewViewState extends State<ReconciliationReviewView> {
  /// O controller era criado dentro do `build`: cada reconstrução descartava o
  /// anterior e o "confirmar todas" perdia o scroll até o fim da lista.
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = widget.notifier;
    final l10n = context.l10n;
    final locale = context.locale;

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
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
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
                controller: _scrollController,
                itemCount: state.matches.length,
                itemBuilder: (context, index) {
                  final match = state.matches[index];
                  return ReconciliationMatchItem(
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
            if (!canConfirm) const ReconciliationUnansweredWarning(),
            ReconciliationFooterActions(
              onBack: notifier.back,
              onConfirm: canConfirm
                  ? (loading) async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      await loading(
                        notifier.confirmReconciliation(
                          uncategorizedLabel: l10n.categoryOthers,
                        ),
                      );

                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(l10n.reconciliationSuccess)),
                      );

                      navigator.pop();
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}

/// Tarja de "ainda falta responder".
///
/// O botão de confirmar desabilitado sozinho não diz por quê; esta linha diz.
class ReconciliationUnansweredWarning extends StatelessWidget {
  const ReconciliationUnansweredWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
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
    );
  }
}

/// Rodapé fixo: voltar e confirmar.
class ReconciliationFooterActions extends StatelessWidget {
  const ReconciliationFooterActions({
    super.key,
    required this.onBack,
    required this.onConfirm,
  });

  final VoidCallback onBack;
  final LoadingCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
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
              onPressed: onBack,
              child: Text(l10n.reconciliationBack),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: LoadingButton.elevated(
              onPressed: onConfirm,
              child: Text(l10n.reconciliationConfirm),
            ),
          ),
        ],
      ),
    );
  }
}
