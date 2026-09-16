import 'package:flutter/material.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Substitui a faixa vermelha de erro do Flutter em release.
///
/// Nunca mostra stack trace nem a mensagem crua da exceção: isso já foi
/// enviado ao Crashlytics. O widget pode ser inserido acima do
/// `Localizations` (quando o erro acontece na própria construção do
/// MaterialApp), então a busca por traduções é tolerante a falhas.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = _tryLocalizations(context);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Container(
        color: theme.colorScheme.surface,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.appErrorWidgetTitle ?? 'Algo deu errado',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n?.appErrorWidgetMessage ??
                  'Já fomos avisados e estamos trabalhando nisso.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static AppLocalizations? _tryLocalizations(BuildContext context) {
    try {
      return AppLocalizations.of(context);
    } catch (_) {
      return null;
    }
  }
}
