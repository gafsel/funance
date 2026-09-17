import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/presentation/screens/account_selection_screen.dart';
import 'package:go_router/go_router.dart';

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
