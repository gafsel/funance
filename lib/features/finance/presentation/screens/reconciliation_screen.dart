import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/reconciliation_review_view.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation/reconciliation_upload_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Conciliação de extrato
//
// O arquivo tinha 1370 linhas: um `_MatchItem` de 531 com dois layouts
// inteiros dentro, um formulário modal de 290, o conector pintado à mão e a
// etapa de revisão de 181. Tudo isso mora agora em
// `presentation/widgets/reconciliation/`; aqui fica só a máquina de duas
// etapas (escolher o arquivo → revisar) e o cabeçalho da conta.
// ─────────────────────────────────────────────────────────────────────────────

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
      body: Column(
        children: [
          _SelectedAccountHeader(account: state.selectedAccount),
          Expanded(
            child: switch (state.step) {
              ReconciliationStep.uploadFile => ReconciliationUploadView(
                notifier: notifier,
              ),
              ReconciliationStep.review => ReconciliationReviewView(
                state: state,
                notifier: notifier,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// Faixa com a conta sendo conciliada.
///
/// Fica visível nas duas etapas porque é a única resposta à pergunta "extrato
/// de qual conta é este?" depois que o arquivo já foi lido.
class _SelectedAccountHeader extends StatelessWidget {
  const _SelectedAccountHeader({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
