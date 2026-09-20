import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:go_router/go_router.dart';

/// Todas as notificações de banco esperando virar lançamento.
///
/// A lista não tem tamanho: o leitor grava uma pendência por notificação e
/// ninguém consolida todo dia. Na Home ela mostra três — mais do que isso e o
/// bloco engole a tela — e o resto está aqui.
class AutomaticTransactionsScreen extends StatelessWidget {
  const AutomaticTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(context.l10n.automaticTransactionTitle),
        // A tela abre empilhada pela Home, mas também por link direto. Sem a
        // saída explícita, chegar por fora deixava a pessoa sem botão de
        // voltar — o mesmo padrão de `EntityRoute`.
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: SafeArea(child: AutomaticTransactionConsolidationWidget()),
      ),
    );
  }
}
