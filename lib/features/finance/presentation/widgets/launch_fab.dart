import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_action_sheet.dart';

/// O botão de lançar.
///
/// Fica no centro da barra inferior em todas as telas principais — é decisão
/// de produto, não de tela. Ele sumia fora das quatro abas da Home: Contas
/// abria a criação por um `IconButton` no `AppBar`, Metas por um
/// `Icons.add_circle` solto no meio de um cabeçalho, e cada tela que tinha um
/// FAB o pintava por conta própria (duas em dourado, uma com a cor do tema).
///
/// Nos formulários e nos slides de coaching ele **não** aparece: ali já existe
/// outro botão principal, e dois primários na mesma tela é uma pergunta sem
/// resposta.
class LaunchFab extends StatelessWidget {
  const LaunchFab({super.key, this.tooltip});

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // Cor, forma e elevação vêm do `floatingActionButtonTheme`.
    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.transparent,
        builder: (context) => const TransactionActionSheet(),
      ),
      child: const Icon(Icons.add),
    );
  }
}
