import 'package:flutter/material.dart';

// Gerenciador de estado global para as modais de carregamento
final List<Future<dynamic>> _activeFutures = [];
bool _isDialogOpen = false;

/// Abre uma modal de bloqueio que ouve um [Future] e fecha quando ele se resolver.
///
/// Se for chamada múltiplas vezes, apenas uma modal será exibida e ela só será
/// fechada quando todos os [Future]s passados forem resolvidos.
///
/// [context] O BuildContext necessário para abrir a modal.
/// [future] O Future que será aguardado.
/// [child] Widget opcional para exibir na modal. Se nulo, mostra um [CircularProgressIndicator] e "Aguarde...".
/// [canPop] Se permite que o usuário feche a modal manualmente (ex: botão voltar). Default é false.
/// [barrierDismissible] Se permite fechar clicando fora da modal. Default é false.
Future<T> showLoadingModal<T>(
  BuildContext context,
  Future<T> future, {
  Widget? child,
  bool canPop = false,
  bool barrierDismissible = false,
}) async {
  _activeFutures.add(future);

  if (!_isDialogOpen) {
    _isDialogOpen = true;

    // Não aguardamos o showDialog aqui para permitir que o código continue
    // e chegue no `await future`.
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _isDialogOpen = false;
              _activeFutures.clear();
            }
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: child ??
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Aguarde...",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
    ).then((_) {
      _isDialogOpen = false;
      _activeFutures.clear();
    });
  }

  try {
    return await future;
  } finally {
    _activeFutures.remove(future);

    // Se não houver mais futures ativos e o diálogo ainda estiver aberto, fecha-o.
    if (_activeFutures.isEmpty && _isDialogOpen) {
      _isDialogOpen = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}
