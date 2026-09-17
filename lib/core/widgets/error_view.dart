import 'package:flutter/material.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Erro de carregamento de um pedaço da tela, com ação de tentar de novo.
///
/// Diferente de `AppErrorWidget`, que substitui a tela inteira quando o próprio
/// build falha: este aqui é para o `error` de um provider — a falha é de uma
/// seção, o resto da tela continua útil e o usuário tem o que fazer.
///
/// Nunca mostra a exceção crua: a mensagem é do app, o detalhe técnico já foi
/// para o Crashlytics.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  /// A partir do erro cru do provider, com a mensagem já classificada.
  ///
  /// É a forma que os `error:` dos `AsyncValue.when` usam: sem rede o texto
  /// fala em conexão, sem permissão fala em acesso, e só o que sobrar cai no
  /// "erro inesperado".
  factory ErrorView.forError(
    BuildContext context,
    Object? error, {
    Key? key,
    VoidCallback? onRetry,
  }) => ErrorView(
    key: key,
    message: errorMessageFor(context, error),
    onRetry: onRetry,
  );

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            color: theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ],
      ),
    );
  }
}
