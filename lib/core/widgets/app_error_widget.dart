import 'package:flutter/material.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

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
    final palette = context.palette;

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Container(
        color: palette.background,
        alignment: Alignment.center,
        // `AppSpacing`, e não 24/12/4 soltos: eram os últimos números mágicos
        // de espaçamento de um widget do core, e a escala existe justamente
        // para que a tela de falha não seja a única com respiro próprio.
        padding: AppSpacing.allLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mesma cara do `ErrorView`: ícone na tinta de erro e texto na
            // tinta do tema. Os dois anunciam a mesma coisa — algo falhou e
            // não foi por culpa de quem está lendo — e apareciam com
            // vermelhos e cinzas diferentes.
            Icon(Icons.cloud_off, size: 40, color: palette.dangerText),
            AppSpacing.gapXs,
            Text(
              l10n?.appErrorWidgetTitle ?? 'Algo deu errado',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
            ),
            AppSpacing.gapXxs,
            Text(
              l10n?.appErrorWidgetMessage ??
                  'Já fomos avisados e estamos trabalhando nisso.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
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
