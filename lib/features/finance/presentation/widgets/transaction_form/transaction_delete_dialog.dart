import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/replication_cascade_dialog.dart';

/// Confirmação de exclusão do lançamento.
///
/// Numa série (parcelado ou recorrente) a pergunta vem em dois passos:
/// primeiro "tem certeza?", depois "só esta ou as seguintes também?". Apagar
/// é irreversível, e a cascata é a diferença entre perder uma parcela e
/// perder o ano inteiro.
abstract final class TransactionDeleteDialog {
  static void show(
    BuildContext context,
    AutoDisposeStateNotifierProvider<
      TransactionFormNotifier,
      TransactionFormState
    >
    provider,
  ) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          Consumer(
            builder: (context, ref, _) {
              final notifier = ref.read(provider.notifier);
              final state = ref.watch(provider.select((s) => s));

              return LoadingButton.text(
                onPressed: (loading) async {
                  final navigator = Navigator.of(context);
                  ReplicationCascade cascade = ReplicationCascade.none;

                  if (state.installmentType != InstallmentType.single) {
                    final selectedCascade =
                        await ReplicationCascadeDialog.showDeletion(context);

                    if (selectedCascade == null) return;
                    cascade = selectedCascade;
                  }

                  notifier.updateReplicationCascade(cascade);
                  await loading(notifier.delete());

                  navigator.pop(); // Fecha dialog de confirmação
                  if (context.mounted) {
                    Navigator.of(context).pop(true); // Fecha tela de form
                  }
                },
                child: Text(
                  l10n.deleteButton,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
