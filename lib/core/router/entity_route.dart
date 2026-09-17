import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:go_router/go_router.dart';

/// Carrega pelo id o que uma rota de detalhe abre.
///
/// Antes, fatura, conciliação, coaching, meta e categoria chegavam com o objeto
/// inteiro no `extra` do go_router. O `extra` é memória do processo: ele não
/// sobrevive a um F5 na web nem a um hot restart, e o go_router ainda o
/// desidrata para `Map` quando reprocessa a rota. O sintoma era sempre o
/// mesmo — a tela redirecionava para a home, e quem tinha compartilhado o
/// endereço via a home também.
///
/// Agora o endereço carrega o id, e a tela carrega o documento. Três estados,
/// todos com saída: carregando, erro (com "tentar de novo") e inexistente (com
/// "voltar para o início").
class EntityRoute<T> extends ConsumerWidget {
  const EntityRoute({
    super.key,
    required this.provider,
    required this.builder,
    this.title,
  });

  /// O provider que busca a entidade. `data(null)` significa "não existe".
  final ProviderBase<AsyncValue<T?>> provider;

  final Widget Function(BuildContext context, T value) builder;

  /// Título da barra usada nos estados de carregamento, erro e ausência — a
  /// tela final tem o seu próprio.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return async.when(
      data: (value) => value == null ? _missing(context) : builder(context, value),
      loading: () => _shell(
        context,
        const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _shell(
        context,
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView.forError(
              context,
              error,
              onRetry: () => ref.invalidate(provider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _missing(BuildContext context) => _shell(
    context,
    Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 16),
            Text(context.l10n.errorNotFound, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              child: Text(context.l10n.routeNotFoundGoHome),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _shell(BuildContext context, Widget child) =>
      Scaffold(appBar: AppBar(title: title == null ? null : Text(title!)), body: child);
}
